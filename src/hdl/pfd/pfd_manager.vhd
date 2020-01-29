-------------------------------------------------------------------------------
-- Title      : Phase and Frequency Detector manager
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pfd_manager.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : University of Padova, INFN Padova
-- Created    : 2020-01-27
-- Last update: 2020-01-29
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

entity pfd_manager is

  generic (
    g_bit_num         : positive := 8;
    g_lock_threshold  : positive := 64;   -- 25%
    g_slock_threshold : positive := 128  -- 50%
    );
  port (
    clk_i         : in  std_logic;
    rst_i         : in  std_logic;
    en_i          : in  std_logic;
    en_out_i      : in  std_logic;
    shifting_i    : in  std_logic;
    shifting_en_i : in  std_logic;
    locked_o      : out std_logic;
    M_change_en_o : out std_logic;
    M_incr_o      : out std_logic
    );
end entity pfd_manager;

architecture rtl of pfd_manager is

  type t_manager_state is (st0_idle,
                           st1_counting,
                           st2_evaluate,
                           st3a_M_up,
                           st3b_M_down,
                           st4_locked
                           );

  type t_fsm_signal is record
    counting : std_logic;
    M_up     : std_logic;
    M_down   : std_logic;
  end record t_fsm_signal;

  constant c_fsm_signal : t_fsm_signal := (
    counting => '0';
    M_up     => '0';
    M_down   => '0'
    );

  signal s_fsm_signal          : t_fsm_signal;
  signal s_state               : t_manager_state;
  signal s_M_down              : std_logic;
  signal s_M_up                : std_logic;
  signal s_M_vec               : std_logic_vector(2 downto 0);
  signal s_counting            : std_logic;
  signal s_shift_counter       : std_logic_vector(31 downto 0);
  signal u_shift_counter       : unsigned(31 downto 0);
  signal sgd_shift_accumulator : signed(31 downto 0);

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
          if s_locked <= '1' then
            if sgd_shift_accumulator > g_lock_threshold then
              s_state <= st3a_M_up;
            elsif sgd_shift_accumulator < (- g_lock_threshold) then
              s_state <= st3b_M_down;
            else
              s_state <= st4_locked;
            end if;
          else
            if sgd_shift_accumulator > g_slock_threshold then
              s_state <= st3a_M_up;
            elsif sgd_shift_accumulator < (- g_slock_threshold) then
              s_state <= st3b_M_down;
            else
              s_state <= st4_locked;
            end if;
          end if;
        --
        when st3a_M_down =>
          s_state <= st0_idle;
        --
        when st3b_M_up =>
          s_state <= st0_idle;
        --
        when st4_locked =>
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
        null;
      --
      when st1_counting =>
        s_fsm_signal.counting <= '1';
      --
      when st2_evaluate =>
        null;
      --
      when st3a_M_down =>
        s_fsm_signal.M_down <= '1';
        s_locked            <= '0';
      --
      when st3b_M_up =>
        s_fsm_signal.M_up <= '1';
        s_locked          <= '0';
      --
      when st4_locked =>
        s_locked <= '1';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  s_M_down   <= s_fsm_signal.M_down;
  s_M_up     <= s_fsm_signal.M_up;
  s_counting <= s_fsm_signal.counting;

  -----------------------------------------------------------------------------
  -- Shifting counter and accumulator
  -----------------------------------------------------------------------------
  p_shifting_counter : process (clk_i, rst_i) is
  begin  -- process p_shifting_counter
    if rst_i = '1' or s_counting = '0' then  -- asynchronous reset (active high)
      u_shift_counter <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if shifting_en_i = '1' then
        u_shift_counter <= u_shift_counter + 1;
      end if;
    end if;
  end process p_shifting_counter;

  s_shift_counter <= std_logic_vector(u_shift_counter);

  p_shifting_accumulator : process (clk_i, rst_i) is
  begin  -- process p_shifting_accumulator
    if rst_i = '1' or s_counting = '0' then  -- asynchronous reset (active high)
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
  -- Output control
  -----------------------------------------------------------------------------
  s_M_vec <= en_out_i & s_M_up & s_M_down;

  p_output_control : process (s_M_vec) is
  begin  -- process p_output_control
    case s_M_vec is
      when "110" =>
        M_change_en_o <= '1';
        M_incr_o      <= '1';
      when "101" =>
        M_change_en_o <= '1';
        M_incr_o      <= '0';
      when others =>
        M_change_en_o <= '0';
        M_incr_o      <= '0';
    end case;
  end process p_output_control;


end architecture rtl;
