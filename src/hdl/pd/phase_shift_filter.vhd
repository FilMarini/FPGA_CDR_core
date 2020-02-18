-------------------------------------------------------------------------------
-- Title      : phase_shift_filter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_shift_filter.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-08-22
-- Last update: 2020-02-18
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
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity phase_shift_filter is

  generic (
    threshold          : natural := 10;
    bit_num_trans_time : natural := 8
    );
  port (
    sys_clk        : in  std_logic;
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

  signal s_state           : t_filter_state;
  signal u_trans_counter   : unsigned(15 downto 0)         := (others => '0');
  signal sgd_phase_counter : signed(15 downto 0)           := (others => '0');
  signal s_trans_counter   : std_logic_vector(15 downto 0) := (others => '0');
  signal s_time_count      : std_logic;
  signal phase_up_synch    : std_logic_vector(1 downto 0);
  signal phase_down_synch  : std_logic_vector(1 downto 0);
  signal phase_counter     : std_logic_vector(15 downto 0);
  signal s_trans_occured   : std_logic;
  signal u_timeout_counter : unsigned(15 downto 0);
  signal s_timeout_counter : std_logic_vector(15 downto 0);

  alias s_bomb : std_logic is s_timeout_counter(bit_num_trans_time + 2);

  -- attribute mark_debug : string;
  -- attribute mark_debug of s_trans_counter : signal is "true";
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
      case s_state is
        --
        when st0_idle =>
          phase_up          <= '0';
          phase_down        <= '0';
          sgd_phase_counter <= (others => '0');
          s_time_count      <= '0';
          s_state           <= st1_counting;
        --
        when st1_counting =>
          phase_up     <= '0';
          phase_down   <= '0';
          s_time_count <= '1';
          if s_bomb = '1' then
            s_state <= st0_idle;
          else
            if s_trans_counter(bit_num_trans_time) = '0' then
              if phase_up_synch(1) = '1' and phase_down_synch(1) = '0' then
                sgd_phase_counter <= sgd_phase_counter + 1;
              elsif phase_up_synch(1) = '0' and phase_down_synch(1) = '1' then
                sgd_phase_counter <= sgd_phase_counter - 1;
              end if;
            else
              s_state <= st2_evaluating;
            end if;
          end if;
        --
        when st2_evaluating =>
          s_time_count <= '0';
          if sgd_phase_counter < (- threshold) then
            phase_down <= '1';
            phase_up   <= '0';
          elsif sgd_phase_counter > threshold then
            phase_up   <= '1';
            phase_down <= '0';
          else
            phase_up   <= '0';
            phase_down <= '0';
          end if;
          s_state <= st0_idle;
        --
        when others =>
          null;
      --
      end case;
    end if;
  end process state_proc;

  s_trans_occured <= or_reduce(std_logic_vector'(phase_up_synch(1) & phase_down_synch(1)));

  p_trans_counter : process (sys_clk, s_time_count) is
  begin  -- process p_timeout_counter
    if s_time_count = '0' then          -- asynchronous reset (active low)
      u_trans_counter <= (others => '0');
    elsif rising_edge(sys_clk) then     -- rising clock edge
      if s_trans_occured = '1' then
        u_trans_counter <= u_trans_counter + 1;
      end if;
    end if;
  end process p_trans_counter;

  s_trans_counter <= std_logic_vector(u_trans_counter);

  p_timeout_counter : process (sys_clk, s_time_count) is
  begin  -- process p_timeout_counter
    if s_time_count = '0' then                -- asynchronous reset (active low)
      u_timeout_counter <= (others => '0');
    elsif rising_edge(sys_clk) then     -- rising clock edge
      u_timeout_counter <= u_timeout_counter + 1;
    end if;
  end process p_timeout_counter;

  s_timeout_counter <= std_logic_vector(u_timeout_counter);

end architecture rtl;
