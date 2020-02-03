-------------------------------------------------------------------------------
-- Title      : quadrant detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : quadrant_detector.vhd
-- Author     : filippo  <filippo@Dell-Precision-3520>
-- Company    : 
-- Created    : 2020-01-16
-- Last update: 2020-02-03
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: More like a quadrant decoder
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-16  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity quadrant_detector is
  port (
    clk_i          : in  std_logic;
    rst_i          : in  std_logic;
    i_early_i      : in  std_logic;
    i_late_i       : in  std_logic;
    q_early_i      : in  std_logic;
    q_late_i       : in  std_logic;
    quadrant_o     : out std_logic_vector(1 downto 0);
    quadrant_rdy_o : out std_logic
    );
end entity quadrant_detector;

architecture rtl of quadrant_detector is

  type t_state is (st0_idle,
                   st1a_I,
                   st1b_II,
                   st1c_III,
                   st1d_IV
                   );

  signal s_state : t_state;

  signal s_quadrant_rdy : std_logic;
  signal s_quadrant     : std_logic_vector(1 downto 0);
  signal s_go_to_idle   : std_logic;

begin  -- architecture rtl

  s_go_to_idle <= or_reduce(std_logic_vector'(i_early_i & i_late_i & q_early_i & q_late_i));

  p_update_state : process (clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(clk_i) then       -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if i_early_i = '1' and i_late_i = '0' and q_early_i = '0' and q_late_i = '1' then
            s_state <= st1a_I;
          elsif i_early_i = '1' and i_late_i = '0' and q_early_i = '1' and q_late_i = '0' then
            s_state <= st1b_II;
          elsif i_early_i = '0' and i_late_i = '1' and q_early_i = '1' and q_late_i = '0' then
            s_state <= st1c_III;
          elsif i_early_i = '0' and i_late_i = '1' and q_early_i = '0' and q_late_i = '1' then
            s_state <= st1d_IV;
          end if;
        --
        when st1a_I =>
          if s_go_to_idle = '0' then
            s_state <= st0_idle;
          end if;
        --
        when st1b_II =>
          if s_go_to_idle = '0' then
            s_state <= st0_idle;
          end if;
        --
        when st1c_III =>
          if s_go_to_idle = '0' then
            s_state <= st0_idle;
          end if;
        --
        when st1d_IV =>
          if s_go_to_idle = '0' then
            s_state <= st0_idle;
          end if;
        --
        when others =>
          s_state <= st0_idle;
      --
      end case;
    end if;
  end process p_update_state;

  p_update_output : process (s_state) is
  begin  -- process p_update_output
    case s_state is
      --
      when st0_idle =>
        s_quadrant_rdy <= '0';
        s_quadrant     <= (others => '0');
      --
      when st1a_I =>
        s_quadrant_rdy <= '1';
        s_quadrant     <= (others => '0');
      --
      when st1b_II =>
        s_quadrant_rdy <= '1';
        s_quadrant     <= "01";
      --
      when st1c_III =>
        s_quadrant_rdy <= '1';
        s_quadrant     <= "10";
      --
      when st1d_IV =>
        s_quadrant_rdy <= '1';
        s_quadrant     <= "11";
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  quadrant_rdy_o <= s_quadrant_rdy;
  quadrant_o     <= s_quadrant;

end architecture rtl;
