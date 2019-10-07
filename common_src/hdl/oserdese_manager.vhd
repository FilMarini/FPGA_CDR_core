-------------------------------------------------------------------------------
-- Title      : oserdese amanger
-- Project    : 
-------------------------------------------------------------------------------
-- File       : oserdese_manager.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-07
-- Last update: 2019-10-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-07  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity oserdese_manager is
  port (
    ls_clk_i      : in  std_logic;
    hs_clk_i      : in  std_logic;
    deser_clk_i   : in  std_logic_vector(7 downto 0);
    mmcm_locked_i : in  std_logic;
    ser_clk_o     : out std_logic
    );
end entity oserdese_manager;

architecture rtl of oserdese_manager is

begin  -- architecture rtl

    OSERDESE2_inst : OSERDESE2
    generic map (
      DATA_RATE_OQ   => "DDR",          -- DDR, SDR
      DATA_RATE_TQ   => "DDR",          -- DDR, BUF, SDR
      DATA_WIDTH     => 8,              -- Parallel data width (2-8,10,14)
      INIT_OQ        => '0',  -- Initial value of OQ output (1'b0,1'b1)
      INIT_TQ        => '0',  -- Initial value of TQ output (1'b0,1'b1)
      SERDES_MODE    => "MASTER",       -- MASTER, SLAVE
      SRVAL_OQ       => '0',  -- OQ output value when SR is used (1'b0,1'b1)
      SRVAL_TQ       => '0',  -- TQ output value when SR is used (1'b0,1'b1)
      TBYTE_CTL      => "FALSE",  -- Enable tristate byte operation (FALSE, TRUE)
      TBYTE_SRC      => "FALSE",        -- Tristate byte source (FALSE, TRUE)
      TRISTATE_WIDTH => 1               -- 3-state converter width (1,4)
      )
    port map (
      OFB       => open,                -- 1-bit output: Feedback path for data
      OQ        => ser_clk_o,            -- 1-bit output: Data path output
      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
      SHIFTOUT1 => open,
      SHIFTOUT2 => open,
      TBYTEOUT  => open,                -- 1-bit output: Byte group tristate
      TFB       => open,                -- 1-bit output: 3-state control
      TQ        => open,                -- 1-bit output: 3-state control
      CLK       => hs_clk_i,          -- 1-bit input: High speed clock
      CLKDIV    => ls_clk_i,           -- 1-bit input: Divided clock
      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      D1        => deser_clk_i(0),
      D2        => deser_clk_i(1),
      D3        => deser_clk_i(2),
      D4        => deser_clk_i(3),
      D5        => deser_clk_i(4),
      D6        => deser_clk_i(5),
      D7        => deser_clk_i(6),
      D8        => deser_clk_i(7),
      OCE       => '1',       -- 1-bit input: Output data clock enable
      RST       => not mmcm_locked_i,  -- 1-bit input: Reset
      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      SHIFTIN1  => '0',
      SHIFTIN2  => '0',
      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      T1        => '0',
      T2        => '0',
      T3        => '0',
      T4        => '0',
      TBYTEIN   => '0',                 -- 1-bit input: Byte group tristate
      TCE       => '0'                  -- 1-bit input: 3-state clock enable
      );


end architecture rtl;
