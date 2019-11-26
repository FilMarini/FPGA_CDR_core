-------------------------------------------------------------------------------
-- Title      : Testbench for design "DMTD"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : DMTD_tb.vhd
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
-- 2019-11-26  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity DMTD_tb is

end entity DMTD_tb;

-------------------------------------------------------------------------------

architecture tb of DMTD_tb is

  -- component ports
  signal rst_i            : std_logic;
  signal DMTD_en_i        : std_logic;
  signal change_freq_o    : std_logic;
  signal change_freq_en_o : std_logic;

  -- clock
  signal ls_clk_i : std_logic := '1';
  signal hs_fixed_clk_i   : std_logic := '1';
  signal hs_var_clk_i     : std_logic := '1';

begin  -- architecture tb

  -- component instantiation
  DUT: entity work.DMTD
    port map (
      ls_clk_i         => ls_clk_i,
      hs_fixed_clk_i   => hs_fixed_clk_i,
      hs_var_clk_i     => hs_var_clk_i,
      rst_i            => rst_i,
      DMTD_en_i        => DMTD_en_i,
      change_freq_o    => change_freq_o,
      change_freq_en_o => change_freq_en_o);

  -- clock generation
  ls_clk_i <= not ls_clk_i after 16.2 ns;
  hs_fixed_clk_i <= not hs_fixed_clk_i after 8 ns;
  hs_var_clk_i <= not hs_var_clk_i after 7.999 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    rst_i <= '1';
    DMTD_en_i <= '0';
    wait for 50 ns;
    rst_i <= '0';
    wait for 50 ns;
    DMTD_en_i <= '1';
    wait;
  end process WaveGen_Proc;

  

end architecture tb;

-------------------------------------------------------------------------------

-- configuration DMTD_tb_tb_cfg of DMTD_tb is
--   for tb
--   end for;
-- end DMTD_tb_tb_cfg;

-------------------------------------------------------------------------------
