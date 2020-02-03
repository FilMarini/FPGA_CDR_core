-------------------------------------------------------------------------------
-- Title      : phase_shift_filter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_shift_filter.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-08-22
-- Last update: 2020-01-30
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-08-22  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity phase_shift_filter is

  generic (
    -- threhsold value to decide if actually early or late
    threshold   : natural := 10;
    -- 2**(g_num_trans) = number of transition before evaluating
    g_num_trans : natural := 8;
    -- mu,ner of clk cycles to strech the output pulses
    g_steps_to_strech : natural := 3
    );
  port (
    sys_clk        : in  std_logic;
    rst_i          : in  std_logic;
    en_i           : in  std_logic;
    phase_up_raw   : in  std_logic;
    phase_down_raw : in  std_logic;
    phase_up       : out std_logic;
    phase_down     : out std_logic
   --debug
   -- time_counter   : out std_logic_vector(31 downto 0);
   -- phase_counter  : out std_logic_vector(31 downto 0)
    );
end entity phase_shift_filter;

architecture rtl of phase_shift_filter is

  type t_filter_state is (st0_idle,
                          st1_counting,
                          st2_evaluating
                          );

  signal s_state              : t_filter_state;
  signal u_time_counter       : unsigned(31 downto 0)         := (others => '0');
  signal sgd_phase_counter    : signed(31 downto 0)           := (others => '0');
  signal s_time_counter       : std_logic_vector(31 downto 0) := (others => '0');
  signal s_time_count         : std_logic;
  signal phase_up_synch       : std_logic_vector(1 downto 0);
  signal phase_down_synch     : std_logic_vector(1 downto 0);
  signal phase_counter        : std_logic_vector(31 downto 0);
  signal s_transition_occured : std_logic;
  signal s_phase_vector       : std_logic_vector(1 downto 0);
  signal s_phase_up           : std_logic;
  signal s_phase_down         : std_logic;

  -- attribute mark_debug : string;
  -- attribute mark_debug of s_time_counter : signal is "true";
  -- attribute mark_debug of phase_counter : signal is "true";

begin  -- architecture rtl

  synchronizer : process (sys_clk) is
  begin  -- process synchronizer
    if rising_edge(sys_clk) then        -- rising clock edge
      phase_up_synch   <= phase_up_synch(0) & phase_up_raw;
      phase_down_synch <= phase_down_synch(0) & phase_down_raw;
    end if;
  end process synchronizer;

  state_proc : process (sys_clk) is
  begin  -- process state_proc
    if rising_edge(sys_clk) then        -- rising clock edge
      if en_i = '0' then
        s_state <= st0_idle;
      else
        case s_state is

          when st0_idle =>
            s_phase_up        <= '0';
            s_phase_down      <= '0';
            sgd_phase_counter <= (others => '0');
            s_time_count      <= '0';
            s_state           <= st1_counting;

          when st1_counting =>
            s_phase_up   <= '0';
            s_phase_down <= '0';
            s_time_count <= '1';
            if s_time_counter(g_num_trans) = '0' then
              if phase_up_synch(1) = '1' and phase_down_synch(1) = '0' then
                sgd_phase_counter <= sgd_phase_counter + 1;
              elsif phase_up_synch(1) = '0' and phase_down_synch(1) = '1' then
                sgd_phase_counter <= sgd_phase_counter - 1;
              end if;
            else
              s_state <= st2_evaluating;
            end if;

          when st2_evaluating =>
            s_time_count <= '0';
            if sgd_phase_counter < (- threshold) then
              s_phase_down <= '1';
              s_phase_up   <= '0';
            elsif sgd_phase_counter > threshold then
              s_phase_up   <= '1';
              s_phase_down <= '0';
            else
              s_phase_up   <= '0';
              s_phase_down <= '0';
            end if;
            s_state <= st0_idle;

          when others => null;
        end case;
      end if;
    end if;
  end process state_proc;

  s_phase_vector       <= phase_up_raw & phase_down_raw;
  s_transition_occured <= or_reduce(s_phase_vector);

  p_timeout_counter : process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      if s_time_count = '0' then
        u_time_counter <= (others => '0');
      else
        if s_transition_occured = '1' then
          u_time_counter <= u_time_counter + 1;
        end if;
      end if;
    end if;
  end process p_timeout_counter;
  s_time_counter <= std_logic_vector(u_time_counter);

  -- time_counter <= s_time_counter;
  phase_counter <= std_logic_vector(sgd_phase_counter);

  phase_up <= s_phase_up;
  phase_down <= s_phase_down;
  -- pulse stretcher
  -- pulse_stretcher_1 : entity work.pulse_stretcher
  --   generic map (
  --     g_num_of_steps => g_steps_to_strech
  --     )
  --   port map (
  --     clk_i => sys_clk,
  --     rst_i => rst_i,
  --     d_i   => s_phase_up,
  --     q_o   => phase_up
  --     );

  -- pulse_stretcher_2 : entity work.pulse_stretcher
  --   generic map (
  --     g_num_of_steps => g_steps_to_strech
  --     )
  --   port map (
  --     clk_i => sys_clk,
  --     rst_i => rst_i,
  --     d_i   => s_phase_down,
  --     q_o   => phase_down
  --     );

end architecture rtl;
