-------------------------------------------------------------------------------
-- Title      : dummy data receiver
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_level.vhd<dummy_data_receiver>
-- Author     : filippo  <filippo@Dell-Precision-3520>
-- Company    : 
-- Created    : 2020-05-06
-- Last update: 2020-05-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-05-06  1.0      filippo	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;

entity top_level is
  port (
    prbs_from_cat5_p_i : in  std_logic;
    prbs_from_cat5_n_i : in  std_logic;
    clk_from_cat5_p_i  : in  std_logic;
    clk_from_cat5_n_i  : in  std_logic;
    coax_o             : out std_logic;
    coax1_o            : out std_logic
    );
end entity top_level;

architecture rtl of top_level is

  signal s_prbs : std_logic;
  signal s_clk : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- PRBS and clk receiver from cat5
  -----------------------------------------------------------------------------
  i_IBUFDS_from_cat5 : IBUFDS
    generic map (
      DIFF_TERM    => false,
      IBUF_LOW_PWR => true,
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => s_prbs,
      I  => prbs_from_cat5_p_i,
      IB => prbs_from_cat5_n_i
      );

  i_IBUFDS_from_cat5 : IBUFDS
    generic map (
      DIFF_TERM    => false,
      IBUF_LOW_PWR => true,
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => s_clk,
      I  => clk_from_cat5_p_i,
      IB => clk_from_cat5_n_i
      );
  
  -----------------------------------------------------------------------------
  -- Output Control to CDR
  -----------------------------------------------------------------------------
  i_OBUF : OBUF
    port map (
      I => s_prbs,
      O => coax_o
      );

  i_OBUF_1 : OBUF
    port map (
      I => s_clk,
      O => coax1_o
      );



end architecture rtl;
