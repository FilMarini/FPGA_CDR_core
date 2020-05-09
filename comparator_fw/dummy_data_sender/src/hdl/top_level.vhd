-------------------------------------------------------------------------------
-- Title      : top_level for dummy hardware
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_level.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-04
-- Last update: 2020-05-09
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
    clk_i              : in  std_logic;
    led_o              : out std_logic;
    led1_o             : out std_logic;
    prbs_to_cat5_p_o   : out std_logic;
    prbs_to_cat5_n_o   : out std_logic;
    clk_to_cat5_p_o    : out std_logic;
    clk_to_cat5_n_o    : out std_logic
    );
end entity top_level;

architecture rtl of top_level is

  signal s_clk            : std_logic;
  signal s_locked         : std_logic;
  signal s_clean_prbs     : std_logic;
  signal s_prbs_to_cat5   : std_logic;
  signal s_prbs_from_cat5 : std_logic;
  signal s_prbs_to_cdr    : std_logic;
  signal s_prbs_rst       : std_logic;
  signal s_prbs_clk : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Clk Manager
  -----------------------------------------------------------------------------
  clk_wiz_1 : entity work.clk_wiz
    generic map (
      g_bandwidth => "LOW"
      )
    port map (
      clk_in     => clk_i,              -- 125 MHz
      reset      => '0',
      clk_out0   => open,               -- 31.125 MHz
      clk_out1   => s_clk,              -- 250 MHz
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
  s_prbs_rst <= not s_locked;

  I_PRBS_ANY_GEN : entity work.PRBS_ANY
    generic map(
      CHK_MODE    => false,
      INV_PATTERN => true,
      POLY_LENGHT => 7,
      POLY_TAP    => 6,
      NBITS       => 1
      )
    port map(
      RST         => s_prbs_rst,        --s_rst_prbs,
      CLK         => s_clk,
      DATA_IN(0)  => '0',               --inject err
      EN          => s_locked,
      DATA_OUT(0) => s_clean_prbs
      );

  -----------------------------------------------------------------------------
  -- Clock forwarding
  -----------------------------------------------------------------------------
    ODDR_inst : ODDR
      generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
        INIT         => '0',  -- Initial value for Q port ('1' or '0')
        SRTYPE       => "SYNC")         -- Reset Type ("ASYNC" or "SYNC")
      port map (
        Q  => s_prbs_clk,          -- 1-bit DDR output
        C  => s_clk,                -- 1-bit clock input
        CE => '1',              -- 1-bit clock enable input
        D1 => '1',                      -- 1-bit data input (positive edge)
        D2 => '0',                      -- 1-bit data input (negative edge)
        R  => s_prbs_rst,             -- 1-bit reset input
        S  => '0'                       -- 1-bit set input
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
  -- Output Control to CAT5E (if present)
  -----------------------------------------------------------------------------
  s_prbs_to_cat5 <= s_clean_prbs;
  
  i_OBUFDS_to_cat5 : OBUFDS
    generic map (
      IOSTANDARD => "DEFAULT",          -- Specify the output I/O standard
      SLEW       => "SLOW")
    port map (
      I  => s_prbs_to_cat5,
      O  => prbs_to_cat5_p_o,
      OB => prbs_to_cat5_n_o
      );

  i_OBUFDS_clk_to_cat5 : OBUFDS
    generic map (
      IOSTANDARD => "DEFAULT",          -- Specify the output I/O standard
      SLEW       => "SLOW")
    port map (
      I  => s_prbs_clk,
      O  => clk_to_cat5_p_o,
      OB => clk_to_cat5_n_o
      );

  -----------------------------------------------------------------------------
  -- Output Control to CDR
  -----------------------------------------------------------------------------
  led_o <= s_locked;


end architecture rtl;
