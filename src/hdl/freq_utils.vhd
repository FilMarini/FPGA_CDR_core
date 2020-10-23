-------------------------------------------------------------------------------
-- Title      : Frequency to Jump Size function package
-- Project    : 
-------------------------------------------------------------------------------
-- File       : freq_utils.vhd
-- Author     : filippo  <filippo@Dell-Precision-3520>
-- Company    : 
-- Created    : 2020-06-26
-- Last update: 2020-10-23
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: package including function that returns the jump size providing
-- the nominal frequency in MHz
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-06-26  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

package freq_utils is

  function freq_to_m (
    constant g_freq_in               : real;  -- MHz
    constant g_freq_out              : real;  -- MHz
    constant g_multiplication_factor : positive;
    constant g_number_of_bits        : positive)
    return integer;

  function freq_to_mmcm (
    constant g_freq_out : real)
    return real;

end package freq_utils;

package body freq_utils is

  function freq_to_m (
    constant g_freq_in               : real;
    constant g_freq_out              : real;
    constant g_multiplication_factor : positive;
    constant g_number_of_bits        : positive)
    return integer is
    variable jump_size_real : real;
  begin  -- function freq_to_m
    jump_size_real := (g_freq_out * real(2.0**(g_number_of_bits))) / (g_freq_in * real(2.0**(g_multiplication_factor - 1)));
    return integer(jump_size_real);

  end function freq_to_m;

  function freq_to_mmcm (
    constant g_freq_out : real)
    return real is
  begin  -- function freq_to_mult
    return 1000.0 / g_freq_out;
  end function freq_to_mmcm;

end package body freq_utils;
