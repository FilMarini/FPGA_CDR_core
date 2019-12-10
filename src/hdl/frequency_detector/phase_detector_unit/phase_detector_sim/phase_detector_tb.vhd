-------------------------------------------------------------------------------
-- Title      : Testbench for design "phase_detector"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_detector_tb.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-10
-- Last update: 2019-12-10
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-10  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity phase_detector_tb is

end entity phase_detector_tb;

-------------------------------------------------------------------------------

architecture behav of phase_detector_tb is

  -- component ports
  signal data_in : std_logic;
  signal x       : std_logic;
  signal y       : std_logic;

  -- clock
  signal sys_clk : std_logic := '1';

begin  -- architecture behav

  -- component instantiation
  DUT: entity work.phase_detector
    port map (
      data_in => data_in,
      sys_clk => sys_clk,
      x       => x,
      y       => y);

  -- clock generation
  sys_clk <= not sys_clk after 10 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    wait for 21 ns;
   while true loop
     data_in <= '1';
     wait for 20 ns;
     data_in <= '1';
     wait for 20 ns;
     data_in <= '1';
     wait for 20 ns;
     data_in <= '1';
     wait for 20 ns;
     data_in <= '0';
     wait for 20 ns;
     data_in <= '0';
     wait for 20 ns;
     data_in <= '0';
     wait for 20 ns;
     data_in <= '1';
     wait for 20 ns;
     data_in <= '1';
     wait for 20 ns;
     data_in <= '1';
     wait for 20 ns;
     data_in <= '1';
     wait for 20 ns;

    end loop; -- insert signal assignments here
    wait;
  end process WaveGen_Proc;

  

end architecture behav;

-------------------------------------------------------------------------------

configuration phase_detector_tb_behav_cfg of phase_detector_tb is
  for behav
  end for;
end phase_detector_tb_behav_cfg;

-------------------------------------------------------------------------------
