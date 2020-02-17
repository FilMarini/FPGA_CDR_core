-------------------------------------------------------------------------------
-- Title      : DDS based CDR
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_cdr.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-02
-- Last update: 2020-02-17
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
    g_gen_vio        : boolean  := false;
    g_check_jc_clk   : boolean  := false;
    g_check_pd       : boolean  := true;
    g_number_of_bits : positive := 28
    );
  port (
    sysclk_p_i    : in  std_logic;
    sysclk_n_i    : in  std_logic;
    data_to_rec_i : in  std_logic;
    -- cdrclk_o  : out std_logic;
    cdrclk_p_o    : out std_logic;
    cdrclk_n_o    : out std_logic;
    cdrclk_p_i    : in  std_logic;
    cdrclk_n_i    : in  std_logic;
    cdrclk_jc_o   : out std_logic;
    led3_o        : out std_logic;
    led2_o        : out std_logic;
    led1_o        : out std_logic;
    led_o         : out std_logic;
    -- debug
    shifting_o    : out std_logic;
    shifting_en_o : out std_logic
    );
end entity top_cdr_fpga;

architecture rtl of top_cdr_fpga is

  signal s_gpio              : std_logic;
  signal s_sysclk            : std_logic;
  signal s_clk_250           : std_logic;
  signal s_clk_1000          : std_logic;
  signal s_clk_625           : std_logic;
  signal s_sysclk_locked     : std_logic;
  signal M_i                 : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal s_deser_clk         : std_logic_vector(7 downto 0);
  signal s_cdrclk            : std_logic;
  signal s_jc_locked_re_df   : std_logic;
  signal s_cdrclk_jc         : std_logic;
  signal s_jc_locked         : std_logic;
  signal s_cdrclk_jc_fwd     : std_logic;
  signal s_jc_locked_re      : std_logic;
  signal s_clk_250_vio       : std_logic;
  signal s_cdrclk_o          : std_logic;
  signal s_oddr_reset        : std_logic;
  signal vio_DTMD_en         : std_logic;
  signal s_clk_625_cdr       : std_logic;
  signal s_clk_about_3125    : std_logic;
  signal s_sysclk_cdr_locked : std_logic;
  signal s_shifting          : std_logic;
  signal s_shifting_en       : std_logic;
  signal s_cdrclk_jc_2       : std_logic;
  signal s_jc_locked_2       : std_logic;
  signal s_locked            : std_logic;
  signal s_pfd_locked        : std_logic;
  signal s_M                 : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal s_incr_freq_re      : std_logic;
  signal s_clk_to_rec        : std_logic;
  signal s_clk_3125_data     : std_logic;
  signal s_data_to_rec       : std_logic;
  signal s_clk_i             : std_logic;
  signal s_clk_q             : std_logic;
  signal s_data_pulse        : std_logic;
  signal s_M_change_en       : std_logic;
  signal s_M_incr            : std_logic;
  signal s_sysclk_locked_rst : std_logic;
  signal s_jc_locked_rst     : std_logic;
  signal s_M_ctrl            : std_logic;

  -- attribute mark_debug             : string;
  -- attribute mark_debug of s_M      : signal is "true";
  -- attribute mark_debug of s_locked : signal is "true";

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
  i_clock_generator : entity work.clk_wiz
    generic map (
      g_bandwidth => "LOW"
      )
    port map (
      clk_in     => s_sysclk,
      reset      => '0',
      clk_out0   => s_clk_1000,
      clk_out1   => s_clk_250,
      clk_out2   => s_clk_250_vio,
      clk_out3   => s_clk_625,
      clk_out4   => open,
      locked     => s_sysclk_locked,
      psen_p     => '0',
      psincdec_p => '0',
      psdone_p   => open
      );

  -----------------------------------------------------------------------------
  -- NCO
  -----------------------------------------------------------------------------
  i_phase_weel_counter_1 : entity work.phase_weel_counter
    generic map (
      g_number_of_bits => g_number_of_bits
      )
    port map (
      clk_i         => s_clk_250,
      M_i           => s_M,             -- M_i if from user, s_M automatic
      mmcm_locked_i => s_sysclk_locked,
      clk_o         => s_deser_clk
      );

  s_sysclk_locked_rst <= not s_sysclk_locked;

  frequency_manager_1 : entity work.frequency_manager
    generic map (
      g_number_of_bits => g_number_of_bits
      )
    port map (
      clk_i            => s_clk_250,
      rst_i            => s_sysclk_locked_rst,
      ctrl_i           => s_M_ctrl,
      change_freq_en_i => s_M_change_en,
      incr_freq_i      => s_M_incr,
      M_start_i        => x"4000200",
      M_o              => s_M
      );

  -----------------------------------------------------------------------------
  -- OSERDESE
  -----------------------------------------------------------------------------
  i_oserdese_manager_1 : entity work.oserdese_manager
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
  i_led_counter_1 : entity work.led_counter
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
        probe_out0 => M_i,
        probe_out1 => vio_DTMD_en
        );

  end generate G_VIO_GENERATION;

  G_FIXED_M : if not g_gen_vio generate

    M_i         <= x"4000001";
    vio_DTMD_en <= '1';

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
  i_jitter_cleaner_1 : entity work.jitter_cleaner
    generic map (
      g_use_ip    => false,
      g_bandwidth => "LOW",
      g_last      => false
      )
    port map (
      clk_in  => s_cdrclk,
      rst_i   => s_jc_locked_re_df,
      clk_out => s_cdrclk_jc,
      locked  => s_jc_locked
      );

  i_i_q_clock_gen_1: entity work.i_q_clock_gen
    generic map (
      g_bandwidth => "OPTIMIZED",
      g_last      => true
      )
    port map (
      clk_in       => s_cdrclk_jc,
      rst_i        => s_jc_locked_re_df,
      clk_i_o      => s_clk_i,
      clk_q_o      => s_clk_q,
      clk_cdr_o    => s_clk_cdr,
      locked       => s_jc_locked_2,
      psen_p_i     => s_psen_p,
      psincdec_p_i => s_psincdec_p,
      psdone_p_o   => s_psdone_p
      );

  -- s_cdrclk_jc_2 <= s_cdrclk_jc;
  -- s_jc_locked_2 <= s_jc_locked;

  -----------------------------------------------------------------------------
  -- Check Jitter Cleaned Recovered Clock
  -----------------------------------------------------------------------------
  G_CHECK_CLK_AFTER_JC : if g_check_jc_clk generate

    -----------------------------------------------------------------------------
    -- DDR
    -----------------------------------------------------------------------------
    s_oddr_reset <= not s_sysclk_locked;

    ODDR_inst : ODDR
      generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
        INIT         => '0',  -- Initial value for Q port ('1' or '0')
        SRTYPE       => "SYNC")         -- Reset Type ("ASYNC" or "SYNC")
      port map (
        Q  => s_cdrclk_jc_fwd,          -- 1-bit DDR output
        C  => s_clk_i,                  -- 1-bit clock input
        CE => s_jc_locked,              -- 1-bit clock enable input
        D1 => '1',                      -- 1-bit data input (positive edge)
        D2 => '0',                      -- 1-bit data input (negative edge)
        R  => s_oddr_reset,             -- 1-bit reset input
        S  => '0'                       -- 1-bit set input
        );

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
        I => s_cdrclk_jc_fwd            -- Buffer input 
        );

  end generate G_CHECK_CLK_AFTER_JC;

  G_NOT_CHECK_CLK_AFTER_JC : if not g_check_jc_clk generate

    cdrclk_jc_o <= s_gpio;

  end generate G_NOT_CHECK_CLK_AFTER_JC;

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
  led1_o <= s_jc_locked_2;
  led2_o <= s_locked;
  led3_o <= s_data_pulse;

  slow_pulse_counter_1 : entity work.slow_pulse_counter
    generic map (
      g_num_bit_threshold => 24
      )
    port map (
      clk_i   => s_clk_i,
      pulse_i => s_data_to_rec,
      pulse_o => s_data_pulse
      );
  -----------------------------------------------------------------------------
  -- Clk Manager for clk to reconstruct to feed the CDR
  -----------------------------------------------------------------------------
  -- BUFIO_inst : BUFIO
  --   port map (
  --     O => s_clk_to_rec,  -- 1-bit output: Clock output (connect to I/O clock loads).
  --     I => clk_to_rec_i   -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
  --     );

  s_data_to_rec <= data_to_rec_i;

  -----------------------------------------------------------------------------
  -- Phase and Frequency Detector
  -----------------------------------------------------------------------------
  s_jc_locked_rst <= not s_jc_locked_2;

  pfd_1 : entity work.pfd
    generic map (
      g_pd_num_trans => 10
      )
    port map (
      clk_i_i       => s_clk_i,
      clk_q_i       => s_clk_q,
      rst_i         => s_jc_locked_rst,
      en_i          => vio_DTMD_en,
      data_i        => s_data_to_rec,
      locked_o      => s_pfd_locked,
      shifting_o    => s_shifting,
      shifting_en_o => s_shifting_en
     --debug
     -- gpio_o        => s_gpio
      );

  pfd_manager_1 : entity work.pfd_manager
    generic map (
      g_bit_num         => 7,
      g_act_threshold   => 56,
      g_lock_threshold  => 8,
      g_slock_threshold => 112
      )
    port map (
      clk_i         => s_clk_i,
      rst_i         => s_jc_locked_rst,
      en_i          => '1',
      shifting_i    => s_shifting,
      shifting_en_i => s_shifting_en,
      locked_o      => s_locked,
      M_ctrl_o      => s_M_ctrl,
      M_change_en_o => s_M_change_en,
      M_incr_o      => s_M_incr
      );

  -----------------------------------------------------------------------------
  -- Phase alignment
  -----------------------------------------------------------------------------
  phase_detector_unit_1: entity work.phase_detector_unit -- manca l' enable!!
    generic map (
      resource_type => "MMCME"
      )
    port map (
      clk              => s_clk_i,
      clk_to_follow    => s_clk_cdr,
      data_in_p        => s_data_to_rec,
      psen_p           => s_psen_p,
      psincdec_p       => s_psincdec_p,
      psdone_p         => s_psdone_p,
      -- debug
      phase_up_raw_o   => open,
      phase_down_raw_o => open
      );

  -----------------------------------------------------------------------------
  -- Output Control
  -----------------------------------------------------------------------------

  GEN_PD_CHECK : if g_check_pd generate
    shifting_en_o <= s_M_change_en;
    shifting_o    <= s_M_incr;
    -- shifting_en_o <= s_shifting_en;
    -- shifting_o    <= s_shifting;
    s_gpio        <= s_locked;
  end generate GEN_PD_CHECK;

  GEN_NO_PD_CHECK : if not g_check_pd generate
    shifting_en_o <= '0';
    shifting_o    <= '0';
    s_gpio        <= '0';
  end generate GEN_NO_PD_CHECK;

end architecture rtl;
