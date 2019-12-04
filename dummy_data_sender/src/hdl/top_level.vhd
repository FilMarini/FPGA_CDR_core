-------------------------------------------------------------------------------
-- Title      : top_level for dummy hardware
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_level.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-04
-- Last update: 2019-12-04
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

entity top_level is
  port (
    clk_i  : in  std_logic;
    led_o  : out std_logic;
    led1_o : out std_logic;
    clk_o  : out std_logic;
    clk1_o : out std_logic
    );
end entity top_level;

architecture rtl of top_level is

  signal s_clk     : std_logic;
  signal s_clk_fwd : std_logic_vector(1 downto 0);
  signal s_locked  : std_logic;

begin  -- architecture rtl

  i_jitter_cleaner_1 : entity work.jitter_cleaner
    generic map (
      g_use_ip    => false,
      g_bandwidth => "LOW",
      g_last      => true
      )
    port map (
      clk_in  => clk_i,
      rst_i   => '0',
      clk_out => s_clk,
      locked  => s_locked
      );

  GEN_OUTPUT : for i in 0 to 1 generate
    i_ODDR_inst : ODDR
      generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
        INIT         => '0',  -- Initial value for Q port ('1' or '0')
        SRTYPE       => "ASYNC")        -- Reset Type ("ASYNC" or "SYNC")
      port map (
        Q  => s_clk_fwd(i),             -- 1-bit DDR output
        C  => s_clk,                    -- 1-bit clock input
        CE => s_locked,              -- 1-bit clock enable input
        D1 => '1',                      -- 1-bit data input (positive edge)
        D2 => '0',                      -- 1-bit data input (negative edge)
        R  => not s_locked,             -- 1-bit reset input
        S  => '0'                       -- 1-bit set input
        );
  end generate GEN_OUTPUT;

  i_slow_clock_pulse_1 : entity work.slow_clock_pulse
    generic map (
      ref_clk_period_ns      => 16,
      output_pulse_period_ms => 1000,
      n_pulse_up             => 20_000_000
      )
    port map (
      ref_clk   => s_clk,
      pulse_out => led1_o
      );



  clk_o  <= s_clk_fwd(0);
  clk1_o <= s_clk_fwd(1);
  led_o  <= s_locked;



end architecture rtl;
