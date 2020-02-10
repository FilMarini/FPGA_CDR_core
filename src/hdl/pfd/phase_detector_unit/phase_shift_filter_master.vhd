-------------------------------------------------------------------------------
-- Title      : phase shift filter master
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_shift_filter_master.vhd
-- Author     : Filippo Marini  <filippo.marini@pd.infn.it>
-- Company    : University of Padova, INFN Padova
-- Created    : 2020-01-30
-- Last update: 2020-02-10
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: this module defines the start and stop of the phase filtering
-- window for the slave, through an internal counter;
-- The number of potential transitions is 2^(g_num_trans)
-------------------------------------------------------------------------------
-- Copyright (c) 2020 University of Padova, INFN Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-30  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity phase_shift_filter_master is
  generic (
    g_num_trans  : positive;
    g_num_slaves : positive := 2
    );
  port (
    clk_i                 : in  std_logic;
    rst_i                 : in  std_logic;
    en_i                  : in  std_logic;
    slaves_ready_i        : in  std_logic_vector(g_num_slaves - 1 downto 0);
    phase_filter_window_o : out std_logic
    );
end entity phase_shift_filter_master;

architecture rtl of phase_shift_filter_master is

  signal u_window_counter : unsigned(31 downto 0);
  signal s_window_counter : std_logic_vector(31 downto 0);
  signal s_all_ready      : std_logic;

  alias s_not_window : std_logic is s_window_counter(g_num_trans);

begin  -- architecture rtl

  -- start counting when all slaves are ready
  s_all_ready <= and_reduce(slaves_ready_i);

  -----------------------------------------------------------------------------
  -- Counter
  -----------------------------------------------------------------------------
  p_window_counter : process (clk_i, rst_i) is
  begin  -- process p_window_counter
    if rst_i = '1' or s_all_ready = '1' then  -- asynchronous reset (active high)
      u_window_counter <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      if en_i = '1' then
        u_window_counter <= u_window_counter + 1;
      end if;
    end if;
  end process p_window_counter;

  s_window_counter <= std_logic_vector(u_window_counter);

  -----------------------------------------------------------------------------
  -- Output control
  -----------------------------------------------------------------------------
  phase_filter_window_o <= not s_not_window;

end architecture rtl;
