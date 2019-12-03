-------------------------------------------------------------------------------
-- Title      : closed loop clock domain crossing
-- Project    : 
-------------------------------------------------------------------------------
-- File       : closed_loop_cdc.vhd
-- Author     : Antonio Bergnoli  <bergnoli@pd.infn.it>
-- Company    : 
-- Created    : 2019-10-21
-- Last update: 2019-10-24
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: closed loop synchronizer for clock domain crossing
--              a single pulse
--
--            An input signal could be long one or more clock cycle (has to be
--            synch generated with the input clock (a)
--            The output pulse will be synchronous with the output clock (b)
--            
-------------------------------------------------------------------------------
-- Copyright (c) 2019 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-21  1.0      antonio Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


entity closed_loop_cdc is
  generic (
    -- flag_out : boolean               := false;
    n_stages : integer range 2 to 10 := 3);
  port (
    a_clk     : in  std_logic;          -- first clock domain 
    pulse_in  : in  std_logic;
    b_clk     : in  std_logic;          -- second clock domain 
    pulse_out : out std_logic);

end entity closed_loop_cdc;

architecture rtl of closed_loop_cdc is

  signal input_buffer    : std_logic_vector(n_stages - 1 downto 0);
  signal output_buffer   : std_logic_vector(n_stages - 1 downto 0);
  signal clear_buffer    : std_logic_vector(n_stages - 1 downto 0);
  signal pulse_out_s     : std_logic;
  signal edge            : std_logic;
  signal shaped_pulse_in : std_logic;
  signal shaper_clear    : std_logic;

begin  -- architecture rtl


  -----------------------------------------------------------------------------
  -- edge detector for the input pulse
  -----------------------------------------------------------------------------

  input_edge_detect : process (a_clk) is
  begin  -- process input_edge_detect
    if rising_edge(a_clk) then          -- rising clock edge
      input_buffer <= input_buffer (n_stages - 2 downto 0) & pulse_in;
      edge         <= (not input_buffer(n_stages - 1)) and (input_buffer(n_stages - 2));
    end if;
  end process input_edge_detect;
  -----------------------------------------------------------------------------
  -- resettable shaper 
  -----------------------------------------------------------------------------
  shaper : process (a_clk) is
    type state_t is (idle_st, shaping_st);
    variable state : state_t := idle_st;
  begin  -- process shaper
    if rising_edge(a_clk) then          -- rising clock edge
      case state is
        when idle_st =>
          shaped_pulse_in <= '0';
          if edge = '1' then
            state := shaping_st;
          end if;
        when shaping_st =>
          shaped_pulse_in <= '1';
          if shaper_clear = '1' then
            shaped_pulse_in <= '0';
            state           := idle_st;
          end if;
        when others =>
          state := idle_st;
      end case;
    end if;
  end process shaper;

  -----------------------------------------------------------------------------
  -- multiple flop section for the first clock domain
  -----------------------------------------------------------------------------
  multi_flop_out : process (b_clk) is
  begin  -- process double_flop_out
    if rising_edge(b_clk) then          -- rising clock edge
      output_buffer <= output_buffer(n_stages - 2 downto 0) & shaped_pulse_in;
      -- if flag_out then

      --   pulse_out_s <= (not output_buffer(n_stages - 1)) and (output_buffer(n_stages - 2));
      -- else
      --   pulse_out_s <= output_buffer(n_stages - 1);
--      end if;
      pulse_out_s <= (not output_buffer(n_stages - 1)) and (output_buffer(n_stages - 2));
    end if;
  end process multi_flop_out;

-----------------------------------------------------------------------------
-- multiple flop section for the second clock domain
-----------------------------------------------------------------------------
  multi_flop_clear : process (a_clk) is
  begin  -- process double_flop_clear
    if rising_edge(a_clk) then          -- rising clock edge
      clear_buffer <= clear_buffer(n_stages - 2 downto 0) & pulse_out_s;
    end if;
  end process multi_flop_clear;
  shaper_clear <= clear_buffer(n_stages - 1);
  pulse_out    <= pulse_out_s;
end architecture rtl;
