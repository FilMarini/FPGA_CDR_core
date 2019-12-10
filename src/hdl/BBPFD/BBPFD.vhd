-------------------------------------------------------------------------------
-- Title      : Bang bang phase and frequency detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : BBPFD.vhd
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
-- 2019-12-09  1.0      filippo	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity BBPFD is
  port (
    clk_i     : in  std_logic;
    clk_90_i  : in  std_logic;
    clk_180_i : in  std_logic;
    clk_270_i : in  std_logic;
    data_i    : in  std_logic;
    PFD_o     : out std_logic
    );
end entity BBPFD;

architecture rtl of BBPFD is

  signal s_pd1 : std_logic;
  signal s_pd2 : std_logic;
  signal s_Q3 : std_logic;
  signal s_Q3_bar : std_logic;
  signal s_pd1_bar : std_logic;
  signal s_Q4 : std_logic;
  signal s_X : std_logic;
  signal s_Y : std_logic;

begin  -- architecture rtl

  BBPD_1: entity work.BBPD
    port map (
      clk_i     => clk_i,
      clk_180_i => clk_180_i,
      data_i    => data_i,
      pd_o      => s_pd1
      );

  BBPD_2: entity work.BBPD
    port map (
      clk_i     => clk_90_i,
      clk_180_i => clk_270_i,
      data_i    => data_i,
      pd_o      => s_pd2
      );

  i_Q3 : FDRE
    generic map (
      INIT => '0')  -- Initial value of register ('0' or '1')  
    port map (
      Q  => s_Q3,                       -- Data output
      C  => s_pd1,                      -- Clock input
      CE => '1',                        -- Clock enable input
      R  => '0',                        -- Synchronous reset input
      D  => s_pd2                      -- Data input
      );

  s_Q3_bar <= not s_Q3;

  s_pd1_bar <= not s_pd1;

  i_Q4 : FDRE
    generic map (
      INIT => '0')  -- Initial value of register ('0' or '1')  
    port map (
      Q  => s_Q4,                       -- Data output
      C  => s_pd1_bar,                      -- Clock input
      CE => '1',                        -- Clock enable input
      R  => '0',                        -- Synchronous reset input
      D  => s_pd2                      -- Data input
      );

  s_X <= s_Q3_bar nand s_pd1;
  s_Y <= s_pd1_bar nand s_Q4;

  PFD_o <= s_X nand s_Y;

end architecture rtl;
