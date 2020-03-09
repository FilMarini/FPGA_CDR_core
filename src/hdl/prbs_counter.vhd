-------------------------------------------------------------------------------
-- Title      : prbs counter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : prbs_counter.vhd
-- Author     : filippo  <filippo@Dell-Precision-3520>
-- Company    : 
-- Created    : 2020-03-09
-- Last update: 2020-03-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-03-09  1.0      filippo	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prbs_counter is
  port (
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    err_i     : in  std_logic;
    locked_i  : in  std_logic;
    counter_o : out std_logic_vector(7 downto 0)
    );
end entity prbs_counter;

architecture rtl of prbs_counter is

  signal u_counter : unsigned(7 downto 0);

begin  -- architecture rtl

  p_counter: process (clk_i, rst_i) is
  begin  -- process p_counter
    if rst_i = '1' then                 -- asynchronous reset (active high)
      u_counter <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if err_i = '1' and locked_i = '1' then
        u_counter <= u_counter + 1;
      end if;
    end if;
  end process p_counter;

  counter_o <= std_logic_vector(u_counter);

end architecture rtl;
