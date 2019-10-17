-------------------------------------------------------------------------------
-- Title      : n_cycle calculator
-- Project    : 
-------------------------------------------------------------------------------
-- File       : n_cycles_calc.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-16
-- Last update: 2019-10-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: FSM to calculate n_cycle 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-16  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_cycles_calc is
  port (
    ls_clk_i        : in  std_logic;
    output_A_i      : in  std_logic;
    output_B_i      : in  std_logic;
    calc_en_i       : in  std_logic;
    rst_i           : in  std_logic;
    n_cycle_o       : out std_logic_vector(7 downto 0);
    n_cycle_ready_o : out std_logic
    );
end entity n_cycles_calc;

architecture rtl of n_cycles_calc is

  type t_state is (st0_idle,
                   st1_set,
                   st2_counting,
                   st3_evaluate
                   );

  type t_fsm_signals is record
    idle     : std_logic;
    lock     : std_logic;
    counting : std_logic;
    evaluate : std_logic;
  end record t_fsm_signals;

  constant c_fsm_signals : t_fsm_signals := (
    idle     => '0',
    lock     => '0',
    counting => '0',
    evaluate => '0'
    );

  signal s_state           : t_state;
  signal s_fsm_signals     : t_fsm_signals;
  signal s_output_A_re     : std_logic;
  signal s_output_B_re     : std_logic;
  signal u_bomb            : unsigned(31 downto 0);
  signal s_bomb_count      : std_logic_vector(31 downto 0);
  signal s_bomb            : std_logic;
  signal u_n_cycle_counter : unsigned(7 downto 0);
  signal s_idle            : std_logic;
  signal s_counting        : std_logic;
  signal s_lock            : std_logic;
  signal s_evaluate        : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Output rising edge detector
  -----------------------------------------------------------------------------
  r_edge_detect_A : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => output_A_i,
      sig_o => s_output_A_re
      );

  r_edge_detect_B : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => output_B_i,
      sig_o => s_output_B_re
      );

  -----------------------------------------------------------------------------
  -- Timeout
  -----------------------------------------------------------------------------
  p_bomb_count : process(ls_clk_i)
  begin
    if rising_edge(ls_clk_i) then
      if s_idle = '1' then
        u_bomb <= (others => '0');
      elsif s_lock = '1' then
        u_bomb <= u_bomb + 1;
      end if;
    end if;
  end process p_bomb_count;

  s_bomb_count <= std_logic_vector(u_bomb);

  p_bomb : process(ls_clk_i)
  begin
    if rising_edge(ls_clk_i) then
      if s_bomb_count(31) = '1' then
        s_bomb <= '1';
      else
        s_bomb <= '0';
      end if;
    end if;
  end process p_bomb;

  -----------------------------------------------------------------------------
  -- n_cycle counter
  -----------------------------------------------------------------------------
  p_n_cycle_counter : process (ls_clk_i, rst_i) is
  begin  -- process p_n_cycle_counter
    if rst_i = '1' or s_idle = '1' then                 -- asynchronous reset (active high)
      u_n_cycle_counter <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      if s_counting = '1' then
        u_n_cycle_counter <= u_n_cycle_counter + 1;
      end if;
    end if;
  end process p_n_cycle_counter;

  n_cycle_o <= std_logic_vector(u_n_cycle_counter);

  n_cycle_ready_o <= s_evaluate;

  -----------------------------------------------------------------------------
  -- FSM
  -----------------------------------------------------------------------------
  p_update_state : process (ls_clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' or calc_en_i = '0' or s_bomb = '1' then  -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(ls_clk_i) then        -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if calc_en_i = '1' then
            s_state <= st1_set;
          end if;
        --
        when st1_set =>
          if s_output_A_re = '1' then
            s_state <= st2_counting;
          end if;
        --
        when st2_counting =>
          if s_output_B_re = '1' then
            s_state <= st3_evaluate;
          end if;
        --
        when st3_evaluate =>
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
    s_fsm_signals <= c_fsm_signals;
    case s_state is
      --
      when st0_idle =>
        s_fsm_signals.idle <= '1';
      --
      when st1_set =>
        s_fsm_signals.lock <= '1';
      --
      when st2_counting =>
        s_fsm_signals.lock     <= '1';
        s_fsm_signals.counting <= '1';
      --
      when st3_evaluate =>
        s_fsm_signals.lock     <= '1';
        s_fsm_signals.evaluate <= '1';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  s_idle     <= s_fsm_signals.idle;
  s_lock     <= s_fsm_signals.lock;
  s_counting <= s_fsm_signals.counting;
  s_evaluate <= s_fsm_signals.evaluate;


end architecture rtl;
