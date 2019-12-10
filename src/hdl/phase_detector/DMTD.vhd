-------------------------------------------------------------------------------
-- Title      : phase detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_detector.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-18
-- Last update: 2019-12-10
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

  signal s_n_cycle           : std_logic_vector(15 downto 0);
  signal s_n_cycle_latch     : std_logic_vector(15 downto 0);
  signal s_n_cycle_ready     : std_logic;
  signal s_n_cycle_max       : std_logic_vector(15 downto 0);
  signal s_n_cycle_max_ready : std_logic;
  signal s_slocked           : std_logic;
  signal s_DMTD_max_en       : std_logic;
  signal s_DMTD_locked       : std_logic;
  signal s_output_fixed_clk  : std_logic;
  signal s_output_var_clk    : std_logic;
  signal s_DMTD_slocked      : std_logic;
  signal s_incr_freq         : std_logic;
  signal s_change_freq_en    : std_logic;

  attribute mark_debug                    : string;
  attribute mark_debug of s_n_cycle       : signal is "true";
  attribute mark_debug of s_n_cycle_ready : signal is "true";
  attribute mark_debug of s_n_cycle_latch : signal is "true";

  -- attribute dont_touch : string;
  -- attribute dont_touch of s_n_cycle  : signal is "true";
  -- attribute dont_touch of s_n_cycle_ready  : signal is "true";

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

  -----------------------------------------------------------------------------
  -- debut to delete
  -----------------------------------------------------------------------------
  DMTD_locked_o <= '1';
  -- incr_freq_o <= '1';
  -- change_freq_en_o <= '1';

  -----------------------------------------------------------------------------
  -- n_cycle_latch
  -----------------------------------------------------------------------------
  p_n_cycle_latch_debug : process (ls_clk_i) is
  begin  -- process p_n_cycle_latch_debug
    if rising_edge(ls_clk_i) then       -- rising clock edge
      if s_n_cycle_ready = '1' then
        s_n_cycle_latch <= s_n_cycle;
      end if;
    end if;
  end process p_n_cycle_latch_debug;

  incr_freq_o      <= s_output_fixed_clk;
  change_freq_en_o <= s_output_var_clk;

  -- i_n_cycles_max_calc : entity work.n_cycles_calc
  --   port map (
  --     ls_clk_i        => ls_clk_i,
  --     output_A_i      => s_output_fixed_clk,
  --     output_B_i      => s_output_fixed_clk,
  --     calc_en_i       => s_DMTD_max_en,
  --     rst_i           => rst_i,
  --     n_cycle_o       => s_n_cycle_max,
  --     n_cycle_ready_o => s_n_cycle_max_ready
  --     );

  -- -----------------------------------------------------------------------------
  -- -- Locker manager FSM
  -- -----------------------------------------------------------------------------
  -- i_locker_manager_1 : entity work.locker_manager
  --   port map (
  --     ls_clk_i            => ls_clk_i,
  --     rst_i               => rst_i,
  --     DMTD_en_i           => DMTD_en_i,
  --     n_cycle_i           => s_n_cycle,
  --     n_cycle_ready_i     => s_n_cycle_ready,
  --     n_cycle_max_i       => s_n_cycle_max,
  --     n_cycle_max_ready_i => s_n_cycle_max_ready,
  --     slocked_i           => s_DMTD_slocked,
  --     DMTD_max_en_o       => s_DMTD_max_en,
  --     DMTD_locked_o       => s_DMTD_locked
  --     );

  -- -----------------------------------------------------------------------------
  -- -- Locker monitoring FSM
  -- -----------------------------------------------------------------------------
  -- i_locker_monitoring_1 : entity work.locker_monitoring
  --   generic map (
  --     g_threshold => g_threshold
  --     )
  --   port map (
  --     ls_clk_i            => ls_clk_i,
  --     rst_i               => rst_i,
  --     n_cycle_i           => s_n_cycle,
  --     n_cycle_ready_i     => s_n_cycle_ready,
  --     n_cycle_max_i       => s_n_cycle_max,
  --     n_cycle_max_ready_i => s_n_cycle_max_ready,
  --     locked_i            => s_DMTD_locked,
  --     slocked_o           => s_DMTD_slocked,
  --     incr_freq_o         => incr_freq_o,
  --     change_freq_en_o    => change_freq_en_o
  --     );


end architecture rtl;
