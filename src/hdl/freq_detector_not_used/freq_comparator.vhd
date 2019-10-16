-------------------------------------------------------------------------------
-- Title      : frequency comparator
-- Project    : 
-------------------------------------------------------------------------------
-- File       : freq_comparator.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-10
-- Last update: 2019-10-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Compare two clock frequencies 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-10  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_comparator is
  port (
    hs_clk_i             : in  std_logic;
    ls_clk_i             : in  std_logic;
    rst_i                : in  std_logic;
    comp_en_i            : in  std_logic;
    comp_counter_ready_o : out std_logic;
    comp_counter_o       : out std_logic_vector(31 downto 0)
    );
end entity freq_comparator;

architecture rtl of freq_comparator is

  type t_state is (st0_idle,
                   st1_set,
                   st2_up,
                   st3_down,
                   st4_evaluate
                   );

  type t_fsm_signals is record
    lock     : std_logic;
    up       : std_logic;
    down     : std_logic;
    evaluate : std_logic;
  end record t_fsm_signals;

  signal s_state                : t_state;
  signal s_fsm_signals          : t_fsm_signals;
  signal s_hs_toggle            : std_logic := '0';
  signal s_comp_en_re           : std_logic;
  signal s_go                   : std_logic;
  signal u_bomb                 : unsigned(31 downto 0);
  signal s_bomb_count           : std_logic_vector(31 downto 0);
  signal s_bomb                 : std_logic;
  signal s_up_re                : std_logic;
  signal s_down_re              : std_logic;
  signal u_comp_counter         : unsigned(31 downto 0);
  signal s_comp_counter         : std_logic_vector(31 downto 0);
  signal s_comp_counter_latched : std_logic_vector(31 downto 0);
  signal s_evaluate_df          : std_logic;
  signal u_period_counter       : unsigned(15 downto 0);
  signal s_period_counter       : std_logic_vector(15 downto 0);
  signal s_lock                 : std_logic;
  signal s_up                   : std_logic;
  signal s_down                 : std_logic;
  signal s_evaluate             : std_logic;
  signal s_hs_toggle_df         : std_logic;

  constant c_fsm_signals : t_fsm_signals := (
    lock     => '0',
    up       => '0',
    down     => '0',
    evaluate => '0'
    );

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- HS Clock Toggle
  -----------------------------------------------------------------------------
  p_hs_clk_toggle : process (hs_clk_i) is
  begin  -- process p_hs_clk_toggle
    if rising_edge(hs_clk_i) then       -- rising clock edge
      s_hs_toggle <= not s_hs_toggle;
    end if;
  end process p_hs_clk_toggle;

  -----------------------------------------------------------------------------
  -- Get ready to exit idle as soon as toggle goes up (after "comp_en" pulse)
  -----------------------------------------------------------------------------
  i_r_edge_detect_1 : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => comp_en_i,
      sig_o => s_comp_en_re
      );

  i_set_reset_ffd_1 : entity work.set_reset_ffd
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i   => ls_clk_i,
      set_i   => s_comp_en_re,
      reset_i => s_lock,
      q_o     => s_go
      );

  -----------------------------------------------------------------------------
  -- Timeout
  -----------------------------------------------------------------------------
  p_bomb_count : process(ls_clk_i)
  begin
    if rising_edge(ls_clk_i) then
      if s_go = '1' then
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
  -- Comparator counter
  -----------------------------------------------------------------------------
  r_edge_detect_up : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => s_up,
      sig_o => s_up_re
      );

  r_edge_detect_down : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => s_down,
      sig_o => s_down_re
      );

  p_comp_counter : process (ls_clk_i, rst_i) is
  begin  -- process p_comp_counter
    if rst_i = '1' or s_go = '1' then   -- asynchronous reset (active high)
      u_comp_counter <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      if s_up = '1' or s_down = '1' then
        u_comp_counter <= u_comp_counter + 1;
      end if;
    end if;
  end process p_comp_counter;

  s_comp_counter <= std_logic_vector(u_comp_counter - 3);

  p_comp_counter_latcher : process (ls_clk_i, rst_i) is
  begin  -- process p_comp_counter_latcher
    if rst_i = '1' or s_go = '1' then   -- asynchronous reset (active high)
      s_comp_counter_latched <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      if s_evaluate = '1' then
        s_comp_counter_latched <= s_comp_counter;
      end if;
    end if;
  end process p_comp_counter_latcher;

  comp_counter_o <= s_comp_counter_latched;

  i_double_flop_evaluation_ready : entity work.double_flop
    generic map (
      g_width    => 1,
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i(0) => s_evaluate,
      sig_o(0) => s_evaluate_df
      );

  comp_counter_ready_o <= s_evaluate_df;

  -----------------------------------------------------------------------------
  -- Period counter
  -----------------------------------------------------------------------------
  p_period_counter : process (ls_clk_i, rst_i) is
  begin  -- process p_period_counter
    if rst_i = '1' or s_go = '1' then   -- asynchronous reset (active high)
      u_period_counter <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      if s_up_re = '1' or s_down_re = '1' then
        u_period_counter <= u_period_counter + 1;
      end if;
    end if;
  end process p_period_counter;

  s_period_counter <= std_logic_vector(u_period_counter);

  -----------------------------------------------------------------------------
  -- Avoid metastability
  -----------------------------------------------------------------------------
  i_double_flop_ls_sampling : entity work.double_flop
    generic map (
      g_width    => 1,
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i(0) => s_hs_toggle,
      sig_o(0) => s_hs_toggle_df
      );

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
          if s_go = '1' and s_hs_toggle_df = '0' then
            s_state <= st1_set;
          end if;
        --
        when st1_set =>
          if s_hs_toggle_df = '1' then
            s_state <= st2_up;
          end if;
        --
        when st2_up =>
          if s_period_counter = x"FFFF" then
            s_state <= st4_evaluate;
          elsif s_hs_toggle_df = '0' then
            s_state <= st3_down;
          end if;
        --
        when st3_down =>
          if s_period_counter = x"FFFF" then
            s_state <= st4_evaluate;
          elsif s_hs_toggle_df = '1' then
            s_state <= st2_up;
          end if;
        --
        when st4_evaluate =>
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
        null;
      --
      when st1_set =>
        s_fsm_signals.lock <= '1';
      --
      when st2_up =>
        s_fsm_signals.lock <= '1';
        s_fsm_signals.up   <= '1';
      --
      when st3_down =>
        s_fsm_signals.lock <= '1';
        s_fsm_signals.down <= '1';
      --
      when st4_evaluate =>
        s_fsm_signals.lock     <= '1';
        s_fsm_signals.evaluate <= '1';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  s_lock     <= s_fsm_signals.lock;
  s_up       <= s_fsm_signals.up;
  s_down     <= s_fsm_signals.down;
  s_evaluate <= s_fsm_signals.evaluate;

end architecture rtl;
