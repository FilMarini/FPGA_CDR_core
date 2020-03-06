-------------------------------------------------------------------------------
-- Title      : phase weel counter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_weel_counter.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-07
-- Last update: 2020-03-05
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: DDS
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-07  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_weel_counter is
  generic (
    g_number_of_bits : positive := 28
    );
  port (
    clk_i         : in  std_logic;
    M_i           : in  std_logic_vector(g_number_of_bits - 1 downto 0);
    mmcm_locked_i : in  std_logic;
    clk_o         : out std_logic_vector(7 downto 0)
    );
end entity phase_weel_counter;

architecture rtl of phase_weel_counter is

  type t_uns_counter is array (7 downto 0) of unsigned (g_number_of_bits - 1 downto 0);
  type t_uns_base is array (6 downto 0) of unsigned (g_number_of_bits - 1 downto 0);
  type t_std_counter is array (7 downto 0) of std_logic_vector (g_number_of_bits - 1 downto 0);

  signal u_phase_wheel_counter : t_uns_counter;
  signal s_phase_wheel_counter : t_std_counter;
  signal u_M                   : unsigned(g_number_of_bits - 1 downto 0);
  signal u_base                : t_uns_base;

begin  -- architecture rtl

  u_M <= unsigned(M_i);

  u_base(0) <= shift_right(u_M, 3);
  u_base(1) <= shift_right(u_M, 2);
  u_base(2) <= u_base(0) + u_base(1);
  u_base(3) <= shift_right(u_M, 1);
  u_base(4) <= u_base(3) + u_base(0);
  u_base(5) <= u_base(1) + u_base(3);
  u_base(6) <= u_base(5) + u_base(0);


  p_phase_wheel_counter : process (clk_i, mmcm_locked_i) is
  begin  -- process p_phase_wheel_counter
    if mmcm_locked_i = '0' then         -- asynchronous reset (active low)
      u_phase_wheel_counter(0) <= (others => '0');
    elsif rising_edge(clk_i) then       -- rising clock edge
      u_phase_wheel_counter(0) <= u_phase_wheel_counter(0) + u_M;
    end if;
  end process p_phase_wheel_counter;

  s_phase_wheel_counter(0) <= std_logic_vector(u_phase_wheel_counter(0));

  clk_o(0) <= s_phase_wheel_counter(0)(g_number_of_bits - 3);

  G_DECR_JITTER : for i in 1 to 7 generate

    u_phase_wheel_counter(i) <= u_phase_wheel_counter(0) + u_base(i-1);

    s_phase_wheel_counter(i) <= std_logic_vector(u_phase_wheel_counter(i));

    clk_o(i) <= s_phase_wheel_counter(i)(g_number_of_bits - 3);

  end generate G_DECR_JITTER;


end architecture rtl;
