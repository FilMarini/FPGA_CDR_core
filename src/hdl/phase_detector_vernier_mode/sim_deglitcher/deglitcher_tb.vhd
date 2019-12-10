-------------------------------------------------------------------------------
-- Title      : Testbench for design "deglitcher"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : deglitcher_tb.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-12-02
-- Last update: 2019-12-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-02  1.0      filippo Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------

entity deglitcher_tb is

end entity deglitcher_tb;

-------------------------------------------------------------------------------

architecture behav of deglitcher_tb is

  -- component generics
  constant g_stable_threshold : positive := 16;

  -- component ports
  signal rst_i             : std_logic;
  signal input_i           : std_logic;
  signal counter_i         : std_logic_vector(31 downto 0);
  signal calc_en_i         : std_logic;
  signal phase_tag_o       : std_logic_vector(31 downto 0);
  signal phase_tag_ready_o : std_logic;
  signal n_cycle_o         : std_logic_vector(15 downto 0);
  signal n_cycle_ready_o   : std_logic;

  -- clock
  signal ls_clk_i : std_logic := '1';

  -- signals
  signal u_counter : unsigned(31 downto 0);
  signal s_signals : std_logic_vector(225 downto 0);

begin  -- architecture behav

  -- component instantiation
  DUT : entity work.deglitcher
    generic map (
      g_stable_threshold => g_stable_threshold)
    port map (
      ls_clk_i          => ls_clk_i,
      rst_i             => rst_i,
      input_i           => input_i,
      counter_i         => counter_i,
      calc_en_i         => calc_en_i,
      phase_tag_o       => phase_tag_o,
      phase_tag_ready_o => phase_tag_ready_o);

  n_cycle_generator_1 : entity work.n_cycle_generator
    port map (
      ls_clk_i             => ls_clk_i,
      rst_i                => rst_i,
      phase_tag_A_in       => phase_tag_o,
      phase_tag_A_ready_in => phase_tag_ready_o,
      phase_tag_B_in       => phase_tag_o,
      phase_tag_B_ready_in => phase_tag_ready_o,
      n_cycle_o            => n_cycle_o,
      n_cycle_ready_o      => n_cycle_ready_o);

  -- clock generation
  ls_clk_i <= not ls_clk_i after 16 ns;

  -----------------------------------------------------------------------------
  -- Counter
  -----------------------------------------------------------------------------
  p_counter_proc : process (ls_clk_i, rst_i) is
  begin  -- process p_counter_proc
    if rst_i = '1' then                 -- asynchronous reset (active high)
      u_counter <= (others => '0');
    elsif rising_edge(ls_clk_i) then    -- rising clock edge
      u_counter <= u_counter + 1;
    end if;
  end process p_counter_proc;

  counter_i <= std_logic_vector(u_counter);

  -----------------------------------------------------------------------------
  -- sampled clock simulation
  -----------------------------------------------------------------------------
  s_signals <= "0000000000000000000100010010101110111111111111111111111111111111111111111101110011010000100000000000000000000000000000000000000000000000001100101000101011111111111111111111111111111111111111111111111111111111111110110001100001";
  p_signals : process
  begin  -- process p_signals
    rst_i     <= '1';
    calc_en_i <= '0';
    input_i   <= '0';
    wait for 50 ns;
    rst_i     <= '0';
    wait for 50 ns;
    calc_en_i <= '1';
    while true loop
      for i in s_signals'range loop
        wait until rising_edge(ls_clk_i);
        input_i <= s_signals(i);
      end loop;  -- i
    end loop;
    wait;
  end process p_signals;



end architecture behav;

-------------------------------------------------------------------------------

-- configuration deglitcher_tb_behav_cfg of deglitcher_tb is
--   for behav
--   end for;
-- end deglitcher_tb_behav_cfg;

-------------------------------------------------------------------------------
