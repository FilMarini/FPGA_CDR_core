-------------------------------------------------------------------------------
-- Title      : phase shifter controller
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ps_controller.vhdl
-- Author     : Antonio Bergnoli  <antonio.bergnoli@dwave.it>
-- Company    : 
-- Created    : 2016-01-14
-- Last update: 2016-01-19
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: controls phase shift capability of the DCM/MMCE Xilinx 
-- clock resources
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-01-14  1.0      antonio Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
-------------------------------------------------------------------------------

entity ps_controller is
  generic (
    resource_type : string := "MMCME");  -- i should be MMCE or DCM

  port (
    clk        : in  std_logic;
    phase_up   : in  std_logic;
    phase_down : in  std_logic;
    psclk      : out std_logic;
    psen       : out std_logic;
    psincdec   : out std_logic;
    psdone     : in  std_logic);
end entity ps_controller;

-------------------------------------------------------------------------------

architecture str of ps_controller is
  signal phase_up_synch   : std_logic_vector(1 downto 0);
  signal phase_down_synch : std_logic_vector(1 downto 0);
  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------

begin  -- architecture str
  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  -- purpose: synchronization process
  -- type   : sequential
  -- inputs : clk, phase_up, phase_down
  -- outputs: phase_up_synch,phase_out_synch
  synchronizer : process (clk) is
  begin  -- process synchronizer
    if rising_edge(clk) then            -- rising clock edge
      phase_up_synch   <= phase_up_synch(0) & phase_up;
      phase_down_synch <= phase_down_synch(0) & phase_down;
    end if;
  end process synchronizer;
-- purpose: main state machine process
-- type   : sequential
-- inputs : clk, phase_up, phase_down
-- outputs: psen, psincdec
  main_state_machine : process (clk) is
    type sm_state is (Idle, Up, Down);
    constant timeout_range   : integer  := 1024;
    variable state           : sm_state := Idle;
    variable phase           : integer range 0 to 1;
    variable L               : line;
    variable timeout_counter : integer range 0 to timeout_range;
  begin  -- process main_state_machine
    if rising_edge(clk) then            -- rising clock edge
      case state is
        when Idle =>
          phase    := 0;
          psen     <= '0';
          psincdec <= '0';
          if phase_up_synch(1) = '0' and phase_down_synch(1) = '0' then
            state := Idle;
          elsif phase_up_synch(1) = '0' and phase_down_synch(1) = '1' then
            state := Down;
          elsif phase_up_synch(1) = '1' and phase_down_synch(1) = '0' then
            state := Up;
          elsif phase_up_synch(1) = '1' and phase_down_synch(1) = '1' then
            state := Idle;
          end if;
        when Up =>
          case phase is
            when 0 =>
              psen     <= '1';
              psincdec <= '1';
              phase    := 1;
            when 1 =>
              psen <= '0';
            when others =>
              state := Idle;
          end case;
          if psdone = '1' then
            state := Idle;
          else
            timeout_counter := timeout_counter + 1;
          end if;
        when Down =>
          case phase is
            when 0 =>
              psen     <= '1';
              psincdec <= '0';
              phase    := 1;
            when 1 =>
              psen <= '0';
            when others =>
              state := Idle;
          end case;
          if psdone = '1' then
            state := Idle;
          else
            timeout_counter := timeout_counter + 1;
          end if;
        when others =>
          state := Idle;
      end case;
      if timeout_counter = timeout_range then
        timeout_counter := 0;
      --   state           := Idle;
      end if;
    end if;
    psclk <= clk;                       -- propagation of system clock to phase
    -- shift clock
    -- synthesis translate_off
    write(L, now);
    write (L, string'(" Current State: "));
    write (L, sm_state'image(state));
    writeline(output, L);
    -- synthesis translate_on
  end process main_state_machine;
end architecture str;

-------------------------------------------------------------------------------
