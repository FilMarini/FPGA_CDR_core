-------------------------------------------------------------------------------
-- Title      : Testbench for design "DMTD"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : DMTD_tb.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-16
-- Last update: 2019-10-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-16  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity DMTD_tb is

end entity DMTD_tb;

-------------------------------------------------------------------------------

architecture rtl of DMTD_tb is

  -- component ports
  signal ls_clk_i         : std_logic := '0';
  signal hs_fixed_clk_i   : std_logic := '0';
  signal hs_var_clk_i     : std_logic := '0';
  signal rst_i            : std_logic;
  signal change_freq_o    : std_logic;
  signal change_freq_en_o : std_logic;
  signal clk_veloce : std_logic := '0';
  signal clk_lento : std_logic := '0';
  signal ps_clk : std_logic := '0';
  signal chg_clk : std_logic;



begin  -- architecture rtl

  -- component instantiation
  DUT : entity work.DMTD
    port map (
      ls_clk_i         => ls_clk_i,
      hs_fixed_clk_i   => hs_fixed_clk_i,
      hs_var_clk_i     => hs_var_clk_i,
      rst_i            => rst_i,
      change_freq_o    => change_freq_o,
      change_freq_en_o => change_freq_en_o);

  -- clock generation
  ls_clk_i       <= not ls_clk_i       after 16400 ps;
  hs_fixed_clk_i <= not hs_fixed_clk_i after 8000 ps;
  clk_veloce   <= not clk_veloce   after 7999 ps;
  clk_lento <= not clk_lento after 8001 ps;

  ps_clk <= not ps_clk after 1 ps;

  clk_process: process (ps_clk) is
  begin  -- process clk_process
    if rising_edge(ps_clk) then      -- rising clock edge
      if chg_clk = '0' then
        hs_var_clk_i <= clk_lento;
        else
          hs_var_clk_i <= clk_veloce;
      end if;
    end if;
  end process clk_process;



  -- waveform generation
  WaveGen_Proc : process
  begin
    rst_i <= '1';
    chg_clk <= '0';
    wait for 50 ns;
    rst_i <= '0';
    wait for 50000 ns;
    chg_clk <= '1';
    wait for 70000 ns;
    chg_clk <= '0';
    wait;


  end process WaveGen_Proc;



end architecture rtl;

-------------------------------------------------------------------------------

-- configuration DMTD_tb_rtl_cfg of DMTD_tb is
--   for rtl
--   end for;
-- end DMTD_tb_rtl_cfg;

-------------------------------------------------------------------------------
