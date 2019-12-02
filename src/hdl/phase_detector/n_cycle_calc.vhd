-------------------------------------------------------------------------------
-- Title      : n_cycle calculator
-- Project    : 
-------------------------------------------------------------------------------
-- File       : n_cycle_calc.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-02
-- Last update: 2019-12-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-02  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_cycle_calc is
  generic (
    g_stable_threshold : positive := 16
    );
  port (
    ls_clk_i        : in  std_logic;
    rst_i           : in  std_logic;
    output_A_i      : in  std_logic;
    output_B_i      : in  std_logic;
    calc_en_i       : in  std_logic;
    n_cycle_o       : out std_logic_vector(15 downto 0);
    n_cycle_ready_o : out std_logic
    );
end entity n_cycle_calc;

architecture rtl of n_cycle_calc is

  signal s_counter           : std_logic_vector(31 downto 0);
  signal u_counter           : unsigned(31 downto 0);
  signal s_phase_tag_A       : std_logic_vector(31 downto 0);
  signal s_phase_tag_A_ready : std_logic;
  signal s_phase_tag_B       : std_logic_vector(31 downto 0);
  signal s_phase_tag_B_ready : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Counter
  -----------------------------------------------------------------------------
  p_counter : process (ls_clk_i, rst_i) is
  begin  -- process p_counter
    if rst_i = '1' then                 -- asynchronous reset (active high)
      u_counter <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      u_counter <= u_counter + 1;
    end if;
  end process p_counter;

  s_counter <= std_logic_vector(u_counter);

  -----------------------------------------------------------------------------
  -- Deglitchers
  -----------------------------------------------------------------------------
  i_deglitcher_1 : entity work.deglitcher
    generic map (
      g_stable_threshold => g_stable_threshold
      )
    port map (
      ls_clk_i          => ls_clk_i,
      rst_i             => rst_i,
      input_i           => output_A_i,
      counter_i         => s_counter,
      calc_en_i         => calc_en_i,
      phase_tag_o       => s_phase_tag_A,
      phase_tag_ready_o => s_phase_tag_A_ready
      );

  i_deglitcher_2 : entity work.deglitcher
    generic map (
      g_stable_threshold => g_stable_threshold
      )
    port map (
      ls_clk_i          => ls_clk_i,
      rst_i             => rst_i,
      input_i           => output_B_i,
      counter_i         => s_counter,
      calc_en_i         => calc_en_i,
      phase_tag_o       => s_phase_tag_B,
      phase_tag_ready_o => s_phase_tag_B_ready
      );

  -----------------------------------------------------------------------------
  -- Calculate the n_cycle
  -----------------------------------------------------------------------------
  i_n_cycle_generator_1: entity work.n_cycle_generator
    port map (
      ls_clk_i             => ls_clk_i,
      rst_i                => rst_i,
      phase_tag_A_in       => s_phase_tag_A,
      phase_tag_A_ready_in => s_phase_tag_A_ready,
      phase_tag_B_in       => s_phase_tag_B,
      phase_tag_B_ready_in => s_phase_tag_B_ready,
      n_cycle_o            => n_cycle_o,
      n_cycle_ready_o      => n_cycle_ready_o
      );


end architecture rtl;
