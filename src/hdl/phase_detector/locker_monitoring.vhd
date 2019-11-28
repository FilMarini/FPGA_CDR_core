-------------------------------------------------------------------------------
-- Title      : locker monitoring
-- Project    : 
-------------------------------------------------------------------------------
-- File       : locker_monitoring.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-11-26
-- Last update: 2019-11-28
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

entity locker_monitoring is
  generic (
    g_threshold : positive := 8
    );
  port (
    ls_clk_i            : in  std_logic;
    rst_i               : in  std_logic;
    n_cycle_i           : in  std_logic_vector(7 downto 0);
    n_cycle_ready_i     : in  std_logic;
    n_cycle_max_i       : in  std_logic_vector(7 downto 0);
    n_cycle_max_ready_i : in  std_logic;
    locked_i            : in  std_logic;
    slocked_o           : out std_logic;
    incr_freq_o         : out std_logic;
    change_freq_en_o    : out std_logic
    );
end entity locker_monitoring;

architecture rtl of locker_monitoring is

  type t_state is (st0_idle,
                   st1_monitoring,
                   st2a_incr,
                   st2b_decr,
                   st3_slocked
                   );

  type t_fsm_signals is record
    DMTD_slocked : std_logic;
    monitoring   : std_logic;
    incr         : std_logic;
    en           : std_logic;
  end record t_fsm_signals;

  constant c_fsm_signals : t_fsm_signals := (
    DMTD_slocked => '0',
    monitoring   => '0',
    incr         => '0',
    en           => '0'
    );

  signal s_state                 : t_state;
  signal s_fsm_signals           : t_fsm_signals;
  signal s_monitoring            : std_logic;
  signal s_incr_freq             : std_logic;
  signal s_change_freq_en        : std_logic;
  signal s_locked_re             : std_logic;
  signal s_n_cycle_max           : std_logic_vector(7 downto 0);
  signal sgn_n_cycle_max         : signed(7 downto 0);
  signal sgn_n_cycle_opt         : signed(7 downto 0);
  signal s_change_freq_en_re     : std_logic;
  signal s_incr_freq_re          : std_logic;
  signal sgn_n_cycle_fixed       : signed(7 downto 0);
  signal sgn_n_cycle_diff        : signed(7 downto 0);
  signal sgn_phase_shift_counter : signed(7 downto 0);
  signal sgn_phase_shift         : signed(7 downto 0);
  signal sgn_n_cycle             : signed(7 downto 0);
  -- debug
  signal s_n_cycle_ready         : std_logic;

  attribute mark_debug                            : string;
  attribute mark_debug of sgn_n_cycle             : signal is "true";
  attribute mark_debug of sgn_n_cycle_opt         : signal is "true";
  attribute mark_debug of s_n_cycle_ready         : signal is "true";
  attribute mark_debug of sgn_phase_shift_counter : signal is "true";
  attribute mark_debug of sgn_phase_shift         : signal is "true";
  attribute mark_debug of sgn_n_cycle_fixed       : signal is "true";
  attribute mark_debug of sgn_n_cycle_diff        : signal is "true";
  attribute mark_debug of s_state                 : signal is "true";
  attribute mark_debug of s_change_freq_en        : signal is "true";
  attribute mark_debug of s_incr_freq             : signal is "true";



begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- debug
  -----------------------------------------------------------------------------
  s_n_cycle_ready <= n_cycle_ready_i;

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

  sgn_n_cycle_max <= signed(s_n_cycle_max);
  sgn_n_cycle_opt <= shift_right(sgn_n_cycle_max, 1);
  sgn_n_cycle     <= signed(n_cycle_i);

  -----------------------------------------------------------------------------
  -- What is the n_cycle(_fixed) value now?
  -----------------------------------------------------------------------------
  i_edge_detect_1 : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => locked_i,
      sig_o => s_locked_re
      );

  i_edge_detect_2 : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => s_change_freq_en,
      sig_o => s_change_freq_en_re
      );

  i_edge_detect_3 : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i => s_incr_freq,
      sig_o => s_incr_freq_re
      );

  p_fix_n_cycle : process (ls_clk_i) is
  begin  -- process p_fix_n_cycle
    if rising_edge(ls_clk_i) then       -- rising clock edge
      if s_locked_re = '1' then
        sgn_n_cycle_fixed <= sgn_n_cycle_opt;
      elsif s_change_freq_en_re = '1' then
        case s_incr_freq_re is
          when '0' =>
            sgn_n_cycle_fixed <= sgn_n_cycle_fixed - 1;
          when '1' =>
            sgn_n_cycle_fixed <= sgn_n_cycle_fixed + 1;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process p_fix_n_cycle;

  sgn_n_cycle_diff <= sgn_n_cycle_fixed - sgn_n_cycle_opt;

  -----------------------------------------------------------------------------
  -- Low pass filter (counter) to determine the phase shift
  -- [the "if sgn_phase_shift = 0 is needed to count only consecutive phase
  -- shift, otherwise, when you are at the edge (in the beginning you are at
  -- the edge of 0 and -1) some bad behaviour happens"]
  -----------------------------------------------------------------------------
  p_phase_shift_counter : process (ls_clk_i) is
  begin  -- process p_phase_shift_counter
    if rising_edge(ls_clk_i) then       -- rising clock edge
      if s_monitoring = '0' then
        sgn_phase_shift_counter <= (others => '0');
      elsif n_cycle_ready_i = '1' then
        sgn_phase_shift <= sgn_n_cycle - sgn_n_cycle_fixed;
        if sgn_phase_shift = 0 then
          sgn_phase_shift_counter <= (others => '0');
        else
          sgn_phase_shift_counter <= sgn_phase_shift_counter + sgn_phase_shift;
        end if;
      end if;
    end if;
  end process p_phase_shift_counter;

  -----------------------------------------------------------------------------
  -- FSM [ "-3" is used cause sgn_n_cycle_diff can not be > sgn_n_cycle_opt
  -- (and to be 100% sure of the behaviour) ]
  -----------------------------------------------------------------------------
  p_update_state : process (ls_clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if locked_i = '1' then
            s_state <= st1_monitoring;
          end if;
        --
        when st1_monitoring =>
          if sgn_phase_shift_counter > g_threshold then
            s_state <= st2a_incr;
          elsif sgn_phase_shift_counter < - g_threshold then
            s_state <= st2b_decr;
          end if;
        --
        when st2a_incr =>
          if n_cycle_ready_i = '1' then
            if (abs(sgn_n_cycle_diff) > sgn_n_cycle_opt - 3) or (abs(sgn_n_cycle - sgn_n_cycle_fixed) > 3) then
              s_state <= st3_slocked;
            else
              s_state <= st1_monitoring;
            end if;
          end if;
        --
        when st2b_decr =>
          if n_cycle_ready_i = '1' then
            if abs(sgn_n_cycle_diff) > sgn_n_cycle_opt - 3 or (abs(sgn_n_cycle - sgn_n_cycle_fixed) > 3) then
              s_state <= st3_slocked;
            else
              s_state <= st1_monitoring;
            end if;
          end if;
        --
        when st3_slocked =>
          s_state <= st0_idle;
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
      when st1_monitoring =>
        s_fsm_signals.monitoring <= '1';
      --
      when st2a_incr =>
        s_fsm_signals.en   <= '1';
        s_fsm_signals.incr <= '1';
      --
      when st2b_decr =>
        s_fsm_signals.en <= '1';
      --
      when st3_slocked =>
        s_fsm_signals.DMTD_slocked <= '1';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  s_monitoring     <= s_fsm_signals.monitoring;
  s_incr_freq      <= s_fsm_signals.incr;
  s_change_freq_en <= s_fsm_signals.en;

  slocked_o        <= s_fsm_signals.DMTD_slocked;
  incr_freq_o      <= s_incr_freq;
  change_freq_en_o <= s_change_freq_en;




end architecture rtl;
