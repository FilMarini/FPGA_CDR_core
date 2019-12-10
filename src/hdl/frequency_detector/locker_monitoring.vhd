-------------------------------------------------------------------------------
-- Title      : locker monitoring
-- Project    : 
-------------------------------------------------------------------------------
-- File       : locker_monitoring.vhd
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

entity locker_monitoring is
  generic (
    g_threshold : positive := 32,
    g_bit_num_time_interval : positive := 8
    );
  port (
    clk_i            : in  std_logic;
    data_i           : in  std_logic;
    locked_i         : in  std_logic;
    incr_freq_o      : out std_logic;
    change_freq_en_o : out std_logic
    );
end entity locker_monitoring;

architecture rtl of locker_monitoring is

  signal s_decr_freq_raw : std_logic;
  signal s_incr_freq_raw : std_logic;
  signal s_decr_freq     : std_logic;
  signal s_incr_freq     : std_logic;

begin  -- architecture rtl

  i_phase_detector_1 : entity work.phase_detector
    port map (
      data_in => data_i,
      sys_clk => clk_i,
      x       => s_decr_freq_raw,
      y       => s_incr_freq_raw
      );

  i_phase_shift_filter_1 : entity work.phase_shift_filter
    generic map (
      threshold             => g_threshold,
      bit_num_time_interval => 8
      )
    port map (
      sys_clk        => clk_i,
      en_i           => locked_i,
      phase_up_raw   => s_decr_freq_raw,
      phase_down_raw => s_incr_freq_raw,
      phase_up       => s_decr_freq,
      phase_down     => s_incr_freq
      );

  freq_controller_1 : entity work.freq_controller
    port map (
      clk_i            => clk_i,
      en_i             => locked_i,
      incr_freq_i      => s_incr_freq,
      decr_freq_i      => s_decr_freq,
      incr_freq_o      => incr_freq_o,
      change_freq_en_o => change_freq_en_o
      );


end architecture rtl;
