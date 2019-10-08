-------------------------------------------------------------------------------
-- Title      : led counter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : led_counter.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-07
-- Last update: 2019-10-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: make sure dds works 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-07  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_counter is
  generic (
    g_bit_to_pulse   : positive := 25;
    g_number_of_bits : positive := 28
    );
  port (
    clk_i             : in  std_logic;
    mmcm_locked_i     : in  std_logic;
    partial_ser_clk_i : in  std_logic;
    led_o             : out std_logic
    );
end entity led_counter;

architecture rtl of led_counter is

  signal u_led_counter : unsigned(g_number_of_bits - 1 downto 0);
  signal s_led_counter : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal s_clk_0_re    : std_logic;



begin  -- architecture rtl

  tap_edge_detector_I : entity work.r_edge_detect
    generic map(
      g_clk_rise => "TRUE"
      )
    port map(
      clk_i => clk_i,
      sig_i => partial_ser_clk_i,
      sig_o => s_clk_0_re
      );

  p_counter_led : process (clk_i, mmcm_locked_i) is
  begin  -- process p_counter_led
    if mmcm_locked_i = '0' then         -- asynchronous reset (active low)
      u_led_counter <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if s_clk_0_re = '1' then
        u_led_counter <= u_led_counter + 1;
      end if;
    end if;
  end process p_counter_led;

  s_led_counter <= std_logic_vector(u_led_counter);

  led_o <= s_led_counter(g_bit_to_pulse);


end architecture rtl;
