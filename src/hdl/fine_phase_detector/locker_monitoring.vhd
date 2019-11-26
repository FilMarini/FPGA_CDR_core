-------------------------------------------------------------------------------
-- Title      : locker monitoring
-- Project    : 
-------------------------------------------------------------------------------
-- File       : locker_monitoring.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-11-26
-- Last update: 2019-11-26
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
    slocked_o           : out std_logic;
    incr_freq_o         : out std_logic;
    change_freq_en_o    : out std_logic
    );
end entity locker_monitoring;

architecture rtl of locker_monitoring is

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- N_cycles max latcher
  -----------------------------------------------------------------------------
  p_n_cycle_max_latcher : process (ls_clk_i, rst_i) is
  begin  -- process p_n_cycle_max_latcher
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_n_cycle_max <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      if n_cycle_max_ready_i = '1' then
        s_n_cycle_max <= n_cycle_max_i;
      end if;
    end if;
  end process p_n_cycle_max_latcher;




end architecture rtl;
