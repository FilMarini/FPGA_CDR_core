-------------------------------------------------------------------------------
-- Title      : cdr manager
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cdr_manager.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : University of Padova, INFN Padova
-- Created    : 2020-01-29
-- Last update: 2020-01-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Switches between the pfd and the BB phase detector. the pfd is
-- needed to get to the closest frequency, while the BB-PD dynamically mantain
-- the edge alignment. When the pfd reaches the closest frequency, the locked
-- flag goes to 1, and the BB-PD enters the action.
-------------------------------------------------------------------------------
-- Copyright (c) 2020 University of Padova, INFN Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-29  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity cdr_manager is
  port (
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    en_i      : in  std_logic;
    locked_i  : in  std_logic;
    pfd_en_o  : out std_logic;
    bbpd_en_o : out std_logic
    );
end entity cdr_manager;

architecture rtl of cdr_manager is

  type t_state is (st0_idle,
                   st1_pfd_en,
                   st2_bbpd_en
                   );

  signal s_state : t_state;

begin  -- architecture rtl

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
          if en_i = '1' then
            s_state <= st1_pfd_en;
          end if;
        --
        when st1_pfd_en =>
          if locked_i = '1' then
            s_state <= st2_bbpd_en;
          end if;
        --
        when st2_bbpd_en =>
          if locked_i = '0' then
            s_state <= st0_idle;
          end if;
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
        pfd_en_o  <= '0';
        bbpd_en_o <= '0';
      --
      when st1_pfd_en =>
        pfd_en_o  <= '1';
        bbpd_en_o <= '0';
      --
      when st2_bbpd_en =>
        pfd_en_o  <= '0';
        bbpd_en_o <= '1';
      --
      when others =>
        pfd_en_o  <= '0';
        bbpd_en_o <= '0';
    --
    end case;
  end process p_update_output;




end architecture rtl;
