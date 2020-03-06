-------------------------------------------------------------------------------
-- Title      : frequency manager
-- Project    : 
-------------------------------------------------------------------------------
-- File       : frequency_manager.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-03
-- Last update: 2020-03-06
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-03  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extras;
use extras.synchronizing.all;

entity frequency_manager is
  generic (
    g_number_of_bits : positive := 28
    );
  port (
    clk_i            : in  std_logic;
    rst_i            : in  std_logic;
    ctrl_i           : in  std_logic;
    change_freq_en_i : in  std_logic;
    incr_freq_i      : in  std_logic;
    M_start_i        : in  std_logic_vector(g_number_of_bits - 1 downto 0);
    M_o              : out std_logic_vector(g_number_of_bits - 1 downto 0)
    );
end entity frequency_manager;

architecture rtl of frequency_manager is

  signal s_ctrl_re           : std_logic;
  signal s_change_freq_en_df : std_logic;
  signal s_incr_freq_df      : std_logic;
  signal sgn_M               : signed(g_number_of_bits - 1 downto 0);
  signal s_M                 : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal sgn_M_start         : signed(g_number_of_bits - 1 downto 0);
  signal s_ctrl              : std_logic;
  signal s_ctrl_df           : std_logic;

  attribute mark_debug        : string;
  -- attribute mark_debug of s_change_freq_en_re : signal is "true";
  -- attribute mark_debug of s_incr_freq_re      : signal is "true";
  attribute mark_debug of s_M : signal is "true";

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Rising edge detectors
  -----------------------------------------------------------------------------
  bit_synchronizer_1 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i,
      Reset  => rst_i,
      Bit_in => change_freq_en_i,
      Sync   => s_change_freq_en_df
      );

  bit_synchronizer_2 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i,
      Reset  => rst_i,
      Bit_in => incr_freq_i,
      Sync   => s_incr_freq_df
      );

  bit_synchronizer_3 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i,
      Reset  => rst_i,
      Bit_in => ctrl_i,
      Sync   => s_ctrl_df
      );

  r_edge_detect_1 : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => clk_i,
      sig_i => s_ctrl_df,
      sig_o => s_ctrl_re
      );

  -----------------------------------------------------------------------------
  -- Frequency manager
  -----------------------------------------------------------------------------
  sgn_M_start <= signed(M_start_i);

  p_freq_manager : process (clk_i, rst_i) is
  begin  -- process p_freq_manager
    if rst_i = '1' then                 -- asynchronous reset (active high)
      sgn_M <= sgn_M_start;             -- should start at 4000000 for 62.5 MHz
    elsif rising_edge(clk_i) then       -- rising clock edge
      if s_ctrl_re = '1' then
        if s_change_freq_en_df = '1' then
          case s_incr_freq_df is
            when '0' =>
              sgn_M <= sgn_M - 1;
            when '1' =>
              sgn_M <= sgn_M + 1;
            when others =>
              null;
          end case;
        end if;
      end if;
    end if;
  end process p_freq_manager;

  p_sample_M : process (clk_i) is
  begin  -- process p_sample_M
    if rising_edge(clk_i) then          -- rising clock edge
      s_M <= std_logic_vector(sgn_M);
    end if;
  end process p_sample_M;

  M_o <= std_logic_vector(sgn_M);

end architecture rtl;
