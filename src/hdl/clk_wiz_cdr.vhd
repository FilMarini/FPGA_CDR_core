-------------------------------------------------------------------------------
-- Title      : clk wizard
-- Project    : 
-------------------------------------------------------------------------------
-- File       : clk_wiz.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-05-03
-- Last update: 2019-10-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: MMCM for clock generation 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-05-03  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;


entity clk_wiz_cdr is
  port (
    clk_in     : in  std_logic;         -- 62.5 MHz
    reset      : in  std_logic;
    clk_out0   : out std_logic;         -- 62.5 MHz
    clk_out1   : out std_logic;         -- (20 / 41 * 62.5) MHz
    clk_out2   : out std_logic;         -- 
    clk_out3   : out std_logic;         -- 
    clk_out4   : out std_logic;         -- 
    locked     : out std_logic;
    psen_p     : in  std_logic;
    psincdec_p : in  std_logic;
    psdone_p   : out std_logic
    );
end entity clk_wiz_cdr;

architecture behavioural of clk_wiz_cdr is

  signal clk_fbout           : std_logic;
  signal clk_fbout_in        : std_logic;
  signal clk_fboutb_unused   : std_logic;
  signal clk_out0_in         : std_logic;
  signal clk_out0b_unused    : std_logic;
  signal s_clk_out0          : std_logic;
  signal clk_out1_in         : std_logic;
  signal clk_out1b_unused    : std_logic;
  signal clk_out2_in         : std_logic;
  signal clk_out2b_unused    : std_logic;
  signal clk_out3_in         : std_logic;
  signal clk_out3b_in        : std_logic;
  signal clk_out4_unused     : std_logic;
  signal clk_out5_unused     : std_logic;
  signal clk_out6_unused     : std_logic;
  signal do_unused           : std_logic_vector(15 downto 0);
  signal drdy_unused         : std_logic;
  signal psdone_unused       : std_logic;
  signal clkinstopped_unused : std_logic;
  signal clkfbstopped_unused : std_logic;


begin

  -----------------------------------------------------------------------------
  -- MMCM Instantiation
  -----------------------------------------------------------------------------
  mmcm_adv_inst : MMCME2_ADV
    generic map
    (BANDWIDTH           => "OPTIMIZED",
     COMPENSATION        => "ZHOLD",
     DIVCLK_DIVIDE       => 1,
     CLKFBOUT_MULT_F     => 20.000,
     CLKFBOUT_PHASE      => 0.000,
     CLKOUT0_DIVIDE_F    => 20.000,
     CLKOUT0_PHASE       => 0.000,
     CLKOUT0_DUTY_CYCLE  => 0.500,
     CLKOUT0_USE_FINE_PS => false,
     CLKOUT1_DIVIDE      => 41,
     CLKOUT1_PHASE       => 0.000,
     CLKOUT1_DUTY_CYCLE  => 0.500,
     CLKOUT1_USE_FINE_PS => false,
     CLKOUT2_DIVIDE      => 4,
     CLKOUT2_PHASE       => 0.000,
     CLKOUT2_DUTY_CYCLE  => 0.500,
     CLKOUT2_USE_FINE_PS => false,
     CLKOUT3_DIVIDE      => 16,
     CLKOUT3_PHASE       => 0.000,
     CLKOUT3_DUTY_CYCLE  => 0.500,
     CLKOUT3_USE_FINE_PS => false,
     CLKOUT4_DIVIDE      => 8,
     CLKOUT4_PHASE       => 90.000,
     CLKOUT4_DUTY_CYCLE  => 0.500,
     CLKOUT4_USE_FINE_PS => false,
     CLKIN1_PERIOD       => 5.000,
     REF_JITTER1         => 0.010)
    port map
    -- Output clocks
    (CLKFBOUT     => clk_fbout_in,
     CLKFBOUTB    => clk_fboutb_unused,
     CLKOUT0      => clk_out0_in,
     CLKOUT0B     => clk_out0b_unused,
     CLKOUT1      => clk_out1_in,
     CLKOUT1B     => clk_out1b_unused,
     CLKOUT2      => clk_out2_in,
     CLKOUT2B     => clk_out2b_unused,
     CLKOUT3      => clk_out3_in,
     CLKOUT3B     => clk_out3b_in,
     CLKOUT4      => clk_out4_unused,
     CLKOUT5      => clk_out5_unused,
     CLKOUT6      => clk_out6_unused,
     -- Input clock control
     CLKFBIN      => clk_fbout,
     CLKIN1       => clk_in,
     CLKIN2       => '0',
     -- Tied to always select the primary input clock
     CLKINSEL     => '1',
     -- Ports for dynamic reconfiguration
     DADDR        => (others => '0'),
     DCLK         => '0',
     DEN          => '0',
     DI           => (others => '0'),
     DO           => do_unused,
     DRDY         => drdy_unused,
     DWE          => '0',
     -- Ports for dynamic phase shift
     PSCLK        => s_clk_out0,
     PSEN         => psen_p,
     PSINCDEC     => psincdec_p,
     PSDONE       => psdone_p,
     -- Other control and status signals
     LOCKED       => locked,
     CLKINSTOPPED => clkinstopped_unused,
     CLKFBSTOPPED => clkfbstopped_unused,
     PWRDWN       => '0',
     RST          => reset);

  -------------------------------------------------------------------------------
  -- Output buffers
  -------------------------------------------------------------------------------
  clkfbout_buf : BUFG
    port map (
      O => clk_fbout,                   -- 1-bit output: Clock output
      I => clk_fbout_in                 -- 1-bit input: Clock input
      );

  clkout0_buf : BUFGCE
    port map
    (O  => s_clk_out0,
     CE => '1',
     I  => clk_out0_in);

  clk_out0 <= s_clk_out0;               -- to use for PSCLK

  clkout1_buf : BUFGCE
    port map
    (O  => clk_out1,
     CE => '1',
     I  => clk_out1_in);
     
--  BUFR_inst : BUFR
--   generic map (
--      BUFR_DIVIDE => "BYPASS",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
--      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
--   )
--   port map (
--      O => clk_out1,     -- 1-bit output: Clock output port
--      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
--      CLR => '0', -- 1-bit input: Active high, asynchronous clear (Divided modes only)
--      I => clk_out1_in      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
--   );

  clkout2_buf : BUFGCE
    port map
    (O  => clk_out2,
     CE => '1',
     I  => clk_out2_in);

  clkout3_buf : BUFGCE
    port map
    (O  => clk_out3,
     CE => '1',
     I  => clk_out3_in);

  clkout4_buf : BUFGCE
    port map
    (O  => clk_out4,
     CE => '1',
     I  => clk_out3b_in);


end architecture behavioural;
