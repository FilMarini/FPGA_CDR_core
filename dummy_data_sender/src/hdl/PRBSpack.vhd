----------------------------------------------------------------------------------
-- Company:   INFN Laboratori Nazionali Legnaro
-- Engineer:  Davide Pedretti
-- 
-- Project Name:   IOC
-- Target Devices: Spartan6 xc6slx45t-fgg484
--
-- Description: 
-- This package defines the BaudrateTable function and types and constants
-- needed in the IOC memory space.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package PRBSpack is

-------------------------------function-------------------------------------------
function f_freq_table (bitrate : real) return integer;
function f_div_table (bitrate : real; cdr_clkin_period : real) return integer;
function f_log2 (A : natural) return natural;
----------------------------------------------------------------------------------

end PRBSpack;

package body PRBSpack is

function f_log2 (A : natural) return natural is
  begin
    for I in 1 to 64 loop     -- Works for up to 64 bits
      if (2**I >= A) then
        return(I);
      end if;
    end loop;
    return(63);
  end function f_log2;

function f_freq_table (bitrate : real) return integer is
 variable v_int : real;
begin
   v_int := (16.0*(62.5/bitrate));
   return(integer(v_int));
end function f_freq_table;
  
function f_div_table (bitrate : real; cdr_clkin_period : real) return integer is
   variable v_int : real;
	begin
   v_int := ((((1.0/cdr_clkin_period)*1000000000.0)*64.0)/16.0)/(bitrate*1000000.0);
	return(integer(v_int));
end function f_div_table; 
  
end PRBSpack;
