-------------------------------------------------------------------------------
-- Title      : phase and frequency detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pfd.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : 
-- Created    : 2020-01-17
-- Last update: 2020-03-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-17  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library extras;
use extras.synchronizing.all;

entity pfd is
  generic (
    g_pd_num_trans : positive := 10
    );
  port (
    clk_i_i       : in  std_logic;
    clk_q_i       : in  std_logic;
    rst_i         : in  std_logic;
    en_i          : in  std_logic;
    data_i        : in  std_logic;
    locked_o      : out std_logic;
    shifting_o    : out std_logic;
    shifting_en_o : out std_logic
    --debug
    -- gpio_o        : out std_logic
    );
end entity pfd;

architecture rtl of pfd is

  signal s_x                   : std_logic;
  signal s_y                   : std_logic;
  signal s_q_x                 : std_logic;
  signal s_q_y                 : std_logic;
  signal s_up_unsync           : std_logic;
  signal s_down_unsync         : std_logic;
  signal s_q_up_unsync         : std_logic;
  signal s_q_down_unsync       : std_logic;
  signal s_up                  : std_logic;
  signal s_down                : std_logic;
  signal s_q_up                : std_logic;
  signal s_q_down              : std_logic;
  signal s_quadrant            : std_logic_vector(1 downto 0);
  signal s_quadrant_rdy        : std_logic;
  signal s_i_ready             : std_logic;
  signal s_q_ready             : std_logic;
  signal s_slaves_ready        : std_logic_vector(1 downto 0);
  signal s_phase_filter_window : std_logic;
  signal s_locked              : std_logic;
  -- debug
  signal s_pulse_down          : std_logic;
  signal s_pulse_up            : std_logic;
  signal s_shifting_en         : std_logic;
  signal s_shifting            : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Phase detector
  -----------------------------------------------------------------------------
  i_phase_detector_in_phase : entity work.phase_detector
    port map (
      data_in => data_i,
      sys_clk => clk_i_i,
      x       => s_x,
      y       => s_y
      );

  i_phase_detector_quadrature : entity work.phase_detector
    port map (
      data_in => data_i,
      sys_clk => clk_q_i,
      x       => s_q_x,
      y       => s_q_y
      );

  -----------------------------------------------------------------------------
  -- Phase detector filter
  -----------------------------------------------------------------------------
  i_phase_shift_filter_master_1 : entity work.phase_shift_filter_master
    generic map (
      g_num_trans  => g_pd_num_trans,
      g_num_slaves => 2
      )
    port map (
      clk_i                 => clk_i_i,
      rst_i                 => rst_i,
      en_i                  => en_i,
      slaves_ready_i        => s_slaves_ready,
      phase_filter_window_o => s_phase_filter_window
      );

  i_phase_shift_filter_slave_1 : entity work.phase_shift_filter_slave
    generic map (
      g_steps_to_strech => 4,
      g_num_trans_min   => g_pd_num_trans - 3
      )
    port map (
      clk_i          => clk_i_i,
      rst_i          => rst_i,
      window_i       => s_phase_filter_window,
      phase_up_raw   => s_x,
      phase_down_raw => s_y,
      ready_o        => s_i_ready,
      phase_up       => s_up_unsync,
      phase_down     => s_down_unsync
      );

  i_phase_shift_filter_slave_2 : entity work.phase_shift_filter_slave
    generic map (
      g_steps_to_strech => 4,
      g_num_trans_min   => g_pd_num_trans - 3
      )
    port map (
      clk_i          => clk_q_i,
      rst_i          => rst_i,
      window_i       => s_phase_filter_window,
      phase_up_raw   => s_q_x,
      phase_down_raw => s_q_y,
      ready_o        => s_q_ready,
      phase_up       => s_q_up_unsync,
      phase_down     => s_q_down_unsync
      );

  s_slaves_ready <= s_i_ready & s_q_ready;

  -----------------------------------------------------------------------------
  -- Cross domain synchronizer
  -----------------------------------------------------------------------------
  i_bit_synchronizer_1 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i_i,
      Reset  => rst_i,
      Bit_in => s_up_unsync,
      Sync   => s_up
      );

  i_bit_synchronizer_2 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i_i,
      Reset  => rst_i,
      Bit_in => s_down_unsync,
      Sync   => s_down
      );

  i_bit_synchronizer_3 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i_i,
      Reset  => rst_i,
      Bit_in => s_q_up_unsync,
      Sync   => s_q_up
      );

  i_bit_synchronizer_4 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i_i,
      Reset  => rst_i,
      Bit_in => s_q_down_unsync,
      Sync   => s_q_down
      );

  -----------------------------------------------------------------------------
  -- Quadrant detector
  -----------------------------------------------------------------------------
  i_quadrant_detector_1 : entity work.quadrant_detector
    port map (
      clk_i          => clk_i_i,
      rst_i          => rst_i,
      i_early_i      => s_up,
      i_late_i       => s_down,
      q_early_i      => s_q_up,
      q_late_i       => s_q_down,
      quadrant_o     => s_quadrant,
      quadrant_rdy_o => s_quadrant_rdy
      );

  -----------------------------------------------------------------------------
  -- Quadrant shifting detector
  -----------------------------------------------------------------------------
  i_quadrant_shifter_detector_1 : entity work.quadrant_shifter_detector
    port map (
      clk_i               => clk_i_i,
      rst_i               => rst_i,
      quadrant_rdy_i      => s_quadrant_rdy,
      quadrant_i          => s_quadrant,
      shifting_detected_o => s_shifting_en,
      shifting_o          => s_shifting,
      locked_o            => s_locked
      );

  -----------------------------------------------------------------------------
  -- Output Control
  -----------------------------------------------------------------------------
  p_output_control : process (clk_i_i) is
  begin  -- process p_output_control
    if rising_edge(clk_i_i) then        -- rising clock edge
      shifting_en_o <= s_shifting_en;
      shifting_o    <= s_shifting;
      -- gpio_o        <= s_locked;
    end if;
  end process p_output_control;

  locked_o <= '1';

  -----------------------------------------------------------------------------
  -- Output debug
  -----------------------------------------------------------------------------
  -- p_shifting_control : process (s_shifting_en, s_shifting) is
  -- begin  -- process p_shifting_control
  --   if s_shifting_en = '1' then
  --     case s_shifting is
  --       when '1' =>
  --         s_pulse_up   <= '1';
  --         s_pulse_down <= '0';
  --       when '0' =>
  --         s_pulse_up   <= '0';
  --         s_pulse_down <= '1';
  --       when others => null;
  --     end case;
  --   else
  --     s_pulse_up   <= '0';
  --     s_pulse_down <= '0';
  --   end if;
  -- end process p_shifting_control;




end architecture rtl;
