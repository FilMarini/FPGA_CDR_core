-------------------------------------------------------------------------------
-- Title      : Testbench for design "top_cdr"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_cdr_tb.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-02
-- Last update: 2019-10-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-02  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity top_cdr_tb is

end entity top_cdr_tb;

-------------------------------------------------------------------------------

architecture rtl of top_cdr_tb is

  -- component ports
  signal sysclk_i : std_logic := '0';
  signal cdrclk_o : std_logic;
  signal M_i : std_logic_vector(31 downto 0);


  -- clock
  
begin  -- architecture rtl

  -- component instantiation
  DUT: entity work.top_cdr
    port map (
      sysclk_i => sysclk_i,
      M_i      => M_i,
      cdrclk_o => cdrclk_o);

  -- clock generation
  sysclk_i <= not sysclk_i after 4 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    -- insert signal assignments here
  M_i <= x"30000000";   
  wait; 
    
  end process WaveGen_Proc;

  

end architecture rtl;

-------------------------------------------------------------------------------

-- configuration top_cdr_tb_rtl_cfg of top_cdr_tb is
--   for rtl
--   end for;
-- end top_cdr_tb_rtl_cfg;

-------------------------------------------------------------------------------
