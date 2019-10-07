-------------------------------------------------------------------------------
-- Title      : DDS based CDR
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_cdr_fpga.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-02
-- Last update: 2019-10-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-02  1.0      filippo Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;


entity top_cdr_fpga is
  generic (
    g_gen_vio        : boolean  := true;
    g_number_of_bits : positive := 28
    );
  port (
    sysclk_i : in  std_logic;
--    M_i      : in  std_logic_vector(31 downto 0);
    cdrclk_o : out std_logic;
    led_o    : out std_logic
    );
end entity top_cdr_fpga;

architecture rtl of top_cdr_fpga is

  signal s_sysclk        : std_logic;
  signal s_clk_250       : std_logic;
  signal s_clk_1000      : std_logic;
  signal s_sysclk_locked : std_logic;
  signal M_i             : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal s_deser_clk     : std_logic_vector(7 downto 0);


begin  -- architecture rtl
  -----------------------------------------------------------------------------
  -- Input buffer
  -----------------------------------------------------------------------------
  IBUF_inst : IBUF
    generic map (
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O => s_sysclk,                    -- Buffer output
      I => sysclk_i  -- Buffer input (connect directly to top-level port)
      );

  -----------------------------------------------------------------------------
  -- Clk Manager
  -----------------------------------------------------------------------------
  clk_manager_cdr : entity work.clk_manager
    port map (
      board_clk       => s_sysclk,
      glbl_rst        => '0',
      locked          => s_sysclk_locked,
      clk_out_250     => s_clk_250,
      clk_out_1000    => s_clk_1000,
      clk_out_200     => open,
      clk_out_125_ps  => open,
      clk_out_125B_ps => open,
      psen_p          => '0',
      psincdec_p      => '0',
      psdone_p        => open
      );

  -----------------------------------------------------------------------------
  -- Phase Wheel Counter
  -----------------------------------------------------------------------------
  phase_weel_counter_1 : entity work.phase_weel_counter
    generic map (
      g_number_of_bits => g_number_of_bits
      )
    port map (
      clk_i         => s_clk_250,
      M_i           => M_i,
      mmcm_locked_i => s_sysclk_locked,
      clk_o         => s_deser_clk
      );

  -----------------------------------------------------------------------------
  -- OSERDESE
  -----------------------------------------------------------------------------
  oserdese_manager_1 : entity work.oserdese_manager
    port map (
      ls_clk_i      => s_clk_250,
      hs_clk_i      => s_clk_1000,
      deser_clk_i   => s_deser_clk,
      mmcm_locked_i => s_sysclk_locked,
      ser_clk_o     => cdrclk_o
      );

  -----------------------------------------------------------------------------
  -- LED Counter
  -----------------------------------------------------------------------------
  led_counter_1 : entity work.led_counter
    generic map (
      g_bit_to_pulse   => 25,
      g_number_of_bits => g_number_of_bits
      )
    port map (
      clk_i             => s_clk_250,
      mmcm_locked_i     => s_sysclk_locked,
      partial_ser_clk_i => s_deser_clk(0),
      led_o             => led_o
      );

  -----------------------------------------------------------------------------
  -- VIO Generation
  -----------------------------------------------------------------------------
  G_VIO_GENERATION : if g_gen_vio generate

    i_vio : entity work.vio_0
      port map (
        clk        => s_clk_250,
        probe_out0 => M_i
        );

  end generate G_VIO_GENERATION;

  G_FIXED_M : if not g_gen_vio generate

    M_i <= x"3000000";

  end generate G_FIXED_M;


end architecture rtl;
