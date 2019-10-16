-------------------------------------------------------------------------------
-- Title      : Testbench for design "freq_comparator"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : freq_comparator_tb.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-11
-- Last update: 2019-10-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-11  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity freq_comparator_tb is

end entity freq_comparator_tb;

-------------------------------------------------------------------------------

architecture rtl of freq_comparator_tb is

  -- component ports
  signal hs_clk_i             : std_logic := '0';
  signal hs_clk_2_i           : std_logic := '0';
  signal ls_clk_i             : std_logic := '0';
  signal rst_i                : std_logic;
  signal comp_en_i            : std_logic;
  signal comp_counter_ready_o : std_logic;
  signal comp_counter_o       : std_logic_vector(31 downto 0);
  signal comp_counter_ready_2_o : std_logic;
  signal comp_counter_2_o       : std_logic_vector(31 downto 0);

  -- clock

begin  -- architecture rtl

  -- component instantiation
  DUT1: entity work.freq_comparator
    port map (
      hs_clk_i             => hs_clk_i,
      ls_clk_i             => ls_clk_i,
      rst_i                => rst_i,
      comp_en_i            => comp_en_i,
      comp_counter_ready_o => comp_counter_ready_o,
      comp_counter_o       => comp_counter_o
      );

  DUT2: entity work.freq_comparator
    port map (
      hs_clk_i             => hs_clk_2_i,
      ls_clk_i             => ls_clk_i,
      rst_i                => rst_i,
      comp_en_i            => comp_en_i,
      comp_counter_ready_o => comp_counter_ready_2_o,
      comp_counter_o       => comp_counter_2_o
      );

  -- clock generation
  ls_clk_i <= not ls_clk_i after 32500 ps;
  hs_clk_i <= not hs_clk_i after 8000000 fs;
  hs_clk_2_i <= not hs_clk_2_i after 7999900 fs;
  
  -- waveform generation
  WaveGen_Proc: process
  begin
    rst_i <= '1';
    comp_en_i <= '0';   -- insert signal assignments here
    wait for 100 ns;
    rst_i <= '0';
    wait for 100 ns;
    comp_en_i <= '1';
    wait for 200 ns;
    comp_en_i <= '0';
    wait;

  end process WaveGen_Proc;

  

end architecture rtl;

-------------------------------------------------------------------------------

-- configuration freq_comparator_tb_rtl_cfg of freq_comparator_tb is
--   for rtl
--   end for;
-- end freq_comparator_tb_rtl_cfg;

-------------------------------------------------------------------------------
