-------------------------------------------------------------------------------
-- Title      : deglitcher
-- Project    : 
-------------------------------------------------------------------------------
-- File       : deglitcher.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-02
-- Last update: 2019-12-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Design based on the WR deglitcher design
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-02  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deglitcher is

  generic (
    g_stable_threshold : positive := 16
    );
  port (
    ls_clk_i          : in  std_logic;
    rst_i             : in  std_logic;
    input_i           : in  std_logic;
    counter_i         : in  std_logic_vector(31 downto 0);
    calc_en_i         : in  std_logic;
    phase_tag_o       : out std_logic_vector(31 downto 0);
    phase_tag_ready_o : out std_logic
    );

end entity deglitcher;

architecture rtl of deglitcher is

  type t_state is (st0_wait_stable_0,
                   st1_wait_edge,
                   st2_got_edge
                   );

  signal s_state           : t_state;
  signal s_phase_tag       : std_logic_vector(31 downto 0);
  signal s_phase_tag_ready : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- FSM
  -----------------------------------------------------------------------------
  p_update_state_and_output : process (ls_clk_i, rst_i) is
    variable v_stab_counter : unsigned(15 downto 0);
    variable v_tag_int      : unsigned(31 downto 0);
  begin  -- process p_update_state
    if rst_i = '1' or calc_en_i = '0' then  -- asynchronous reset (active high)
      v_stab_counter := (others => '0');
      s_state          <= st0_wait_stable_0;
    elsif rising_edge(ls_clk_i) then        -- rising clock edge
      case s_state is
        --
        when st0_wait_stable_0 =>
          s_phase_tag_ready <= '0';
          if input_i = '1' then
            v_stab_counter := (others => '0');
          else
            v_stab_counter := v_stab_counter + 1;
          end if;
          if v_stab_counter = g_stable_threshold then
            s_state <= st1_wait_edge;
          end if;
        --
        when st1_wait_edge =>
          s_phase_tag_ready <= '0';
          if input_i = '1' then
            v_tag_int      := unsigned(counter_i);
            v_stab_counter := (others => '0');
            s_state        <= st2_got_edge;
          end if;
        --
        when st2_got_edge =>
          if input_i = '0' then
            v_tag_int      := v_tag_int + 1;
            v_stab_counter := (others => '0');
          else
            v_stab_counter := v_stab_counter + 1;
          end if;
          if v_stab_counter = g_stable_threshold then
            s_phase_tag       <= std_logic_vector(v_tag_int);
            s_state           <= st0_wait_stable_0;
            s_phase_tag_ready <= '1';
          end if;
        --
        when others =>
          null;
      --
      end case;
    end if;
  end process p_update_state_and_output;

  -----------------------------------------------------------------------------
  -- Output control
  -----------------------------------------------------------------------------
  phase_tag_o       <= s_phase_tag;
  phase_tag_ready_o <= s_phase_tag_ready;

end architecture rtl;
