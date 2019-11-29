-------------------------------------------------------------------------------
-- Title      : phase detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_detector.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-18
-- Last update: 2019-11-29
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
-- 2019-10-18  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMTD is
  generic (
    g_threshold : positive := 16
    );
  port (
    ls_clk_i         : in  std_logic;
    hs_fixed_clk_i   : in  std_logic;
    hs_var_clk_i     : in  std_logic;
    rst_i            : in  std_logic;
    DMTD_en_i        : in  std_logic;
    DMTD_locked_o    : out std_logic;
    incr_freq_o      : out std_logic;
    change_freq_en_o : out std_logic
    );
end entity DMTD;

architecture rtl of DMTD is

  signal s_n_cycle           : std_logic_vector(7 downto 0);
  signal s_n_cycle_ready     : std_logic;
  signal s_n_cycle_max       : std_logic_vector(7 downto 0);
  signal s_n_cycle_max_ready : std_logic;
  signal s_slocked           : std_logic;
  signal s_DMTD_max_en       : std_logic;
  signal s_DMTD_locked       : std_logic;
  signal s_output_fixed_clk  : std_logic;
  signal s_output_var_clk    : std_logic;
  signal s_DMTD_slocked      : std_logic;
  signal s_incr_freq         : std_logic;
  signal s_change_freq_en    : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Connections to top_level ports
  -----------------------------------------------------------------------------
  DMTD_locked_o <= s_DMTD_locked;

  -----------------------------------------------------------------------------
  -- Obtain Output
  -----------------------------------------------------------------------------
  i_slow_phase_analyzer_1 : entity work.slow_phase_analyzer
    port map (
      hs_clk_i => hs_fixed_clk_i,
      ls_clk_i => ls_clk_i,
      output_o => s_output_fixed_clk
      );

  i_slow_phase_analyzer_2 : entity work.slow_phase_analyzer
    port map (
      hs_clk_i => hs_var_clk_i,
      ls_clk_i => ls_clk_i,
      output_o => s_output_var_clk
      );

  -----------------------------------------------------------------------------
  -- Calculate n_cycle
  -----------------------------------------------------------------------------
  i_n_cycles_calc_1 : entity work.n_cycles_calc
    port map (
      ls_clk_i        => ls_clk_i,
      output_A_i      => s_output_fixed_clk,
      output_B_i      => s_output_var_clk,
      calc_en_i       => DMTD_en_i,
      rst_i           => rst_i,
      n_cycle_o       => s_n_cycle,
      n_cycle_ready_o => s_n_cycle_ready
      );

  i_n_cycles_max_calc : entity work.n_cycles_calc
    port map (
      ls_clk_i        => ls_clk_i,
      output_A_i      => s_output_fixed_clk,
      output_B_i      => s_output_fixed_clk,
      calc_en_i       => s_DMTD_max_en,
      rst_i           => rst_i,
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
      slocked_i           => s_DMTD_slocked,
      DMTD_max_en_o       => s_DMTD_max_en,
      DMTD_locked_o       => s_DMTD_locked
      );

  -----------------------------------------------------------------------------
  -- Locker monitoring FSM
  -----------------------------------------------------------------------------
  i_locker_monitoring_1 : entity work.locker_monitoring
    generic map (
      g_threshold => g_threshold
      )
    port map (
      ls_clk_i            => ls_clk_i,
      rst_i               => rst_i,
      n_cycle_i           => s_n_cycle,
      n_cycle_ready_i     => s_n_cycle_ready,
      n_cycle_max_i       => s_n_cycle_max,
      n_cycle_max_ready_i => s_n_cycle_max_ready,
      locked_i            => s_DMTD_locked,
      slocked_o           => s_DMTD_slocked,
      incr_freq_o         => incr_freq_o,
      change_freq_en_o    => change_freq_en_o
      );


end architecture rtl;
