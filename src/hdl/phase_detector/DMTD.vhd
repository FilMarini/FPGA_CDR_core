-------------------------------------------------------------------------------
-- Title      : Dual Mixer Time Difference
-- Project    : 
-------------------------------------------------------------------------------
-- File       : DMTD.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-16
-- Last update: 2019-10-17
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
-- 2019-10-16  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMTD is
  generic (
    g_counter_threshold : positive := 5
    );
  port (
    ls_clk_i         : in  std_logic;   -- ~ 31.125 MHz (62.5 * 20 / 41)
    hs_fixed_clk_i   : in  std_logic;   -- 62.5 MHz
    hs_var_clk_i     : in  std_logic;   -- 62.5 MHz
    rst_i            : in  std_logic;
    DMTD_en_i        : in  std_logic;
    change_freq_o    : out std_logic;
    change_freq_en_o : out std_logic
    );
end entity DMTD;

architecture rtl of DMTD is

  type t_state is (st0_idle,
                   st1_evaluating,
                   st2a_incr,
                   st2b_decr
                   );

  type t_fsm_signals is record
    idle : std_logic;
    lock : std_logic;
    incr : std_logic;
    en   : std_logic;
  end record t_fsm_signals;

  constant c_fsm_signals : t_fsm_signals := (
    idle => '0',
    lock => '0',
    incr => '0',
    en   => '0'
    );

  signal s_state            : t_state;
  signal s_fsm_signals      : t_fsm_signals;
  signal s_output_fixed_clk : std_logic;
  signal s_output_var_clk   : std_logic;
  signal s_n_cycle          : std_logic_vector(7 downto 0);
  signal s_n_cycle_ready    : std_logic;
  signal s_n_cycle_new      : std_logic_vector(7 downto 0);
  signal s_n_cycle_old      : std_logic_vector(7 downto 0);
  signal u_n_cycle_new      : signed(7 downto 0);
  signal u_n_cycle_old      : signed(7 downto 0);
  signal sgn_n_cycle_diff   : signed (7 downto 0);
  signal sgn_counter        : signed(7 downto 0);
  signal i_abs_n_cycle_diff : integer;
  signal u_bomb             : unsigned(31 downto 0);
  signal s_bomb_count       : std_logic_vector(31 downto 0);
  signal s_bomb             : std_logic;
  signal s_idle             : std_logic;
  signal s_lock             : std_logic;
  signal s_incr             : std_logic;
  signal s_en               : std_logic;

begin  -- architecture rtl

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
  n_cycles_calc_1 : entity work.n_cycles_calc
    port map (
      ls_clk_i        => ls_clk_i,
      output_A_i      => s_output_fixed_clk,
      output_B_i      => s_output_var_clk,
      calc_en_i       => '1',
      rst_i           => rst_i,
      n_cycle_o       => s_n_cycle,
      n_cycle_ready_o => s_n_cycle_ready
      );

  -----------------------------------------------------------------------------
  -- n_cycle latcher
  -----------------------------------------------------------------------------
  p_n_cycle_latcher : process (ls_clk_i, rst_i) is
  begin  -- process p_n_cycle_latcher
    if rst_i = '1' or s_idle = '1' then  -- asynchronous reset (active high)
      s_n_cycle_new <= (others => '0');
      s_n_cycle_old <= (others => '0');
    elsif rising_edge(ls_clk_i) then     -- rising clock edge
      if s_n_cycle_ready = '1' then
        s_n_cycle_new <= s_n_cycle;
        s_n_cycle_old <= s_n_cycle_new;
      end if;
    end if;
  end process p_n_cycle_latcher;

  u_n_cycle_new <= signed(s_n_cycle_new);
  u_n_cycle_old <= signed(s_n_cycle_old);

  sgn_n_cycle_diff <= u_n_cycle_new - u_n_cycle_old;

  -----------------------------------------------------------------------------
  -- Counter
  -----------------------------------------------------------------------------
  i_abs_n_cycle_diff <= to_integer(abs(sgn_n_cycle_diff));

  p_counter : process (ls_clk_i, rst_i) is
  begin  -- process p_counter
    if rst_i = '1' or s_idle = '1' then  -- asynchronous reset (active high)
      sgn_counter <= (others => '0');
    elsif rising_edge(ls_clk_i) then     -- rising clock edge
      if s_n_cycle_ready = '1' and i_abs_n_cycle_diff < 3 then
        sgn_counter <= sgn_counter + sgn_n_cycle_diff;
      end if;
    end if;
  end process p_counter;

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
  -- FSM
  -----------------------------------------------------------------------------
  p_update_state : process (ls_clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' or s_bomb = '1' then  -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(ls_clk_i) then     -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if DMTD_en_i = '1' then
            s_state <= st1_evaluating;
          end if;
        --
        when st1_evaluating =>
          if sgn_counter > g_counter_threshold then
            s_state <= st2a_incr;
          elsif sgn_counter < - g_counter_threshold then
            s_state <= st2b_decr;
          end if;
        --
        when st2a_incr =>
          s_state <= st0_idle;
        --
        when st2b_decr =>
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
      when st1_evaluating =>
        s_fsm_signals.lock <= '1';
      --
      when st2a_incr =>
        s_fsm_signals.lock <= '1';
        s_fsm_signals.incr <= '1';
        s_fsm_signals.en   <= '1';
      --
      when st2b_decr =>
        s_fsm_signals.lock <= '1';
        s_fsm_signals.en   <= '1';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  s_idle <= s_fsm_signals.idle;
  s_lock <= s_fsm_signals.lock;
  s_incr <= s_fsm_signals.incr;
  s_en   <= s_fsm_signals.en;

  change_freq_en_o <= s_en;
  change_freq_o    <= s_incr;


end architecture rtl;

