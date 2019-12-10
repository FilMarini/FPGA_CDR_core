-------------------------------------------------------------------------------
-- Title      : Testbench for design "BBPFD"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : BBPFD_tb.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-09
-- Last update: 2019-12-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-09  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity BBPFD_tb is

end entity BBPFD_tb;

-------------------------------------------------------------------------------

architecture rtl of BBPFD_tb is

  -- component ports
  signal clk_90_i  : std_logic;
  signal clk_180_i : std_logic;
  signal clk_270_i : std_logic;
  signal data_i    : std_logic;
  signal PFD_o     : std_logic;

  -- clock
  signal clk_i : std_logic := '1';

begin  -- architecture rtl

  clk_90_i <= clk_i after 4 ns;
  clk_180_i <= not clk_i;
  clk_270_i <= clk_180_i after 4 ns;

  -- component instantiation
  DUT: entity work.BBPFD
    port map (
      clk_i     => clk_i,
      clk_90_i  => clk_90_i,
      clk_180_i => clk_180_i,
      clk_270_i => clk_270_i,
      data_i    => data_i,
      PFD_o     => PFD_o);

  -- clock generation
  clk_i <= not clk_i after 8 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    data_i <= '0';
    wait for 15 ns;  -- insert signal assignments here
    while true loop
      data_i <= '0';
      wait for 17 ns;
      data_i <= '1';
      wait for 17 ns;
      data_i <= '0';
      wait for 17 ns;
      data_i <= '1';
      wait for 17 ns;
      data_i <= '1';
      wait for 17 ns;
      data_i <= '0';
      wait for 17 ns;
      data_i <= '1';
      wait for 17 ns;
      data_i <= '0';
      wait for 17 ns;
      data_i <= '1';
      wait for 17 ns;
      data_i <= '0';
      wait for 17 ns;
      data_i <= '1';
    end loop;
    wait;
    
  end process WaveGen_Proc;

  

end architecture rtl;

-------------------------------------------------------------------------------

-- configuration BBPFD_tb_rtl_cfg of BBPFD_tb is
--   for rtl
--   end for;
-- end BBPFD_tb_rtl_cfg;

-------------------------------------------------------------------------------
