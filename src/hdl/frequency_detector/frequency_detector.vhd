-------------------------------------------------------------------------------
-- Title      : frequency detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : frequency_detector.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-09
-- Last update: 2019-12-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-09  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity frequency_detector is

  generic (
    g_threshold : positive := 32
    );
  port (
    ls_clk_i         : in  std_logic;
    data_i           : in  std_logic;
    hs_var_clk_i     : in  std_logic;
    rst_i            : in  std_logic;
    DMTD_en_i        : in  std_logic;
    DMTD_locked_o    : out std_logic;
    incr_freq_o      : out std_logic;
    change_freq_en_o : out std_logic
    );

end entity frequency_detector;

architecture rtl of frequency_detector is

  signal s_output_data       : std_logic;
  signal s_output_var_clk    : std_logic;
  signal s_n_cycle           : std_logic_vector(15 downto 0);
  signal s_n_cycle_ready     : std_logic;
  signal s_n_cycle_max       : std_logic_vector(15 downto 0);
  signal s_n_cycle_max_ready : std_logic;
  signal s_DMTD_max_en       : std_logic;
  signal s_DMTD_locked       : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Obtain output
  -----------------------------------------------------------------------------
  i_slow_phase_analyzer_1 : entity work.slow_phase_analyzer
    generic map (
      g_is_data => true
      )
    port map (
      hs_clk_i => data_i,
      ls_clk_i => ls_clk_i,
      output_o => s_output_data
      );

  i_slow_phase_analyzer_2 : entity work.slow_phase_analyzer
    generic map (
      g_is_data => false
      )
    port map (
      hs_clk_i => hs_var_clk_i,
      ls_clk_i => ls_clk_i,
      output_o => s_output_var_clk
      );

  -----------------------------------------------------------------------------
  -- Calculate n_cycle
  -----------------------------------------------------------------------------
  i_n_cycle_calc_1 : entity work.n_cycle_calc
    generic map (
      g_stable_threshold => 16
      )
    port map (
      ls_clk_i        => ls_clk_i,
      rst_i           => rst_i,
      output_A_i      => s_output_var_clk,
      output_B_i      => s_output_data,
      calc_en_i       => DMTD_en_i,
      n_cycle_o       => s_n_cycle,
      n_cycle_ready_o => s_n_cycle_ready
      );

  i_n_cycle_calc_2 : entity work.n_cycle_calc
    generic map (
      g_stable_threshold => 16
      )
    port map (
      ls_clk_i        => ls_clk_i,
      rst_i           => rst_i,
      output_A_i      => s_output_var_clk,
      output_B_i      => s_output_var_clk,
      calc_en_i       => s_DMTD_max_en,
      n_cycle_o       => s_n_cycle_max,
      n_cycle_ready_o => s_n_cycle_max_ready
      );

  -----------------------------------------------------------------------------
  -- Locker manager FSM
  -----------------------------------------------------------------------------
  i_locker_manager_1 : entity work.locker_manager
    port map (
      ls_clk_i            => ls_clk_i,
      rst_i               => rst_i,
      DMTD_en_i           => DMTD_en_i,
      n_cycle_i           => s_n_cycle,
      n_cycle_ready_i     => s_n_cycle_ready,
      n_cycle_max_i       => s_n_cycle_max,
      n_cycle_max_ready_i => s_n_cycle_max_ready,
      DMTD_max_en_o       => s_DMTD_max_en,
      DMTD_locked_o       => s_DMTD_locked
      );

  -----------------------------------------------------------------------------
  -- Locker monitoring
  -----------------------------------------------------------------------------
  i_locker_monitoring_1 : entity work.locker_monitoring
    generic map (
      g_threshold => g_threshold)
    port map (
      clk_i            => hs_var_clk_i,
      data_i           => data_i,
      locked_i         => s_DMTD_locked,
      incr_freq_o      => incr_freq_o,
      change_freq_en_o => change_freq_en_o
      );


end architecture rtl;
