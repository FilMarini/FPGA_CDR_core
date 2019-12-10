-------------------------------------------------------------------------------
-- Title      : Bang Bang phase detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : BBPD.vhd
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
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity BBPD is
  port (
    clk_i     : in  std_logic;
    clk_180_i : in  std_logic;
    data_i    : in  std_logic;
    pd_o      : out std_logic
    );
end entity BBPD;

architecture rtl of BBPD is
  
  signal s_Q1 : std_logic;
  signal s_Q2 : std_logic;
  signal s_Q3 : std_logic;
  signal s_Q4 : std_logic;
  signal s_Q3_bar : std_logic;
  signal s_Q1_bar : std_logic;
  signal s_X : std_logic;
  signal s_Y : std_logic;

begin  -- architecture rtl

  i_Q1 : FDRE
    generic map (
      INIT => '0')  -- Initial value of register ('0' or '1')  
    port map (
      Q  => s_Q1,                       -- Data output
      C  => clk_i,                      -- Clock input
      CE => '1',                        -- Clock enable input
      R  => '0',                        -- Synchronous reset input
      D  => data_i                      -- Data input
      );


  i_Q2 : FDRE
    generic map (
      INIT => '0')      -- Initial value of register ('0' or '1')  
    port map (
      Q  => s_Q2,                       -- Data output
      C  => clk_180_i,                  -- Clock input
      CE => '1',                        -- Clock enable input
      R  => '0',                        -- Synchronous reset input
      D  => data_i                      -- Data input
      );

  i_Q3 : FDRE
    generic map (
      INIT => '0')  -- Initial value of register ('0' or '1')  
    port map (
      Q  => s_Q3,                       -- Data output
      C  => s_Q1,                       -- Clock input
      CE => '1',                        -- Clock enable input
      R  => '0',                        -- Synchronous reset input
      D  => s_Q2                        -- Data input
      );

  s_Q3_bar <= not s_Q3;
  s_Q1_bar <= not s_Q1;

  i_Q4 : FDRE
    generic map (
      INIT => '0')     -- Initial value of register ('0' or '1')  
    port map (
      Q  => s_Q4,                       -- Data output
      C  => s_Q1_bar,                   -- Clock input
      CE => '1',                        -- Clock enable input
      R  => '0',                        -- Synchronous reset input
      D  => s_Q2                        -- Data input
      );

  s_X <= s_Q3_bar nand s_Q1;
  s_Y <= (not s_Q1) nand s_Q4;

  pd_o <= s_X nand s_Y;

end architecture rtl;
