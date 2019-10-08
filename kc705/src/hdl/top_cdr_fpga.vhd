-------------------------------------------------------------------------------
-- Title      : DDS based CDR
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_cdr.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-02
-- Last update: 2019-10-08
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
    sysclk_p_i  : in  std_logic;
    sysclk_n_i  : in  std_logic;
    -- cdrclk_o  : out std_logic;
    cdrclk_p_o  : out std_logic;
    cdrclk_n_o  : out std_logic;
    cdrclk_p_i  : in  std_logic;
    cdrclk_n_i  : in  std_logic;
    cdrclk_jc_o : out std_logic;
    led1_o      : out std_logic;
    led_o       : out std_logic
    );
end entity top_cdr_fpga;

architecture rtl of top_cdr_fpga is

  signal s_sysclk          : std_logic;
  signal s_clk_250         : std_logic;
  signal s_clk_1000        : std_logic;
  signal s_sysclk_locked   : std_logic;
  signal M_i               : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal s_deser_clk       : std_logic_vector(7 downto 0);
  signal s_cdrclk          : std_logic;
  signal s_jc_locked_re_df : std_logic;
  signal s_cdrclk_jc       : std_logic;
  signal s_jc_locked       : std_logic;
  signal s_cdrclk_jc_fwd   : std_logic;
  signal s_jc_locked_re    : std_logic;
  signal s_clk_250_vio     : std_logic;
  signal s_cdrclk_o        : std_logic;

begin  -- architecture rtl
  -----------------------------------------------------------------------------
  -- Input Buffer
  -----------------------------------------------------------------------------
  IBUFDS_inst : IBUFDS
    generic map (
      DIFF_TERM    => false,            -- Differential Termination 
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => s_sysclk,                   -- Buffer output
      I  => sysclk_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => sysclk_n_i  -- Diff_n buffer input (connect directly to top-level port)
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
      clk_out_250_vio => s_clk_250_vio,
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
      ser_clk_o     => s_cdrclk_o
      );

  -----------------------------------------------------------------------------
  -- Output buffer
  -----------------------------------------------------------------------------
  OBUFDS_cdrclk : OBUFDS
    generic map (
      IOSTANDARD => "DEFAULT",          -- Specify the output I/O standard
      SLEW       => "SLOW")             -- Specify the output slew rate
    port map (
      O  => cdrclk_p_o,  -- Diff_p output (connect directly to top-level port)
      OB => cdrclk_n_o,  -- Diff_n output (connect directly to top-level port)
      I  => s_cdrclk_o                  -- Buffer input 
      );
  
  -- OBUF_cdrclk : OBUF
  --   generic map (
  --     DRIVE      => 12,
  --     IOSTANDARD => "DEFAULT",
  --     SLEW       => "SLOW")
  --   port map (
  --     O => cdrclk_o,  -- Buffer output (connect directly to top-level port)
  --     I => s_cdrclk_o              -- Buffer input 
  --     );
  
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
        clk        => s_clk_250_vio,
        probe_out0 => M_i
        );

  end generate G_VIO_GENERATION;

  G_FIXED_M : if not g_gen_vio generate

    M_i <= x"2100000";

  end generate G_FIXED_M;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Recovered Clock
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Input buffer
  -----------------------------------------------------------------------------
  IBUFDS_cdrclk_i : IBUFDS
    generic map (
      DIFF_TERM    => false,            -- Differential Termination 
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => s_cdrclk,                   -- Buffer output
      I  => cdrclk_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => cdrclk_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

  -----------------------------------------------------------------------------
  -- Jitter cleaner
  -----------------------------------------------------------------------------
  jitter_cleaner_1 : entity work.jitter_cleaner
    generic map (
      use_ip => false
      )
    port map (
      clk_in  => s_cdrclk,
      rst_i   => s_jc_locked_re_df,
      clk_out => s_cdrclk_jc,
      locked  => s_jc_locked
      );

  -----------------------------------------------------------------------------
  -- DDR
  -----------------------------------------------------------------------------
  -- ODDR_inst : ODDR
  --   generic map(
  --     DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
  --     INIT         => '0',  -- Initial value for Q port ('1' or '0')
  --     SRTYPE       => "SYNC")           -- Reset Type ("ASYNC" or "SYNC")
  --   port map (
  --     Q  => s_cdrclk_jc_fwd,            -- 1-bit DDR output
  --     C  => s_cdrclk_jc,                -- 1-bit clock input
  --     CE => '1',                -- 1-bit clock enable input
  --     D1 => '1',                        -- 1-bit data input (positive edge)
  --     D2 => '0',                        -- 1-bit data input (negative edge)
  --     R  => '0',        -- 1-bit reset input
  --     S  => s_sysclk_locked                         -- 1-bit set input
  --     );

  -----------------------------------------------------------------------------
  -- Output buffer
  -----------------------------------------------------------------------------
  OBUF_inst : OBUF
    generic map (
      DRIVE      => 12,
      IOSTANDARD => "DEFAULT",
      SLEW       => "SLOW")
    port map (
      O => cdrclk_jc_o,  -- Buffer output (connect directly to top-level port)
      I => s_cdrclk_jc              -- Buffer input 
      );

  -----------------------------------------------------------------------------
  -- MMCM reset control
  -----------------------------------------------------------------------------
  f_edge_detect_1 : entity work.f_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => s_clk_250,
      sig_i => s_jc_locked,
      sig_o => s_jc_locked_re
      );

  double_flop_1 : entity work.double_flop
    generic map (
      g_width    => 1,
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i    => s_clk_250,
      sig_i(0) => s_jc_locked_re,
      sig_o(0) => s_jc_locked_re_df
      );

  -----------------------------------------------------------------------------
  -- LED Control
  -----------------------------------------------------------------------------
  led1_o <= s_jc_locked;



end architecture rtl;
