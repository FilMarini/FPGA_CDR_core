-------------------------------------------------------------------------------
-- Title      : MMCM jitter cleaner
-- Project    : 
-------------------------------------------------------------------------------
-- File       : i_q_clock_gen.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-08-19
-- Last update: 2020-10-23
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-08-19  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;

entity i_q_clock_gen is
  generic (
    g_bandwidth : string  := "LOW";
    g_last      : boolean := true;
    g_mult_period : real := 4.0;
    g_out_phase : real := 90.0
    );
  port (
    clk_in       : in  std_logic;
    rst_i        : in  std_logic;
    clk_i_o      : out std_logic;
    clk_q_o      : out std_logic;
    clk_cdr_o    : out std_logic;
    clk_sample_o : out std_logic;
    locked       : out std_logic;
    psen_p_i     : in  std_logic;
    psincdec_p_i : in  std_logic;
    psdone_p_o   : out std_logic
    );
end entity i_q_clock_gen;

architecture rtl of i_q_clock_gen is

  signal out_clk_fb     : std_logic;
  signal in_clk_fb      : std_logic;
  signal s_clk_i_bufg   : std_logic;
  signal s_clk_i        : std_logic;
  signal s_clk_q_bufg   : std_logic;
  signal s_clk_cdr_bufg : std_logic;
  signal s_clk_sample_bufg : std_logic;
  signal s_locked       : std_logic;

  component clk_wiz_0
    port
      (                                 -- Clock in ports
        -- Clock out ports
        clk_out1 : out std_logic;
        -- Status and control signals
        locked   : out std_logic;
        clk_in1  : in  std_logic
        );
  end component;


begin  -- architecture rtl

  MMCME2_ADV_inst : MMCME2_ADV
    generic map (
      BANDWIDTH            => g_bandwidth,  -- Jitter programming (OPTIMIZED, HIGH, LOW)
      CLKFBOUT_MULT_F      => g_mult_period,  -- Multiply value for all CLKOUT (2.000-64.000).
      CLKFBOUT_PHASE       => 0.0,  -- Phase offset in degrees of CLKFB (-360.000-360.000).
      -- CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      CLKIN1_PERIOD        => g_mult_period,
      CLKIN2_PERIOD        => 0.0,
      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
      CLKOUT1_DIVIDE       => integer(g_mult_period),
      CLKOUT2_DIVIDE       => integer(g_mult_period),
      CLKOUT3_DIVIDE       => integer(g_mult_period),
      CLKOUT4_DIVIDE       => 1,
      CLKOUT5_DIVIDE       => 1,
      CLKOUT6_DIVIDE       => 1,
      CLKOUT0_DIVIDE_F     => g_mult_period,  -- Divide amount for CLKOUT0 (1.000-128.000).
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
      CLKOUT0_DUTY_CYCLE   => 0.5,
      CLKOUT1_DUTY_CYCLE   => 0.5,
      CLKOUT2_DUTY_CYCLE   => 0.5,
      CLKOUT3_DUTY_CYCLE   => 0.5,
      CLKOUT4_DUTY_CYCLE   => 0.5,
      CLKOUT5_DUTY_CYCLE   => 0.5,
      CLKOUT6_DUTY_CYCLE   => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT0_PHASE        => 0.0,
      CLKOUT1_PHASE        => 90.0,
      CLKOUT2_PHASE        => 0.0,
      CLKOUT3_PHASE        => g_out_phase,
      CLKOUT4_PHASE        => 0.0,
      CLKOUT5_PHASE        => 0.0,
      CLKOUT6_PHASE        => 0.0,
      CLKOUT4_CASCADE      => false,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      COMPENSATION         => "ZHOLD",  -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
      DIVCLK_DIVIDE        => 1,        -- Master division value (1-106)
      -- REF_JITTER: Reference input jitter in UI (0.000-0.999).
      REF_JITTER1          => 0.5,
      REF_JITTER2          => 0.0,
      STARTUP_WAIT         => false,  -- Delays DONE until MMCM is locked (FALSE, TRUE)
      -- Spread Spectrum: Spread Spectrum Attributes
      SS_EN                => "FALSE",  -- Enables spread spectrum (FALSE, TRUE)
      SS_MODE              => "CENTER_HIGH",  -- CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
      SS_MOD_PERIOD        => 10000,  -- Spread spectrum modulation period (ns) (VALUES)
      -- USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
      CLKFBOUT_USE_FINE_PS => false,
      CLKOUT0_USE_FINE_PS  => false,
      CLKOUT1_USE_FINE_PS  => false,
      CLKOUT2_USE_FINE_PS  => true,
      CLKOUT3_USE_FINE_PS  => true,
      CLKOUT4_USE_FINE_PS  => false,
      CLKOUT5_USE_FINE_PS  => false,
      CLKOUT6_USE_FINE_PS  => false
      )
    port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0      => s_clk_i_bufg,     -- 1-bit output: CLKOUT0
      CLKOUT0B     => open,             -- 1-bit output: Inverted CLKOUT0
      CLKOUT1      => s_clk_q_bufg,     -- 1-bit output: CLKOUT1
      CLKOUT1B     => open,             -- 1-bit output: Inverted CLKOUT1
      CLKOUT2      => s_clk_cdr_bufg,   -- 1-bit output: CLKOUT2
      CLKOUT2B     => open,             -- 1-bit output: Inverted CLKOUT2
      CLKOUT3      => s_clk_sample_bufg,    -- 1-bit output: CLKOUT3
      CLKOUT3B     => open,             -- 1-bit output: Inverted CLKOUT3
      CLKOUT4      => open,             -- 1-bit output: CLKOUT4
      CLKOUT5      => open,             -- 1-bit output: CLKOUT5
      CLKOUT6      => open,             -- 1-bit output: CLKOUT6
      -- DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
      DO           => open,             -- 16-bit output: DRP data
      DRDY         => open,             -- 1-bit output: DRP ready
      -- Dynamic Phase Shift Ports: 1-bit (each) output: Ports used for dynamic phase shifting of the outputs
      PSDONE       => psdone_p_o,       -- 1-bit output: Phase shift done
      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT     => out_clk_fb,       -- 1-bit output: Feedback clock
      CLKFBOUTB    => open,             -- 1-bit output: Inverted CLKFBOUT
      -- Status Ports: 1-bit (each) output: MMCM status ports
      CLKFBSTOPPED => open,             -- 1-bit output: Feedback clock stopped
      CLKINSTOPPED => open,             -- 1-bit output: Input clock stopped
      LOCKED       => s_locked,         -- 1-bit output: LOCK
      -- Clock Inputs: 1-bit (each) input: Clock inputs
      CLKIN1       => clk_in,           -- 1-bit input: Primary clock
      CLKIN2       => '0',              -- 1-bit input: Secondary clock
      -- Control Ports: 1-bit (each) input: MMCM control ports
      CLKINSEL     => '1',  -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
      PWRDWN       => '0',              -- 1-bit input: Power-down
      RST          => rst_i,            -- 1-bit input: Reset
      -- DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
      DADDR        => (others => '0'),  -- 7-bit input: DRP address
      DCLK         => '0',              -- 1-bit input: DRP clock
      DEN          => '0',              -- 1-bit input: DRP enable
      DI           => (others => '0'),  -- 16-bit input: DRP data
      DWE          => '0',              -- 1-bit input: DRP write enable
      -- Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
      PSCLK        => s_clk_i,          -- 1-bit input: Phase shift clock
      PSEN         => psen_p_i,         -- 1-bit input: Phase shift enable
      PSINCDEC     => psincdec_p_i,  -- 1-bit input: Phase shift increment/decrement
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN      => out_clk_fb        -- 1-bit input: Feedback clock
      );

  -- BUFG_inst : BUFG
  --   port map (
  --     O => in_clk_fb,                 -- 1-bit output: Clock output
  --     I => out_clk_fb                 -- 1-bit input: Clock input
  --     );

  GEN_BUFG : if g_last generate
    i_BUFG_i_clk : BUFG
      port map (
        O => s_clk_i,                   -- 1-bit output: Clock output
        I => s_clk_i_bufg               -- 1-bit input: Clock input
        );

    clk_i_o <= s_clk_i;

    i_BUFG_q_clk : BUFG
      port map (
        O => clk_q_o,                   -- 1-bit output: Clock output
        I => s_clk_q_bufg               -- 1-bit input: Clock input
        );

    i_BUFG_cdr_clk : BUFG
      port map (
        O => clk_cdr_o,                 -- 1-bit output: Clock output
        I => s_clk_cdr_bufg             -- 1-bit input: Clock input
        );

    i_BUFG_sample_clk : BUFG
      port map (
        O => clk_sample_o,              -- 1-bit output: Clock output
        I => s_clk_sample_bufg          -- 1-bit input: Clock input
        );
  end generate GEN_BUFG;

  GEN_NO_BUFG : if not g_last generate
    clk_i_o      <= s_clk_i_bufg;
    clk_q_o      <= s_clk_q_bufg;
    clk_cdr_o    <= s_clk_cdr_bufg;
    clk_sample_o <= s_clk_sample_bufg;
  end generate GEN_NO_BUFG;

  locked <= s_locked;

end architecture rtl;
