-------------------------------------------------------------------------------
-- Title      : Dual Mixer Time Difference
-- Project    : 
-------------------------------------------------------------------------------
-- File       : DMTD.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-16
-- Last update: 2019-10-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Phase detector based on WR protocol (pg 51 "White Rabbit
-- Specification: draft for Comments; version 2.0",
-- "https://www.ohwr.org/project/wr-std/wikis/Documents/White-Rabbit-Specification-(latest-version)") 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-16  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMTD is
  port (
    ls_clk_i         : in  std_logic;
    hs_fixed_clk_i   : in  std_logic;
    hs_var_clk_i     : in  std_logic;
    rst_i            : in  std_logic;
    change_freq_o    : out std_logic;
    change_freq_en_o : out std_logic
    );
end entity DMTD;

architecture rtl of DMTD is

  signal s_output_fixed_clk : std_logic;
  signal s_output_var_clk   : std_logic;
  signal s_n_cycle          : std_logic_vector(7 downto 0);
  signal s_n_cycle_ready    : std_logic;
  signal s_n_cycle_new      : std_logic_vector(7 downto 0);
  signal s_n_cycle_old      : std_logic_vector(7 downto 0);
  signal u_n_cycle_new      : signed(7 downto 0);
  signal u_n_cycle_old      : signed(7 downto 0);
  signal sgn_n_cycle_diff   : signed (7 downto 0);
  signal sgn_counter        : signed(7 downto 0);
  signal i_abs_n_cycle_diff : integer;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Obtain Output
  -----------------------------------------------------------------------------
  i_slow_phase_analyzer_1 : entity work.slow_phase_analyzer
    port map (
      hs_clk_i => hs_fixed_clk_i,
      ls_clk_i => ls_clk_i,
      rst_i    => rst_i,
      output_o => s_output_fixed_clk
      );

  i_slow_phase_analyzer_2 : entity work.slow_phase_analyzer
    port map (
      hs_clk_i => hs_var_clk_i,
      ls_clk_i => ls_clk_i,
      rst_i    => rst_i,
      output_o => s_output_var_clk
      );

  -----------------------------------------------------------------------------
  -- Calculate n_cycle
  -----------------------------------------------------------------------------
  n_cycles_calc_1 : entity work.n_cycles_calc
    port map (
      ls_clk_i        => ls_clk_i,
      output_A_i      => s_output_fixed_clk,
      output_B_i      => s_output_var_clk,
      calc_en_i       => '1',
      rst_i           => rst_i,
      n_cycle_o       => s_n_cycle,
      n_cycle_ready_o => s_n_cycle_ready
      );

  -----------------------------------------------------------------------------
  -- n_cycle latcher
  -----------------------------------------------------------------------------
  p_n_cycle_latcher : process (ls_clk_i, rst_i) is
  begin  -- process p_n_cycle_latcher
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_n_cycle_new <= (others => '0');
      s_n_cycle_old <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      if s_n_cycle_ready = '1' then
        s_n_cycle_new <= s_n_cycle;
        s_n_cycle_old <= s_n_cycle_new;
      end if;
    end if;
  end process p_n_cycle_latcher;

  u_n_cycle_new <= signed(s_n_cycle_new);
  u_n_cycle_old <= signed(s_n_cycle_old);

  sgn_n_cycle_diff <= u_n_cycle_new - u_n_cycle_old;

  -----------------------------------------------------------------------------
  -- Counter
  -----------------------------------------------------------------------------
  i_abs_n_cycle_diff <= to_integer(abs(sgn_n_cycle_diff));

  p_counter : process (ls_clk_i, rst_i) is
  begin  -- process p_counter
    if rst_i = '1' then                 -- asynchronous reset (active high)
      sgn_counter <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      if s_n_cycle_ready = '1' and i_abs_n_cycle_diff < 3 then
        sgn_counter <= sgn_counter + sgn_n_cycle_diff;
      end if;
    end if;
  end process p_counter;





end architecture rtl;

