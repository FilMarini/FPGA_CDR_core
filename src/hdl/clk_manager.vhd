-------------------------------------------------------------------------------
-- Title      : clk manager
-- Project    : 
-------------------------------------------------------------------------------
-- File       : clk_manager.vhd
-- Author     : Filippo Marini   <filippo.marini@pd.infn.it>
-- Company    : Universita degli studi di Padova
-- Created    : 2019-05-03
-- Last update: 2019-10-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Clock manager 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Universita degli studi di Padova
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-05-03  1.0      filippo Created
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity clk_manager is
  generic (
    g_board : string := "KC705"
    );
  port (
    board_clk       : in  std_logic;
    glbl_rst        : in  std_logic;
    locked          : out std_logic;
    clk_out_250     : out std_logic;
    clk_out_1000    : out std_logic;
    clk_out_200     : out std_logic;
    clk_out_125_ps  : out std_logic;
    clk_out_125B_ps : out std_logic;
    psen_p          : in  std_logic;
    psincdec_p      : in  std_logic;
    psdone_p        : out std_logic
    );
end entity clk_manager;

architecture rtl of clk_manager is

  ------------------------------------------------------------------------------
  -- Component declaration for the synchroniser
  ------------------------------------------------------------------------------
  component tri_mode_ethernet_mac_0_sync_block
    port (
      clk      : in  std_logic;
      data_in  : in  std_logic;
      data_out : out std_logic
      );
  end component;

  -- signal declaration
  signal locked_int    : std_logic;
  signal locked_sync   : std_logic;
  signal locked_edge   : std_logic;
  signal locked_reg    : std_logic;
  signal mmcm_reset_in : std_logic;


begin  -- architecture rtl

  -- detect a falling edge on locked (after resyncing to this domain)
  -- lock_sync : tri_mode_ethernet_mac_0_sync_block
  --   port map (
  --     clk      => board_clk,
  --     data_in  => locked_int,
  --     data_out => locked_sync
  --     );

  -- -- for the falling edge detect we want to force this at power on so init the flop to 1
  -- dcm_lock_detect_p : process(board_clk)
  -- begin
  --   if board_clk'event and board_clk = '1' then
  --     locked_reg  <= locked_sync;
  --     locked_edge <= locked_reg and not locked_sync;
  --   end if;
  -- end process dcm_lock_detect_p;

  -- mmcm_reset_in <= glbl_rst or locked_edge;

  mmcm_reset_in <= glbl_rst;

  -----------------------------------------------------------------------------
  -- MMCM Clock generator
  -----------------------------------------------------------------------------
  G_GCU_CLK_MAN : if g_board = "GCU" generate
    clock_generator : entity work.clk_wiz
      generic map (
        g_mult_f => 8.000
        )
      port map (
        clk_in     => board_clk,
        reset      => glbl_rst,
        clk_out0   => clk_out_1000,
        clk_out1   => clk_out_250,
        clk_out2   => clk_out_200,
        clk_out3   => clk_out_125_ps,
        clk_out4   => clk_out_125B_ps,
        locked     => locked_int,
        psen_p     => psen_p,
        psincdec_p => psincdec_p,
        psdone_p   => psdone_p
        );
  end generate G_GCU_CLK_MAN;

  G_KC705_CLK_MAN : if g_board = "KC705" generate
    clock_generator : entity work.clk_wiz
      generic map (
        g_mult_f => 5.000
        )
      port map (
        clk_in     => board_clk,
        reset      => glbl_rst,
        clk_out0   => clk_out_1000,
        clk_out1   => clk_out_250,
        clk_out2   => clk_out_200,
        clk_out3   => clk_out_125_ps,
        clk_out4   => clk_out_125B_ps,
        locked     => locked_int,
        psen_p     => psen_p,
        psincdec_p => psincdec_p,
        psdone_p   => psdone_p
        );
  end generate G_KC705_CLK_MAN;

  locked <= locked_int;

end architecture rtl;
