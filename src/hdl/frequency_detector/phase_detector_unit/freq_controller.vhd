-------------------------------------------------------------------------------
-- Title      : frequency controller
-- Project    : 
-------------------------------------------------------------------------------
-- File       : freq_controller.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-09
-- Last update: 2019-12-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-09  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity freq_controller is
  port (
    clk_i            : in  std_logic;
    en_i             : in  std_logic;
    incr_freq_i      : in  std_logic;
    decr_freq_i      : in  std_logic;
    incr_freq_o      : out std_logic;
    change_freq_en_o : out std_logic
    );
end entity freq_controller;

architecture rtl of freq_controller is

  signal s_control_freq_vec : std_logic_vector(1 downto 0);

begin  -- architecture rtl

  s_control_freq_vec <= decr_freq_i & incr_freq_i;

  p_freq_control : process (clk_i) is
  begin  -- process p_freq_control
    if rising_edge(clk_i) then          -- rising clock edge
      if en_i = '1' then
        case s_control_freq_vec is
          when "10" =>
            incr_freq_o      <= '0';
            change_freq_en_o <= '1';
          when "01" =>
            incr_freq_o      <= '1';
            change_freq_en_o <= '1';
          when others =>
            incr_freq_o      <= '0';
            change_freq_en_o <= '0';
        end case;
      end if;
    end if;
  end process p_freq_control;


end architecture rtl;
