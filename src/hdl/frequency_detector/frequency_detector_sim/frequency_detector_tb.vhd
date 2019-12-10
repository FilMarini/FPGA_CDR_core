-------------------------------------------------------------------------------
-- Title      : Testbench for design "frequency_detector"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : frequency_detector_tb.vhd
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
-- 2019-12-09  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity frequency_detector_tb is

end entity frequency_detector_tb;

-------------------------------------------------------------------------------

architecture behav of frequency_detector_tb is

  -- component generics
  constant g_threshold : positive := 8;

  -- component ports
  signal rst_i            : std_logic;
  signal DMTD_en_i        : std_logic;
  signal DMTD_locked_o    : std_logic;
  signal incr_freq_o      : std_logic;
  signal change_freq_en_o : std_logic;

  -- clock
  signal ls_clk_i     : std_logic := '1';
  signal data_i       : std_logic := '1';
  signal hs_var_clk_i : std_logic := '1';

begin  -- architecture behav

  -- component instantiation
  DUT : entity work.frequency_detector
    generic map (
      g_threshold => g_threshold)
    port map (
      ls_clk_i         => ls_clk_i,
      data_i           => data_i,
      hs_var_clk_i     => hs_var_clk_i,
      rst_i            => rst_i,
      DMTD_en_i        => DMTD_en_i,
      DMTD_locked_o    => DMTD_locked_o,
      incr_freq_o      => incr_freq_o,
      change_freq_en_o => change_freq_en_o);

  -- clock generation
  ls_clk_i     <= not ls_clk_i     after 16.2 ns;
  data_i       <= not data_i       after 16.001 ns;
  hs_var_clk_i <= not hs_var_clk_i after 8 ns;

  -- waveform generation
  WaveGen_Proc : process
  begin
    rst_i     <= '1';
    DMTD_en_i <= '0';
    wait for 50 ns;
    rst_i     <= '0';
    wait for 50 ns;
    DMTD_en_i <= '1';
    wait;
  end process WaveGen_Proc;



end architecture behav;

-------------------------------------------------------------------------------

-- configuration frequency_detector_tb_behav_cfg of frequency_detector_tb is
--   for behav
--   end for;
-- end frequency_detector_tb_behav_cfg;

-------------------------------------------------------------------------------
