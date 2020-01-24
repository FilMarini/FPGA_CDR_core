-------------------------------------------------------------------------------
-- Title      : top_level for dummy hardware
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_level.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-04
-- Last update: 2020-01-24
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-04  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VComponents.all;
use work.PRBSpack.all;

entity top_level is
  port (
    clk_i   : in  std_logic;
    led_o   : out std_logic;
    led1_o  : out std_logic;
    coax_o  : out std_logic;
    coax1_o : out std_logic
    );
end entity top_level;

architecture rtl of top_level is

  signal s_clk    : std_logic;
  signal s_locked : std_logic;
  signal s_prbs   : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Clk Manager
  -----------------------------------------------------------------------------
  clk_wiz_1 : entity work.clk_wiz
    generic map (
      g_bandwidth => "LOW"
      )
    port map (
      clk_in     => clk_i,             -- 125 MHz
      reset      => '0',
      clk_out0   => s_clk,              -- 62.5 MHz
      clk_out1   => open,
      clk_out2   => open,
      clk_out3   => open,
      clk_out4   => open,
      locked     => s_locked,
      psen_p     => '0',
      psincdec_p => '0',
      psdone_p   => open
      );

  -----------------------------------------------------------------------------
  -- PRBS Generator
  -----------------------------------------------------------------------------
  I_PRBS_ANY_GEN : entity work.PRBS_ANY
    generic map(
      CHK_MODE    => false,
      INV_PATTERN => false,
      POLY_LENGHT => 9,
      POLY_TAP    => 5,
      NBITS       => 1
      )
    port map(
      RST         => '0',               --s_rst_prbs,
      CLK         => s_clk,
      DATA_IN(0)  => '0',               --inject err
      EN          => s_locked,
      DATA_OUT(0) => s_prbs
      );

  -----------------------------------------------------------------------------
  -- Heart Beat
  -----------------------------------------------------------------------------
  i_slow_clock_pulse_1 : entity work.slow_clock_pulse
    generic map (
      ref_clk_period_ns      => 16,
      output_pulse_period_ms => 1000,
      n_pulse_up             => 31_250_000
      )
    port map (
      ref_clk   => s_clk,
      pulse_out => led1_o
      );

  -----------------------------------------------------------------------------
  -- Output Control
  -----------------------------------------------------------------------------
  i_OBUF : OBUF
    port map (
      I => s_prbs,
      O => coax_o
      );

  i_OBUF_1 : OBUF
    port map (
      I => s_prbs,
      O => coax1_o
      );

  led_o <= s_locked;


end architecture rtl;
