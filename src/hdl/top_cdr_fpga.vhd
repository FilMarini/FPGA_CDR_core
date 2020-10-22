-------------------------------------------------------------------------------
-- Title      : DDS based CDR
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_cdr.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-02
-- Last update: 2020-10-22
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

use work.freq_utils.all;

library extras;
use extras.synchronizing.all;

library UNISIM;
use UNISIM.vcomponents.all;


entity top_cdr_fpga is
  generic (
    g_gen_vio               : boolean  := false;
    g_check_jc_clk          : boolean  := true;
    g_check_pd              : boolean  := false;
    g_number_of_bits        : positive := 28;
    g_multiplication_factor : positive := 3;
    g_freq_in               : real     := 125.0;
    g_freq_out              : real     := 250.0;
    g_out_phase             : real     := 90.0 
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
    cdrclk_jc_p_o : out std_logic;
    cdrclk_jc_n_o : out std_logic;
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
  signal s_clk_sys           : std_logic;
  signal s_clk_oserdes          : std_logic;
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
  signal s_locked_raw        : std_logic;
  signal s_lock_ctrl         : std_logic;
  signal s_pfd_locked        : std_logic;
  signal s_M                 : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal s_s_M               : std_logic_vector(g_number_of_bits - 1 downto 0);
  signal s_incr_freq_re      : std_logic;
  signal s_clk_to_rec        : std_logic;
  signal s_clk_3125_data     : std_logic;
  signal s_data_to_rec       : std_logic;
  signal s_clk_i             : std_logic;
  signal s_clk_q             : std_logic;
  signal s_clk_cdr           : std_logic;
  signal s_data_pulse        : std_logic;
  signal s_M_change_en       : std_logic;
  signal s_M_incr            : std_logic;
  signal s_sysclk_locked_rst : std_logic;
  signal s_jc_locked_rst     : std_logic;
  signal s_M_ctrl            : std_logic;
  signal s_psen_p            : std_logic;
  signal s_psincdec_p        : std_logic;
  signal s_psdone_p          : std_logic;
  signal s_clk_sample        : std_logic;
  signal s_data              : std_logic;
  signal s_error             : std_logic;
  signal s_error_pulse       : std_logic;
  signal s_prbs_counter      : std_logic_vector(7 downto 0);
  signal i_M_start           : integer;
  signal s_M_start           : std_logic_vector(g_number_of_bits - 1 downto 0);

  attribute mark_debug                   : string;
  attribute mark_debug of s_prbs_counter : signal is "true";
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
      g_bandwidth => "LOW",
      g_clk_out_divide => freq_to_mmcm(g_freq_in)
      )
    port map (
      clk_in     => s_sysclk,
      reset      => '0',
      clk_out0   => s_clk_oserdes,
      clk_out1   => s_clk_sys,
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
      g_number_of_bits        => g_number_of_bits,
      g_multiplication_factor => g_multiplication_factor
      )
    port map (
      clk_i         => s_clk_sys,
      M_i           => s_s_M,           -- M_i if from user, s_M automatic
      mmcm_locked_i => s_sysclk_locked,
      clk_o         => s_deser_clk
      );

  s_sysclk_locked_rst <= not s_sysclk_locked;

  -- Define nominal jump size to start
  -- i_M_start <= freq_to_M(g_freq_in, g_freq_out, g_multiplication_factor, g_number_of_bits);
  i_M_start <= 67108864;
  s_M_start <= std_logic_vector(to_unsigned(i_M_start, g_number_of_bits));

  i_frequency_manager_1 : entity work.frequency_manager
    generic map (
      g_number_of_bits => g_number_of_bits
      )
    port map (
      clk_i            => s_clk_sys,
      rst_i            => s_sysclk_locked_rst,
      ctrl_i           => s_M_ctrl,
      change_freq_en_i => s_M_change_en,
      incr_freq_i      => s_M_incr,
      M_start_i        => s_M_start,
      M_o              => s_M
      );

  -----------------------------------------------------------------------------
  -- OSERDESE
  -----------------------------------------------------------------------------
  i_oserdese_manager_1 : entity work.oserdese_manager
    port map (
      ls_clk_i      => s_clk_sys,
      hs_clk_i      => s_clk_oserdes,
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
  -- i_led_counter_1 : entity work.led_counter
  --   generic map (
  --     g_bit_to_pulse   => 25,
  --     g_number_of_bits => g_number_of_bits
  --     )
  --   port map (
  --     clk_i             => s_clk_sys,
  --     mmcm_locked_i     => s_sysclk_locked,
  --     partial_ser_clk_i => s_deser_clk(0),
  --     led_o             => led_o
  --     );

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

    s_s_M <= M_i;

  end generate G_VIO_GENERATION;

  G_FIXED_M : if not g_gen_vio generate

    vio_DTMD_en <= '1';
    s_s_M       <= s_M;

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
  -- Jitter cleanef
  -----------------------------------------------------------------------------
  i_jitter_cleaner_1 : entity work.jitter_cleaner
    generic map (
      g_use_ip      => false,
      g_bandwidth   => "LOW",
      g_last        => false,
      g_mult_period => freq_to_mmcm(g_freq_out)
      )
    port map (
      clk_in  => s_cdrclk,
      rst_i   => s_jc_locked_re_df,
      clk_out => s_cdrclk_jc,
      locked  => s_jc_locked
      );

  i_i_q_clock_gen_1 : entity work.i_q_clock_gen
    generic map (
      g_bandwidth   => "OPTIMIZED",
      g_last        => true,
      g_mult_period => freq_to_mmcm(g_freq_out),
      g_out_phase   => g_out_phase
      )
    port map (
      clk_in       => s_cdrclk_jc,
      rst_i        => s_jc_locked_re_df,
      clk_i_o      => s_clk_i,
      clk_q_o      => s_clk_q,
      clk_cdr_o    => s_clk_cdr,
      clk_sample_o => s_clk_sample,
      locked       => s_jc_locked_2,
      psen_p_i     => s_psen_p,
      psincdec_p_i => s_psincdec_p,
      psdone_p_o   => s_psdone_p
     -- psen_p_i     => '0',
     -- psincdec_p_i => '0',
     -- psdone_p_o   => open
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
        C  => s_clk_cdr,                -- 1-bit clock input
        CE => s_jc_locked,              -- 1-bit clock enable input
        D1 => '1',                      -- 1-bit data input (positive edge)
        D2 => '0',                      -- 1-bit data input (negative edge)
        R  => s_oddr_reset,             -- 1-bit reset input
        S  => '0'                       -- 1-bit set input
        );

    -----------------------------------------------------------------------------
    -- Output buffer
    -----------------------------------------------------------------------------
    -- OBUF_inst : OBUF
    --   generic map (
    --     DRIVE      => 12,
    --     IOSTANDARD => "DEFAULT",
    --     SLEW       => "SLOW")
    --   port map (
    --     O => cdrclk_jc_o,  -- Buffer output (connect directly to top-level port)
    --     I => s_cdrclk_jc_fwd            -- Buffer input 
    --     );
    OBUFDS_inst : OBUFDS
      generic map (
        IOSTANDARD => "DEFAULT",        -- Specify the output I/O standard
        SLEW       => "SLOW")           -- Specify the output slew rate
      port map (
        O  => cdrclk_jc_p_o,  -- Diff_p output (connect directly to top-level port)
        OB => cdrclk_jc_n_o,  -- Diff_n output (connect directly to top-level port)
        I  => s_cdrclk_jc_fwd           -- Buffer input 
        );

  end generate G_CHECK_CLK_AFTER_JC;

  G_NOT_CHECK_CLK_AFTER_JC : if not g_check_jc_clk generate

    -- cdrclk_jc_o <= s_gpio;
    OBUFDS_inst : OBUFDS
      generic map (
        IOSTANDARD => "DEFAULT",        -- Specify the output I/O standard
        SLEW       => "SLOW")           -- Specify the output slew rate
      port map (
        O  => cdrclk_jc_p_o,  -- Diff_p output (connect directly to top-level port)
        OB => cdrclk_jc_n_o,  -- Diff_n output (connect directly to top-level port)
        I  => '0'                       -- Buffer input 
        );

  end generate G_NOT_CHECK_CLK_AFTER_JC;

  -----------------------------------------------------------------------------
  -- MMCM reset control
  -----------------------------------------------------------------------------
  f_edge_detect_1 : entity work.f_edge_detect
    generic map (
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i => s_clk_sys,
      sig_i => s_jc_locked,
      sig_o => s_jc_locked_re
      );

  double_flop_1 : entity work.double_flop
    generic map (
      g_width    => 1,
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i    => s_clk_sys,
      sig_i(0) => s_jc_locked_re,
      sig_o(0) => s_jc_locked_re_df
      );

  -----------------------------------------------------------------------------
  -- LED Control
  -----------------------------------------------------------------------------
  led_o  <= s_jc_locked;
  led1_o <= s_jc_locked_2;
  led2_o <= s_locked;
  led3_o <= s_data_pulse;

  i_slow_pulse_counter_1 : entity work.slow_pulse_counter
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

  -- s_data_to_rec <= data_to_rec_i;

  IBUF_inst : IBUF
    generic map (
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O => s_data_to_rec,               -- Buffer output
      I => data_to_rec_i  -- Buffer input (connect directly to top-level port)
      );

  -----------------------------------------------------------------------------
  -- Phase and Frequency Detector
  -----------------------------------------------------------------------------
  s_jc_locked_rst <= not s_jc_locked_2;

  i_pfd_1 : entity work.pfd
    generic map (
      g_pd_num_trans => 8
      )
    port map (
      clk_i_i       => s_clk_i,
      clk_q_i       => s_clk_q,
      rst_i         => s_jc_locked_rst,
      en_i          => vio_DTMD_en,
      data_i        => s_data_to_rec,
      locked_o      => open,
      shifting_o    => s_shifting,
      shifting_en_o => s_shifting_en
     --debug
     -- gpio_o        => s_gpio
      );

  i_pfd_manager_1 : entity work.pfd_manager
    generic map (
      g_bit_num         => 7,
      g_act_threshold   => 56,
      g_lock_threshold  => 16,
      g_slock_threshold => 112
      )
    port map (
      clk_i         => s_clk_i,
      rst_i         => s_jc_locked_rst,
      en_i          => '1',
      shifting_i    => s_shifting,
      shifting_en_i => s_shifting_en,
      locked_o      => s_locked_raw,
      lock_ctrl_o   => s_lock_ctrl,
      M_ctrl_o      => s_M_ctrl,
      M_change_en_o => s_M_change_en,
      M_incr_o      => s_M_incr
      );

  -----------------------------------------------------------------------------
  -- Lock Manager
  -----------------------------------------------------------------------------
  i_lock_manager_1 : entity work.lock_manager
    generic map (
      g_threshold_bit => 7
      )
    port map (
      clk_i       => s_clk_i,
      lock_ctrl_i => s_lock_ctrl,
      lock_raw_i  => s_locked_raw,
      lock_o      => s_locked
      );

  -----------------------------------------------------------------------------
  -- Phase alignment
  -----------------------------------------------------------------------------
  i_phase_detector_unit_1 : entity work.phase_detector_unit
    generic map (
      resource_type => "MMCME"
      )
    port map (
      clk              => s_clk_i,
      clk_to_follow    => s_clk_cdr,
      data_in_p        => s_data_to_rec,
      enable_i         => s_locked,
      psen_p           => s_psen_p,
      psincdec_p       => s_psincdec_p,
      psdone_p         => s_psdone_p,
      -- debug
      phase_up_raw_o   => open,
      phase_down_raw_o => open
      );

  -- s_locked <= '0';

  -----------------------------------------------------------------------------
  -- Output Control
  -----------------------------------------------------------------------------
  GEN_PD_CHECK : if g_check_pd generate
    p_sample_output : process (s_clk_sample) is
    begin  -- process p_sample_output
      if rising_edge(s_clk_sample) then  -- rising clock edge
        shifting_en_o <= s_data;
        shifting_o    <= '0';
        s_gpio        <= '0';
      -- shifting_en_o <= s_shifting_en;
      -- shifting_o    <= s_shifting;
      -- s_gpio        <= '0';
      end if;
    end process p_sample_output;
  end generate GEN_PD_CHECK;

  GEN_NO_PD_CHECK : if not g_check_pd generate
    shifting_en_o <= '0';
    shifting_o    <= '0';
    s_gpio        <= '0';
  end generate GEN_NO_PD_CHECK;

  -----------------------------------------------------------------------------
  -- PRBS checker
  -----------------------------------------------------------------------------
  bit_synchronizer_1 : entity extras.bit_synchronizer
    generic map (
      STAGES             => 2,
      RESET_ACTIVE_LEVEL => '1'
      )
    port map (
      Clock  => s_clk_sample,
      Reset  => '0',
      Bit_in => s_data_to_rec,
      Sync   => s_data
      );

  PRBS_ANY_1 : entity work.PRBS_ANY
    generic map (
      CHK_MODE    => true,
      INV_PATTERN => true,
      POLY_LENGHT => 7,
      POLY_TAP    => 6,
      NBITS       => 1
      )
    port map (
      RST         => s_jc_locked_rst,
      CLK         => s_clk_sample,
      DATA_IN(0)  => s_data,
      EN          => '1',
      DATA_OUT(0) => s_error
      );

  i_prbs_counter_1 : entity work.prbs_counter
    port map (
      clk_i     => s_clk_sample,
      rst_i     => s_jc_locked_rst,
      err_i     => s_error,
      locked_i  => s_locked,
      counter_o => s_prbs_counter
      );

  -- slow_pulse_counter_2 : entity work.slow_pulse_counter
  --   generic map (
  --     g_num_bit_threshold => 20
  --     )
  --   port map (
  --     clk_i   => s_clk_sample,
  --     pulse_i => s_error,
  --     pulse_o => s_error_pulse
  --     );

end architecture rtl;
