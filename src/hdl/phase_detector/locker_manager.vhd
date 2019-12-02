-------------------------------------------------------------------------------
-- Title      : locker manager
-- Project    : 
-------------------------------------------------------------------------------
-- File       : locker_manager.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-11-26
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
-- 2019-11-26  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity locker_manager is

  port (
    ls_clk_i            : in  std_logic;
    rst_i               : in  std_logic;
    DMTD_en_i           : in  std_logic;
    n_cycle_i           : in  std_logic_vector(15 downto 0);
    n_cycle_ready_i     : in  std_logic;
    n_cycle_max_i       : in  std_logic_vector(15 downto 0);
    n_cycle_max_ready_i : in  std_logic;
    slocked_i           : in  std_logic;
    n_cycle_opt_o       : out std_logic_vector(15 downto 0);
    DMTD_max_en_o       : out std_logic;
    DMTD_locked_o       : out std_logic
    );

end entity locker_manager;

architecture rtl of locker_manager is

  type t_state is (st0_idle,
                   st1_calculate_n_cycle_max,
                   st2_am_i_half_n_max,
                   st3_wait_for_half_n_max,
                   st4_locked
                   );

  type t_fsm_signals is record
    lock        : std_logic;
    DMTD_max_en : std_logic;
    DMTD_locked : std_logic;
  end record t_fsm_signals;

  constant c_fsm_signals : t_fsm_signals := (
    lock        => '0',
    DMTD_max_en => '0',
    DMTD_locked => '0'
    );

  signal s_fsm_signals : t_fsm_signals;
  signal s_state       : t_state;

  signal s_lock : std_logic;
  signal s_n_cycle_max : std_logic_vector(15 downto 0);
  signal u_n_cycle_max : unsigned(15 downto 0);
  signal u_n_cycle_opt : unsigned(15 downto 0);

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- N_cycles max latcher
  -----------------------------------------------------------------------------
  p_n_cycle_max_latcher : process (ls_clk_i) is
  begin  -- process p_n_cycle_max_latcher
    if rising_edge(ls_clk_i) then       -- rising clock edge
      if n_cycle_max_ready_i = '1' then
        s_n_cycle_max <= n_cycle_max_i;
      end if;
    end if;
  end process p_n_cycle_max_latcher;

  u_n_cycle_max <= unsigned(s_n_cycle_max);
  u_n_cycle_opt <= shift_right(u_n_cycle_max, 1);
  n_cycle_opt_o <= std_logic_vector(u_n_cycle_opt);
  -----------------------------------------------------------------------------
  -- FSM
  -----------------------------------------------------------------------------
  p_update_state : process (ls_clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if DMTD_en_i = '1' then
            s_state <= st1_calculate_n_cycle_max;
          end if;
        --
        when st1_calculate_n_cycle_max =>
          if n_cycle_max_ready_i = '1' then
            s_state <= st2_am_i_half_n_max;
          end if;
        --
        when st2_am_i_half_n_max =>
          if n_cycle_ready_i = '1' then
            if n_cycle_i = std_logic_vector(u_n_cycle_opt) then
              s_state <= st4_locked;
            else
              s_state <= st3_wait_for_half_n_max;
            end if;
          end if;
        --
        when st3_wait_for_half_n_max =>
          s_state <= st2_am_i_half_n_max;
        --
        when st4_locked =>
          if slocked_i = '1' then
            s_state <= st0_idle;
          end if;
        --
        when others =>
          s_state <= st0_idle;
      --
      end case;
    end if;
  end process p_update_state;

  p_update_output : process (s_state) is
  begin  -- process p_update_output
    s_fsm_signals <= c_fsm_signals;
    case s_state is
      --
      when st0_idle =>
        null;
      --
      when st1_calculate_n_cycle_max =>
        s_fsm_signals.lock        <= '1';
        s_fsm_signals.DMTD_max_en <= '1';
      --
      when st2_am_i_half_n_max =>
        s_fsm_signals.lock <= '1';
      --
      when st3_wait_for_half_n_max =>
        s_fsm_signals.lock <= '1';
      --
      when st4_locked =>
        s_fsm_signals.DMTD_locked <= '1';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  s_lock        <= s_fsm_signals.lock;
  DMTD_max_en_o <= s_fsm_signals.DMTD_max_en;
  DMTD_locked_o <= s_fsm_signals.DMTD_locked;



end architecture rtl;
