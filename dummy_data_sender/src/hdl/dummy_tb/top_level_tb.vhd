-------------------------------------------------------------------------------
-- Title      : Testbench for design "top_level"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_level_tb.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : 
-- Created    : 2020-01-24
-- Last update: 2020-01-24
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-24  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity top_level_tb is

end entity top_level_tb;

-------------------------------------------------------------------------------

architecture behav of top_level_tb is

  -- component ports
  signal led_o   : std_logic;
  signal led1_o  : std_logic;
  signal coax_o  : std_logic;
  signal coax1_o : std_logic;

  -- clock
  signal clk_i : std_logic := '1';

  -- signals
  signal s_errors : std_logic;

begin  -- architecture behav

  -- component instantiation
  DUT: entity work.top_level
    port map (
      clk_i   => clk_i,
      led_o   => led_o,
      led1_o  => led1_o,
      coax_o  => coax_o,
      coax1_o => coax1_o
      );

  -- clock generation
  clk_i <= not clk_i after 4 ns;

  PRBS_ANY_1: entity work.PRBS_ANY
    generic map (
      CHK_MODE    => true,
      INV_PATTERN => false,
      POLY_LENGHT => 9,
      POLY_TAP    => 5,
      NBITS       => 1
      )
    port map (
      RST      => '0',
      CLK      => clk_i,
      DATA_IN(0)  => coax_o,
      EN       => '1',
      DATA_OUT(0) => s_errors
      );

  -- waveform generation


end architecture behav;

-------------------------------------------------------------------------------

-- configuration top_level_tb_behav_cfg of top_level_tb is
--   for behav
--   end for;
-- end top_level_tb_behav_cfg;

-------------------------------------------------------------------------------
