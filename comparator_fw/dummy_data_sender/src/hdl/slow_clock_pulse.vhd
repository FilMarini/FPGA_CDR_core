-------------------------------------------------------------------------------
-- Title      : slow clock pulse
-- Project    : 
-------------------------------------------------------------------------------
-- File       : slow_clock_pulse.vhd
-- Author     : Antonio Bergnoli  <bergnoli@pd.infn.it>
-- Company    : 
-- Created    : 2019-02-25
-- Last update: 2019-05-23
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: generates a programmable slow clock
-------------------------------------------------------------------------------
-- Copyright (c) 2019 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-02-25  1.0      antonio Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity slow_clock_pulse is

  generic (
    ref_clk_period_ns      : integer := 10;  -- input clock period width in nanoseconds
    output_pulse_period_ms : integer := 1000;  -- output period in ms.
    n_pulse_up             : integer := 1);  -- number of input clock periods that
  -- the output pulse stays active

  port (
    ref_clk   : in  std_logic;
    pulse_out : out std_logic);

end entity slow_clock_pulse;

-------------------------------------------------------------------------------

architecture str of slow_clock_pulse is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  constant main_divisor : integer := output_pulse_period_ms / ref_clk_period_ns * 1_000_000;
-- 1.000.000 = 1 ms / 1 ns

  signal int_counter : integer := 0;
  signal pulse_high  : integer := 0;
begin  -- architecture str

-- purpose: generate the output pulse
-- type   : sequential
-- inputs : ref_clk, 
-- outputs: n_pulse_out 
  main : process (ref_clk) is
    -- variable int_counter : integer := 0;
    -- variable pulse_high  : integer := 0;
    type state_t is (counting_st, high_st);
    variable state : state_t := counting_st;
  begin  -- process main
    if rising_edge(ref_clk) then        -- rising clock edge
      case state is
        when counting_st =>
          pulse_out <='0';
          int_counter <= int_counter + 1;
          if int_counter = main_divisor - n_pulse_up then
            state := high_st;
          end if;
        when high_st =>
          pulse_out <='1';
          pulse_high <= pulse_high + 1;
          if pulse_high = n_pulse_up then
            pulse_high  <= 0;
            int_counter <= 0;
            state       := counting_st;
          end if;
        when others => null;
      end case;
    end if;
  end process main;

end architecture str;

-------------------------------------------------------------------------------
