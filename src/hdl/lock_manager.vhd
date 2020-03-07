-------------------------------------------------------------------------------
-- Title      : lock manager
-- Project    : 
-------------------------------------------------------------------------------
-- File       : lock_manager.vhd
-- Author     : filippo  <filippo@Dell-Precision-3520>
-- Company    : 
-- Created    : 2020-03-07
-- Last update: 2020-03-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Essentially the lock has to be stable (for either locked on
-- unlocked state) for a number of times before changing its state 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-03-07  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lock_manager is
  generic (
    g_threshold_bit : positive := 5
    );
  port (
    clk_i       : in  std_logic;
    lock_ctrl_i : in  std_logic;
    lock_raw_i  : in  std_logic;
    lock_o      : out std_logic
    );
end entity lock_manager;

architecture rtl of lock_manager is

  signal s_lock_raw_re  : std_logic;
  signal s_lock_raw_fe  : std_logic;
  signal u_up_counter   : unsigned(15 downto 0);
  signal s_up_counter   : std_logic_vector(15 downto 0);
  signal u_down_counter : unsigned(15 downto 0);
  signal s_down_counter : std_logic_vector(15 downto 0);

  alias s_up_stop   : std_logic is s_up_counter(g_threshold_bit + 1);
  alias s_up_set    : std_logic is s_up_counter(g_threshold_bit);
  alias s_down_stop : std_logic is s_down_counter(g_threshold_bit + 1);
  alias s_down_set  : std_logic is s_down_counter(g_threshold_bit);

begin  -- architecture rtl

-------------------------------------------------------------------------------
-- Lock status change detector
-------------------------------------------------------------------------------
  r_edge_detect_1 : entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => clk_i,
      sig_i => lock_raw_i,
      sig_o => s_lock_raw_re
      );

  f_edge_detect_1 : entity work.f_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => clk_i,
      sig_i => lock_raw_i,
      sig_o => s_lock_raw_fe
      );

  -----------------------------------------------------------------------------
  -- Up and Down counters
  -----------------------------------------------------------------------------
  p_up_counter : process (clk_i, s_lock_raw_re) is
  begin  -- process p_up_counter
    if rising_edge(clk_i) then          -- rising clock edge
      if s_lock_raw_re = '1' then
        u_up_counter <= (others => '0');
      else
        if lock_raw_i = '1' and s_up_stop = '0' and lock_ctrl_i = '1' then
          u_up_counter <= u_up_counter + 1;
        end if;
      end if;
    end if;
  end process p_up_counter;

  s_up_counter <= std_logic_vector(u_up_counter);

  p_down_counter : process (clk_i, s_lock_raw_fe) is
  begin  -- process p_down_counter
    if rising_edge(clk_i) then          -- rising clock edge
      if s_lock_raw_re = '1' then
        u_down_counter <= (others => '0');
      else
        if lock_raw_i = '0' and s_down_stop = '0' and lock_ctrl_i = '1' then
          u_down_counter <= u_down_counter + 1;
        end if;
      end if;
    end if;
  end process p_down_counter;

  s_down_counter <= std_logic_vector(u_down_counter);

  -----------------------------------------------------------------------------
  -- SRFF for lock and unlock
  -----------------------------------------------------------------------------
  set_reset_ffd_1: entity work.set_reset_ffd
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i   => clk_i,
      set_i   => s_up_set,
      reset_i => s_down_set,
      q_o     => lock_o
      );


end architecture rtl;
