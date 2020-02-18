-------------------------------------------------------------------------------
-- Title      : bang bang phase detector
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_detector_w_en.vhdl
-- Author     : Antonio Bergnoli  <a.bergnoli@gmail.com>
-- Company    : 
-- Created    : 2016-01-03
-- Last update: 2020-02-18
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: alexander 'style' phase detector
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-01-03  1.0      antonio Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library extras;
use extras.synchronizing.all;

-------------------------------------------------------------------------------

entity phase_detector_w_en is

  port (data_in  : in  std_logic;
        sys_clk  : in  std_logic;
        enable_i : in  std_logic;
        x        : out std_logic;
        y        : out std_logic
        );

end entity phase_detector_w_en;

-------------------------------------------------------------------------------

architecture str of phase_detector_w_en is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  -- signal positive_q : std_logic_vector(2 downto 0);
  signal positive_q  : std_logic_vector(4 downto 0);
  signal negative_q  : std_logic;
  signal T           : std_logic;
  signal E           : std_logic;
  signal te_vector   : std_logic_vector(1 downto 0);
  signal s_enable_df : std_logic;
  signal s_x, s_y    : std_logic;

  -- attribute mark_debug      : string;
  -- attribute mark_debug of T : signal is "true";
  -- attribute mark_debug of E : signal is "true";


  type transition_type is (idle,
                           up,
                           down);
  signal transition_state : transition_type;

begin  -- architecture str

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  bit_synchronizer_1 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => sys_clk,
      Reset  => '0',
      Bit_in => enable_i,
      Sync   => s_enable_df
      );

  -- purpose: main process implementing the sequential sturcture
  -- type   : sequential
  -- inputs : sys_clk
  -- outputs: 
  main : process (sys_clk) is
  begin  -- process main
    if rising_edge(sys_clk) then        -- rising clock edge
      positive_q(2) <= data_in;
      positive_q(1) <= positive_q(2);
      positive_q(0) <= negative_q;
      positive_q(3) <= positive_q(1);   -- to remove metastability
      positive_q(4) <= positive_q(0);   -- to remove metastability
    end if;
  end process main;

-- purpose: negative edge clocking p
-- type   : sequential
-- inputs : sys_clk
-- outputs: 
  negative : process (sys_clk) is
  begin  -- process negative
    if falling_edge(sys_clk) then       --  falling clock edge
      negative_q <= data_in;
    end if;
  end process negative;

  -- x <= positive_q(1) xor positive_q(0);
  -- y <= positive_q(2) xor positive_q(0);

  -- T <= positive_q(1) xor positive_q(2);
  -- E <= positive_q(0) xor positive_q(1);

  T <= positive_q(1) xor positive_q(3);
  E <= positive_q(4) xor positive_q(3);

  te_vector <= T & E;

  transition_proc : process (sys_clk) is
  begin  -- process transition_proc
    if rising_edge(sys_clk) then        -- rising clock edge
      case te_vector is
        when "00"   => transition_state <= idle;
        when "10"   => transition_state <= down;
        when "11"   => transition_state <= up;
        when others => transition_state <= idle;
      end case;
    end if;
  end process transition_proc;

  transition_state_proc : process (sys_clk) is
  begin  -- process transition_state_proc
    if rising_edge(sys_clk) then        -- rising clock edge
      case transition_state is
        when idle =>
          s_x <= '0';
          s_y <= '0';
        when up =>
          s_x <= '1';
          s_y <= '0';
        when down =>
          s_x <= '0';
          s_y <= '1';
        when others =>
          s_x <= '0';
          s_y <= '0';
      end case;
    end if;
  end process transition_state_proc;

  p_output_enable: process (s_enable_df, s_x, s_y) is
  begin  -- process p_output_enable
    case s_enable_df is
      when '1' =>
        x <= s_x;
        y <= s_y;
      when '0' =>
        x <= '0';
        y <= '0';
      when others =>
        null;
    end case;
  end process p_output_enable;

end architecture str;

-------------------------------------------------------------------------------
