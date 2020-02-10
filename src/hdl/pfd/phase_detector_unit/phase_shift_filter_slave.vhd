-------------------------------------------------------------------------------
-- Title      : phase shift filter slave
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_shift_filter_slave.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : University of Padova, INFN Padova
-- Created    : 2020-01-30
-- Last update: 2020-02-10
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: With this module, the starting of the counter is managed by a
-- master module, and the threshold is equal to the number of transition detected 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 University of Padova, INFN Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-30  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library extras;
use extras.synchronizing.all;

entity phase_shift_filter_slave is
  generic (
    -- mu,ner of clk cycles to strech the output pulses
    g_steps_to_strech : natural  := 3;
    g_num_trans_min   : positive := 8
    );
  port (
    clk_i          : in  std_logic;
    rst_i          : in  std_logic;
    window_i       : in  std_logic;
    phase_up_raw   : in  std_logic;
    phase_down_raw : in  std_logic;
    ready_o        : out std_logic;
    phase_up       : out std_logic;
    phase_down     : out std_logic
    );
end entity phase_shift_filter_slave;

architecture rtl of phase_shift_filter_slave is

  type t_filter_state is (st0_idle,
                          st1_counting,
                          st2_evaluate,
                          st3a_phase_up,
                          st3b_phase_down
                          );

  type t_fsm_signal is record
    ready      : std_logic;
    counting   : std_logic;
    phase_up   : std_logic;
    phase_down : std_logic;
  end record t_fsm_signal;

  constant c_fsm_signal : t_fsm_signal := (
    ready      => '0',
    counting   => '0',
    phase_up   => '0',
    phase_down => '0'
    );

  signal s_fsm_signal         : t_fsm_signal;
  signal s_state              : t_filter_state;
  signal sgd_trans_counter    : signed(31 downto 0) := (others => '0');
  signal sgd_phase_counter    : signed(31 downto 0) := (others => '0');
  signal s_transition_occured : std_logic;
  signal s_phase_vector       : std_logic_vector(1 downto 0);
  signal s_phase_up           : std_logic;
  signal s_phase_down         : std_logic;
  signal s_phase_up_synch     : std_logic;
  signal s_phase_down_synch   : std_logic;
  signal s_ready              : std_logic;
  signal s_counting           : std_logic;
  signal s_trans_ok           : std_logic;

  alias s_trans_to_check : std_logic is sgd_trans_counter(g_num_trans_min);

  attribute mark_debug : string;
  attribute mark_debug of s_state : signal is "true";
  attribute mark_debug of sgd_trans_counter : signal is "true";
  attribute mark_debug of sgd_phase_counter : signal is "true";

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Bit Synchronizer
  -----------------------------------------------------------------------------
  bit_synchronizer_1 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i,
      Reset  => rst_i,
      Bit_in => phase_up_raw,
      Sync   => s_phase_up_synch
      );

  bit_synchronizer_2 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i,
      Reset  => rst_i,
      Bit_in => phase_down_raw,
      Sync   => s_phase_down_synch
      );

  -----------------------------------------------------------------------------
  -- FSM
  -----------------------------------------------------------------------------
  p_update_state : process (clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(clk_i) then       -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if window_i = '1' then
            s_state <= st1_counting;
          end if;
        --
        when st1_counting =>
          if window_i = '0' then
            s_state <= st2_evaluate;
          end if;
        --
        when st2_evaluate =>
          if s_trans_ok = '1' then
            if sgd_phase_counter = sgd_trans_counter then
              s_state <= st3a_phase_up;
            elsif sgd_phase_counter = - (sgd_trans_counter) then
              s_state <= st3b_phase_down;
            else
              s_state <= st0_idle;
            end if;
          else
            s_state <= st0_idle;
          end if;
        --
        when st3a_phase_up =>
          s_state <= st0_idle;
        --
        when st3b_phase_down =>
          s_state <= st0_idle;
        --
        when others =>
          null;
      --
      end case;
    end if;
  end process p_update_state;

  p_update_output : process (s_state) is
  begin  -- process p_update_output
    s_fsm_signal <= c_fsm_signal;
    case s_state is
      --
      when st0_idle =>
        s_fsm_signal.ready <= '1';
      --
      when st1_counting =>
        s_fsm_signal.counting <= '1';
      --
      when st2_evaluate =>
        null;
      --
      when st3a_phase_up =>
        s_fsm_signal.phase_up <= '1';
      --
      when st3b_phase_down =>
        s_fsm_signal.phase_down <= '1';
      --
      when others => null;
    end case;
  end process p_update_output;

  s_ready      <= s_fsm_signal.ready;
  s_counting   <= s_fsm_signal.counting;
  s_phase_up   <= s_fsm_signal.phase_up;
  s_phase_down <= s_fsm_signal.phase_down;

  -----------------------------------------------------------------------------
  -- Transition and phase counter
  -----------------------------------------------------------------------------
  s_phase_vector       <= s_phase_up_synch & s_phase_down_synch;
  s_transition_occured <= or_reduce(s_phase_vector);

  p_trans_counter : process (clk_i, s_ready) is
  begin  -- process p_trans_counter
    if s_ready = '1' then               -- asynchronous reset (active low)
      sgd_trans_counter <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if s_transition_occured = '1' then
        sgd_trans_counter <= sgd_trans_counter + 1;
      end if;
    end if;
  end process p_trans_counter;

  p_phase_counter : process (clk_i, s_ready) is
  begin  -- process p_phase_counter
    if s_ready = '1' then               -- asynchronous reset (active low)
      sgd_phase_counter <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if s_phase_up_synch = '1' and s_phase_down_synch = '0' then
        sgd_phase_counter <= sgd_phase_counter + 1;
      elsif s_phase_up_synch = '0' and s_phase_down_synch = '1' then
        sgd_phase_counter <= sgd_phase_counter - 1;
      end if;
    end if;
  end process p_phase_counter;

  -----------------------------------------------------------------------------
  -- Check for minimum transition detected
  -----------------------------------------------------------------------------
  set_reset_ffd_1 : entity work.set_reset_ffd
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i   => clk_i,
      set_i   => s_trans_to_check,
      reset_i => s_ready,
      q_o     => s_trans_ok
      );

  -----------------------------------------------------------------------------
  -- Pulse stretcher
  -----------------------------------------------------------------------------
  pulse_stretcher_1 : entity work.pulse_stretcher
    generic map (
      g_num_of_steps => g_steps_to_strech
      )
    port map (
      clk_i => clk_i,
      rst_i => rst_i,
      d_i   => s_phase_up,
      q_o   => phase_up
      );

  pulse_stretcher_2 : entity work.pulse_stretcher
    generic map (
      g_num_of_steps => g_steps_to_strech
      )
    port map (
      clk_i => clk_i,
      rst_i => rst_i,
      d_i   => s_phase_down,
      q_o   => phase_down
      );

  -----------------------------------------------------------------------------
  -- Output control
  -----------------------------------------------------------------------------
  ready_o <= s_ready;

end architecture rtl;
