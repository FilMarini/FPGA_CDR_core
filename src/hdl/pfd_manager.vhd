-------------------------------------------------------------------------------
-- Title      : Phase and Frequency Detector manager
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pfd_manager.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : University of Padova, INFN Padova
-- Created    : 2020-01-27
-- Last update: 2020-03-06
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Find the closest M (frequency) matching the data rate 
-- when locked, the frequency is the closest (approximately)
-------------------------------------------------------------------------------
-- Copyright (c) 2020 University of Padova, INFN Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-27  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library extras;
use extras.synchronizing.all;

entity pfd_manager is

  generic (
    g_bit_num         : positive := 7;
    g_act_threshold   : positive := 96;  -- 75%
    g_lock_threshold  : positive := 8;   -- 6.25%
    g_slock_threshold : positive := 112  -- 87.5%
    );
  port (
    clk_i         : in  std_logic;
    rst_i         : in  std_logic;
    en_i          : in  std_logic;
    shifting_i    : in  std_logic;
    shifting_en_i : in  std_logic;
    locked_o      : out std_logic;
    M_ctrl_o      : out std_logic;
    M_change_en_o : out std_logic;
    M_incr_o      : out std_logic
    );
end entity pfd_manager;

architecture rtl of pfd_manager is

  type t_manager_state is (st0_idle,
                           st1_counting,
                           st2_evaluate,
                           st3a_M_up,
                           st3b_M_down
                           );

  type t_fsm_signal is record
    idle     : std_logic;
    counting : std_logic;
    evaluate : std_logic;
    M_up     : std_logic;
    M_down   : std_logic;
  end record t_fsm_signal;

  constant c_fsm_signal : t_fsm_signal := (
    idle     => '0',
    counting => '0',
    evaluate => '0',
    M_up     => '0',
    M_down   => '0'
    );

  signal s_state                 : t_manager_state;
  signal s_fsm_signal            : t_fsm_signal;
  signal s_idle                  : std_logic;
  signal s_counting              : std_logic;
  signal s_evaluate              : std_logic;
  signal s_counter_rst           : std_logic;
  signal s_lock_set              : std_logic;
  signal s_lock_rst              : std_logic;
  signal s_locked                : std_logic;
  signal u_shift_counter         : unsigned(15 downto 0);
  signal s_shift_counter         : std_logic_vector(15 downto 0);
  signal sgd_shift_accumulator   : signed(15 downto 0);
  signal s_M_vec                 : std_logic_vector(1 downto 0);
  signal s_M_change_en           : std_logic;
  signal s_M_change_en_stretched : std_logic;
  signal s_M_incr                : std_logic;
  signal s_M_incr_stretched      : std_logic;
  signal s_M_ctrl                : std_logic;
  signal s_M_ctrl_df             : std_logic;

  alias s_M_up   : std_logic is s_M_vec(1);
  alias s_M_down : std_logic is s_M_vec(0);

  attribute mark_debug                          : string;
  attribute mark_debug of s_state               : signal is "true";
  attribute mark_debug of s_shift_counter       : signal is "true";
  attribute mark_debug of sgd_shift_accumulator : signal is "true";

begin  -- architecture rtl

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
          if en_i = '1' then
            s_state <= st1_counting;
          end if;
        --
        when st1_counting =>
          if s_shift_counter(g_bit_num) = '1' then
            s_state <= st2_evaluate;
          end if;
        --
        when st2_evaluate =>
          if s_locked = '1' then
            if sgd_shift_accumulator > g_act_threshold then
              s_state <= st3a_M_up;
            elsif sgd_shift_accumulator < (- g_act_threshold) then
              s_state <= st3b_M_down;
            else
              s_state <= st0_idle;
            end if;
          else
            if sgd_shift_accumulator > g_lock_threshold then
              s_state <= st3a_M_up;
            elsif sgd_shift_accumulator < (- g_lock_threshold) then
              s_state <= st3b_M_down;
            else
              s_state <= st0_idle;
            end if;
          end if;
        --
        when st3a_M_up =>
          s_state <= st0_idle;
        --
        when st3b_M_down =>
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
        s_fsm_signal.idle <= '1';
      --
      when st1_counting =>
        s_fsm_signal.counting <= '1';
      --
      when st2_evaluate =>
        s_fsm_signal.evaluate <= '1';
      --
      when st3a_M_up =>
        s_fsm_signal.M_up <= '1';
      --
      when st3b_M_down =>
        s_fsm_signal.M_down <= '1';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  s_idle     <= s_fsm_signal.idle;
  s_M_down   <= s_fsm_signal.M_down;
  s_M_up     <= s_fsm_signal.M_up;
  s_counting <= s_fsm_signal.counting;
  s_evaluate <= s_fsm_signal.evaluate;

  -----------------------------------------------------------------------------
  -- Shifting counter and accumulator
  -----------------------------------------------------------------------------
  s_counter_rst <= or_reduce(std_logic_vector'(rst_i & s_idle));

  p_shifting_counter : process (clk_i, s_counter_rst) is
  begin  -- process p_shifting_counter
    if s_counter_rst = '1' then         -- asynchronous reset (active high)
      u_shift_counter <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if shifting_en_i = '1' then
        u_shift_counter <= u_shift_counter + 1;
      end if;
    end if;
  end process p_shifting_counter;

  s_shift_counter <= std_logic_vector(u_shift_counter);

  p_shifting_accumulator : process (clk_i, s_counter_rst) is
  begin  -- process p_shifting_accumulator
    if s_counter_rst = '1' then         -- asynchronous reset (active high)
      sgd_shift_accumulator <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if shifting_en_i = '1' and shifting_i = '1' then
        sgd_shift_accumulator <= sgd_shift_accumulator + 1;
      elsif shifting_en_i = '1' and shifting_i = '0' then
        sgd_shift_accumulator <= sgd_shift_accumulator - 1;
      end if;
    end if;
  end process p_shifting_accumulator;

  -----------------------------------------------------------------------------
  -- Locker
  -----------------------------------------------------------------------------
  p_locker : process (clk_i) is
  begin  -- process p_locker
    if rising_edge(clk_i) then          -- rising clock edge
      if s_evaluate = '1' then
        if abs(sgd_shift_accumulator) < g_lock_threshold then
          s_lock_set <= '1';
        else
          s_lock_set <= '0';
        end if;
        if abs(sgd_shift_accumulator) > g_slock_threshold then
          s_lock_rst <= '1';
        else
          s_lock_rst <= '0';
        end if;
      end if;
    end if;
  end process p_locker;

  set_reset_ffd_1 : entity work.set_reset_ffd
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i   => clk_i,
      set_i   => s_lock_set,
      reset_i => s_lock_rst,
      q_o     => s_locked
      );

  -----------------------------------------------------------------------------
  -- Output control
  -----------------------------------------------------------------------------
  p_output_control : process (clk_i) is
  begin  -- process p_output_control
    if rising_edge(clk_i) then
      case s_M_vec is
        when "10" =>
          s_M_change_en <= '1';
          s_M_incr      <= '1';
        when "01" =>
          s_M_change_en <= '1';
          s_M_incr      <= '0';
        when others =>
          s_M_change_en <= '0';
          s_M_incr      <= '0';
      end case;
    end if;
  end process p_output_control;

  i_pulse_stretcher_1 : entity work.pulse_stretcher
    generic map (
      g_num_of_steps => 5
      )
    port map (
      clk_i => clk_i,
      rst_i => rst_i,
      d_i   => s_M_change_en,
      q_o   => s_M_change_en_stretched
      );

  i_pulse_stretcher_2 : entity work.pulse_stretcher
    generic map (
      g_num_of_steps => 5
      )
    port map (
      clk_i => clk_i,
      rst_i => rst_i,
      d_i   => s_M_incr,
      q_o   => s_M_incr_stretched
      );

  i_pulse_stretcher_3 : entity work.pulse_stretcher
    generic map (
      g_num_of_steps => 3
      )
    port map (
      clk_i => clk_i,
      rst_i => rst_i,
      d_i   => s_M_change_en,
      q_o   => s_M_ctrl
      );

  i_bit_synchronizer_1 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => clk_i,
      Reset  => rst_i,
      Bit_in => s_M_ctrl,
      Sync   => s_M_ctrl_df
      );

  locked_o      <= s_locked;
  M_ctrl_o      <= s_M_ctrl_df;
  M_change_en_o <= s_M_change_en_stretched;
  M_incr_o      <= s_M_incr_stretched;


end architecture rtl;
