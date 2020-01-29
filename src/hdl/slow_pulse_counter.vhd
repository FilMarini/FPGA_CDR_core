-------------------------------------------------------------------------------
-- Title      : slow pulse counter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : slow_pulse_counter.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : University of Padova, INFN Padova
-- Created    : 2020-01-29
-- Last update: 2020-01-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 University of Padova, INFN Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-29  1.0      filippo	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slow_pulse_counter is
  generic (
    g_num_bit_threshold : positive := 3
    );
  port (
    clk_i   : in  std_logic;
    pulse_i : in  std_logic;
    pulse_o : out std_logic
    );
end entity slow_pulse_counter;

architecture rtl of slow_pulse_counter is

  signal s_pulse_re : std_logic;
  signal u_pulse_counter : unsigned(31 downto 0);
  signal s_pulse_counter : std_logic_vector(31 downto 0);

begin  -- architecture rtl

  r_edge_detect_1: entity work.r_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => clk_i,
      sig_i => pulse_i,
      sig_o => s_pulse_re
      );

  p_pulse_counter: process (clk_i) is
  begin  -- process p_pulse_counter
    if rising_edge(clk_i) then       -- rising clock edge
      if s_pulse_re = '1' then
        u_pulse_counter <= u_pulse_counter + 1;
      end if;
    end if;
  end process p_pulse_counter;

  s_pulse_counter <= std_logic_vector(u_pulse_counter);

  pulse_o <= s_pulse_counter(g_num_bit_threshold);

end architecture rtl;
