-------------------------------------------------------------------------------
-- Title      : quadrant shifter detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : quadrant_shifting_detector.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : 
-- Created    : 2020-01-17
-- Last update: 2020-01-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-17  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity quadrant_shifter_detector is
  port (
    clk_i               : in  std_logic;
    rst_i               : in  std_logic;
    quadrant_rdy_i      : in  std_logic;
    quadrant_i          : in  std_logic_vector(1 downto 0);
    shifting_detected_o : out std_logic;
    shifting_o          : out std_logic;
    locked_o            : out std_logic
    );
end entity quadrant_shifter_detector;

architecture rtl of quadrant_shifter_detector is

  type t_state is (st0_idle,
                   st1_waiting_for_next_quadrant,
                   st2a_shifting_up,
                   st2b_shifting_down,
                   st3_update_quadrant
                   );

  signal s_state : t_state;

  signal s_quadrant          : std_logic_vector(1 downto 0);
  signal s_current_quadrant  : std_logic_vector(1 downto 0);
  signal s_locked            : std_logic;
  signal s_update_quadrant   : std_logic;
  signal s_shifting          : std_logic;
  signal s_shifting_detected : std_logic;


begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Quadrant latcher
  -----------------------------------------------------------------------------
  p_quadrant_latcher : process (clk_i) is
  begin  -- process p_quadrant_latcher
    if rising_edge(clk_i) then          -- rising clock edge
      if quadrant_rdy_i = '1' then
        s_quadrant <= quadrant_i;
      end if;
    end if;
  end process p_quadrant_latcher;

  -----------------------------------------------------------------------------
  -- Current quadrant
  -----------------------------------------------------------------------------
  p_current_quadrant : process (clk_i) is
  begin  -- process p_current_quadrant
    if rising_edge(clk_i) then          -- rising clock edge
      if s_update_quadrant = '1' then
        s_current_quadrant <= s_quadrant;
      end if;
    end if;
  end process p_current_quadrant;

  -----------------------------------------------------------------------------
  -- FSM
  -----------------------------------------------------------------------------
  p_update_state : process (clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(clk_i) then       -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if quadrant_rdy_i = '1' then
            s_state <= st1_waiting_for_next_quadrant;
          end if;
        --
        when st1_waiting_for_next_quadrant =>
          case s_current_quadrant is
            --
            when "00" =>
              if s_quadrant = "00" then
                s_state <= st1_waiting_for_next_quadrant;
              elsif s_quadrant = "01" then
                s_state <= st2a_shifting_up;
              elsif s_quadrant = "11" then
                s_state <= st2b_shifting_down;
              else
                s_state <= st0_idle;
              end if;
            --
            when "01" =>
              if s_quadrant = "01" then
                s_state <= st1_waiting_for_next_quadrant;
              elsif s_quadrant = "10" then
                s_state <= st2a_shifting_up;
              elsif s_quadrant = "00" then
                s_state <= st2b_shifting_down;
              else
                s_state <= st0_idle;
              end if;
            --
            when "10" =>
              if s_quadrant = "10" then
                s_state <= st1_waiting_for_next_quadrant;
              elsif s_quadrant = "11" then
                s_state <= st2a_shifting_up;
              elsif s_quadrant = "01" then
                s_state <= st2b_shifting_down;
              else
                s_state <= st0_idle;
              end if;
            --
            when "11" =>
              if s_quadrant = "11" then
                s_state <= st1_waiting_for_next_quadrant;
              elsif s_quadrant = "00" then
                s_state <= st2a_shifting_up;
              elsif s_quadrant = "10" then
                s_state <= st2b_shifting_down;
              else
                s_state <= st0_idle;
              end if;
            --
            when others =>
              null;
          --
          end case;
        --
        when st2a_shifting_up =>
          s_state <= st3_update_quadrant;
        --
        when st2b_shifting_down =>
          s_state <= st3_update_quadrant;
        --
        when st3_update_quadrant =>
          s_state <= st1_waiting_for_next_quadrant;
        --
        when others =>
          null;
      --
      end case;
    end if;
  end process p_update_state;

  p_update_output : process (s_state) is
  begin  -- process p_update_output
    case s_state is
      --
      when st0_idle =>
        s_locked            <= '0';
        s_update_quadrant   <= '0';
        s_shifting          <= '0';
        s_shifting_detected <= '0';
      --
      when st1_waiting_for_next_quadrant =>
        s_locked            <= '1';
        s_update_quadrant   <= '0';
        s_shifting          <= '0';
        s_shifting_detected <= '0';
      --
      when st2a_shifting_up =>
        s_locked            <= '1';
        s_update_quadrant   <= '0';
        s_shifting          <= '1';
        s_shifting_detected <= '1';
      --
      when st2b_shifting_down =>
        s_locked            <= '1';
        s_update_quadrant   <= '0';
        s_shifting          <= '0';
        s_shifting_detected <= '1';
      --
      when st3_update_quadrant =>
        s_locked            <= '1';
        s_update_quadrant   <= '1';
        s_shifting          <= '0';
        s_shifting_detected <= '0';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  locked_o            <= s_locked;
  shifting_o          <= s_shifting;
  shifting_detected_o <= s_shifting_detected;



end architecture rtl;
