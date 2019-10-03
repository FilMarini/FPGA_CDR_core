-------------------------------------------------------------------------------
-- Title      : DDS based CDR
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top_cdr.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-10-02
-- Last update: 2019-10-03
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-10-02  1.0      filippo	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;


entity top_cdr is
  port (
    sysclk_i : in  std_logic;
    M_i      : in  std_logic_vector(31 downto 0);
    cdrclk_o : out std_logic
    );
end entity top_cdr;

architecture rtl of top_cdr is

  type t_uns_counter is array (3 downto 0) of unsigned (31 downto 0);
  type t_std_counter is array (3 downto 0) of std_logic_vector (31 downto 0);

  signal s_sysclk_locked : std_logic;
  signal s_clk_250 : std_logic;
  signal s_clk_500 : std_logic;
  signal u_phase_wheel_counter : t_uns_counter;
  signal s_phase_wheel_counter : t_std_counter;
  signal u_vector_rst : t_uns_counter;
  signal s_clk : std_logic_vector(3 downto 0);
  signal u_M : unsigned(31 downto 0);
  signal M : integer;
  signal u_base, u_double_base : unsigned(31 downto 0);

begin  -- architecture rtl

  u_M <= unsigned(M_i);
  M <= to_integer(u_M);

  u_base <= shift_right(u_M, 2);
  u_double_base <= shift_right(u_M, 1);

  u_vector_rst(0) <= (others => '0');
  u_vector_rst(1) <= u_base;
  u_vector_rst(2) <= u_double_base;
  u_vector_rst(3) <= u_double_base + u_base;

  -----------------------------------------------------------------------------
  -- Clk Manager
  -----------------------------------------------------------------------------
  clk_manager_cdr : entity work.clk_manager
    port map (
      board_clk       => sysclk_i,
      glbl_rst        => '0',
      locked          => s_sysclk_locked,
      clk_out_250     => s_clk_250,
      clk_out_500     => s_clk_500,
      clk_out_200     => open,
      clk_out_125_ps  => open,
      clk_out_125B_ps => open,
      psen_p          => '0',
      psincdec_p      => '0',
      psdone_p        => open 
      );

  G_PHASE_WHEEL_COUNTER: for i in 0 to 3 generate

    p_phase_wheel_counter: process (s_clk_250, s_sysclk_locked) is
    begin  -- process p_phase_wheel_counter
      if s_sysclk_locked = '0' then     -- asynchronous reset (active low)
        u_phase_wheel_counter(i) <= u_vector_rst(i);
      elsif rising_edge(s_clk_250) then  -- rising clock edge
        u_phase_wheel_counter(i) <= u_phase_wheel_counter(i) + M;
      end if;
    end process p_phase_wheel_counter;

    s_phase_wheel_counter(i) <= std_logic_vector(u_phase_wheel_counter(i));

    s_clk(i) <= s_phase_wheel_counter(i)(31);

  end generate G_PHASE_WHEEL_COUNTER;

  OSERDESE2_inst : OSERDESE2
   generic map (
      DATA_RATE_OQ => "DDR",   -- DDR, SDR
      DATA_RATE_TQ => "DDR",   -- DDR, BUF, SDR
      DATA_WIDTH => 4,         -- Parallel data width (2-8,10,14)
      INIT_OQ => '0',          -- Initial value of OQ output (1'b0,1'b1)
      INIT_TQ => '0',          -- Initial value of TQ output (1'b0,1'b1)
      SERDES_MODE => "MASTER", -- MASTER, SLAVE
      SRVAL_OQ => '0',         -- OQ output value when SR is used (1'b0,1'b1)
      SRVAL_TQ => '0',         -- TQ output value when SR is used (1'b0,1'b1)
      TBYTE_CTL => "FALSE",    -- Enable tristate byte operation (FALSE, TRUE)
      TBYTE_SRC => "FALSE",    -- Tristate byte source (FALSE, TRUE)
      TRISTATE_WIDTH => 4      -- 3-state converter width (1,4)
   )
   port map (
      OFB => open,             -- 1-bit output: Feedback path for data
      OQ => cdrclk_o,               -- 1-bit output: Data path output
      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
      SHIFTOUT1 => open,
      SHIFTOUT2 => open,
      TBYTEOUT => open,   -- 1-bit output: Byte group tristate
      TFB => open,             -- 1-bit output: 3-state control
      TQ => open,               -- 1-bit output: 3-state control
      CLK => s_clk_500,             -- 1-bit input: High speed clock
      CLKDIV => s_clk_250,       -- 1-bit input: Divided clock
      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      D1 => s_clk(0),
      D2 => s_clk(1),
      D3 => s_clk(2),
      D4 => s_clk(3),
      D5 => '0',
      D6 => '0',
      D7 => '0',
      D8 => '0',
      OCE => '1',             -- 1-bit input: Output data clock enable
      RST => not s_sysclk_locked,             -- 1-bit input: Reset
      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      SHIFTIN1 => '0',
      SHIFTIN2 => '0',
      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0',
      TBYTEIN => '0',     -- 1-bit input: Byte group tristate
      TCE => '0'              -- 1-bit input: 3-state clock enable
   );


end architecture rtl;
