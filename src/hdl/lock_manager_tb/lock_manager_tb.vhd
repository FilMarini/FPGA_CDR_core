-------------------------------------------------------------------------------
-- Title      : Testbench for design "lock_manager"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : lock_manager_tb.vhd
-- Author     : filippo  <filippo@Dell-Precision-3520>
-- Company    : 
-- Created    : 2020-03-07
-- Last update: 2020-03-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-03-07  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity lock_manager_tb is

end entity lock_manager_tb;

-------------------------------------------------------------------------------

architecture behav of lock_manager_tb is

  -- component generics
  constant g_threshold_bit : positive := 5;

  -- component ports
  signal lock_ctrl_i : std_logic := '0';
  signal lock_raw_i  : std_logic;
  signal lock_o      : std_logic;

  -- clock
  signal clk_i : std_logic := '1';

begin  -- architecture behav

  -- component instantiation
  DUT: entity work.lock_manager
    generic map (
      g_threshold_bit => g_threshold_bit)
    port map (
      clk_i       => clk_i,
      lock_ctrl_i => lock_ctrl_i,
      lock_raw_i  => lock_raw_i,
      lock_o      => lock_o);

  -- clock generation
  clk_i <= not clk_i after 10 ns;

  -- lock control
  ctrl_proc: process
  begin  -- process ctrl_proc
    lock_ctrl_i <= '0';
    loop 
      wait for 200 ns;
      lock_ctrl_i <= '1';
      wait for 20 ns;
      lock_ctrl_i <='0';
    end loop;
  end process ctrl_proc;

  -- waveform generation
  WaveGen_Proc: process
  begin
    lock_raw_i <= '0';-- insert signal assignments here
    wait for 200 ns;
    lock_raw_i <= '1';
    wait;
  end process WaveGen_Proc;

  

end architecture behav;

-------------------------------------------------------------------------------

configuration lock_manager_tb_behav_cfg of lock_manager_tb is
  for behav
  end for;
end lock_manager_tb_behav_cfg;

-------------------------------------------------------------------------------
