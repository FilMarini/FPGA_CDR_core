-------------------------------------------------------------------------------
-- Title      : n_cycle generator
-- Project    : 
-------------------------------------------------------------------------------
-- File       : n_cycle_generator.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-02
-- Last update: 2019-12-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: calculate n_cycle starting from the phase tags of the
-- deglitcher 
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

entity n_cycle_generator is
  port (
    ls_clk_i             : in  std_logic;
    rst_i                : in  std_logic;
    phase_tag_A_in       : in  std_logic_vector(31 downto 0);
    phase_tag_A_ready_in : in  std_logic;
    phase_tag_B_in       : in  std_logic_vector(31 downto 0);
    phase_tag_B_ready_in : in  std_logic;
    n_cycle_o            : out std_logic_vector(15 downto 0);
    n_cycle_ready_o      : out std_logic
    );
end entity n_cycle_generator;

architecture rtl of n_cycle_generator is

  type t_state is (st0_idle,
                   st1_gotA,
                   st2_gotB
                   );

  signal s_state                 : t_state;
  signal s_n_cycle               : std_logic_vector(15 downto 0);
  signal s_n_cycle_ready         : std_logic;
  signal sgn_phase_tag_A_latched : signed(31 downto 0);
  signal sgn_phase_tag_B_latched : signed(31 downto 0);

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- FSM
  -----------------------------------------------------------------------------
  p_update_state_and_output : process (ls_clk_i, rst_i) is
  begin  -- process p_update_state_and_output
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_state         <= st0_idle;
      s_n_cycle_ready <= '0';
      s_n_cycle       <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          s_n_cycle_ready <= '0';
          if phase_tag_A_ready_in = '1' then
            sgn_phase_tag_A_latched <= signed(phase_tag_A_in);
            s_state                 <= st1_gotA;
          end if;
        --
        when st1_gotA =>
          s_n_cycle_ready <= '0';
          if phase_tag_B_ready_in = '1' then
            sgn_phase_tag_B_latched <= signed(phase_tag_B_in);
            s_state                 <= st2_gotB;
          end if;
        --
        when st2_gotB =>
          s_n_cycle_ready <= '1';
          s_n_cycle       <= std_logic_vector(resize((sgn_phase_tag_B_latched - sgn_phase_tag_A_latched), 16));
          s_state <= st0_idle;
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
  n_cycle_o       <= s_n_cycle;
  n_cycle_ready_o <= s_n_cycle_ready;


end architecture rtl;
