-------------------------------------------------------------------------------
-- Title      : Phase detector unit wrapper
-- Project    : 
-------------------------------------------------------------------------------
-- File       : phase_detector_unit.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-08-22
-- Last update: 2019-08-28
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-08-22  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity phase_detector_unit is
  generic (
    resource_type : string := "MMCME"
    );
  port (
    clk              : in  std_logic;
    clk_to_follow    : in  std_logic;
    data_in_p        : in  std_logic;
    psen_p           : out std_logic;
    psincdec_p       : out std_logic;
    psdone_p         : in  std_logic;
    -- debug
    phase_up_raw_o   : out std_logic;
    phase_down_raw_o : out std_logic
    );
end entity phase_detector_unit;

architecture rtl of phase_detector_unit is

  signal phase_up       : std_logic;
  signal phase_down     : std_logic;
  signal phase_up_raw   : std_logic;
  signal phase_down_raw : std_logic;
  signal phase_down_dbg : std_logic;
  signal phase_up_dbg   : std_logic;
  -- signal time_counter : std_logic_vector(31 downto 0);
  -- signal phase_counter : std_logic_vector(31 downto 0);

  -- attribute mark_debug                   : string;
  -- attribute mark_debug of phase_up_raw   : signal is "true";
  -- attribute mark_debug of phase_down_raw : signal is "true";
  -- attribute mark_debug of phase_down_dbg : signal is "true";
  -- attribute mark_debug of phase_up_dbg   : signal is "true";

begin  -- architecture rtl

  phase_detector_1 : entity work.phase_detector
    port map (
      data_in => data_in_p,
      sys_clk => clk_to_follow,
      x       => phase_up_raw,
      y       => phase_down_raw
      );

  phase_shift_filter_1 : entity work.phase_shift_filter
    generic map (
      threshold             => 10,
      bit_num_time_interval => 7
      )
    port map (
      sys_clk        => clk,
      phase_up_raw   => phase_up_raw,
      phase_down_raw => phase_down_raw,
      phase_up       => phase_up,
      phase_down     => phase_down
     -- debug
     -- time_counter   => time_counter,
     -- phase_counter  => phase_counter
      );

  ps_controller_1 : entity work.ps_controller
    generic map (
      resource_type => resource_type
      )
    port map (
      clk        => clk,
      phase_up   => phase_up, 
      phase_down => phase_down,
      psclk      => open,
      psen       => psen_p,
      psincdec   => psincdec_p,
      psdone     => psdone_p
      );

  -- phase_down_dbg <= phase_down;
  -- phase_up_dbg   <= phase_up;

  phase_up_raw_o   <= phase_up_raw;
  phase_down_raw_o <= phase_down_raw;

end architecture rtl;
