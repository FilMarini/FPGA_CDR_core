-------------------------------------------------------------------------------
-- Title      : slow phase analyzer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_detector.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-16
-- Last update: 2019-10-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: creates the output to be compared to obtain the n_cycle 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-16  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slow_phase_analyzer is
  port (
    hs_clk_i : in  std_logic;
    ls_clk_i : in  std_logic;
    output_o : out std_logic
    );
end entity slow_phase_analyzer;

architecture rtl of slow_phase_analyzer is

  signal s_hs_toggle : std_logic := '0';
  signal s_hs_toggle_df : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- HS Clock Toggle
  -----------------------------------------------------------------------------
  p_hs_clk_toggle : process (hs_clk_i) is
  begin  -- process p_hs_clk_toggle
    if rising_edge(hs_clk_i) then       -- rising clock edge
      s_hs_toggle <= not s_hs_toggle;
    end if;
  end process p_hs_clk_toggle;

  -----------------------------------------------------------------------------
  -- Avoid metastability
  -----------------------------------------------------------------------------
  i_triple_flop_ls_sampling : entity work.triple_flop
    generic map (
      g_width    => 1,
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => ls_clk_i,
      sig_i(0) => s_hs_toggle,
      sig_o(0) => s_hs_toggle_df
      );

  output_o <= s_hs_toggle_df;


end architecture rtl;
