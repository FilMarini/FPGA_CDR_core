-------------------------------------------------------------------------------
-- Title      : Testbench for design "pfd"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pfd_tb.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : 
-- Created    : 2020-01-17
-- Last update: 2020-01-31
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-17  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity pfd_tb is

end entity pfd_tb;

-------------------------------------------------------------------------------

architecture behav of pfd_tb is

  -- component ports
  signal rst_i         : std_logic;
  signal en_i          : std_logic;
  signal data_i        : std_logic := '1';
  signal locked_o      : std_logic;
  signal shifting_o    : std_logic;
  signal shifting_en_o : std_logic;

  -- clock
  signal clk_i_i   : std_logic := '1';
  signal clk_q_i : std_logic := '1';

begin  -- architecture behav

  -- component instantiation
  DUT : entity work.pfd
    port map (
      clk_i_i         => clk_i_i,
      clk_q_i       => clk_q_i,
      rst_i         => rst_i,
      en_i          => en_i,
      data_i        => data_i,
      locked_o      => locked_o,
      shifting_o    => shifting_o,
      shifting_en_o => shifting_en_o);

  -- clock generation
  clk_i_i  <= not clk_i_i  after 8 ns;
  clk_q_i <= clk_i_i after 4 ns;
  data_i <= not data_i after 15.999 ns;

  -- waveform generation
  WaveGen_Proc : process
  begin
    rst_i <= '1';
    en_i  <= '1';
    wait for 64 ns;
    rst_i <= '0';
    wait;
  end process WaveGen_Proc;



end architecture behav;

-------------------------------------------------------------------------------

-- configuration pfd_tb_behav_cfg of pfd_tb is
--   for behav
--   end for;
-- end pfd_tb_behav_cfg;

-------------------------------------------------------------------------------
