----------------------------------------------------------------------------------
-- Company:   INFN 
-- Engineer:  
-- Module Name:    GCU_utils - rtl 
-- Project Name:   GCU
-- Target Devices: all
--
-- Description: VHDL utility file
--
-- Version: V0.0 file created
--
----------------------------------------------------------------------------------
-----------------------------------Double flopping--------------------------------
----------------------------------------------------------------------------------
-- Description: double flopping stage. This is a synchronization stage 
-- whose purpose is to reduce metastability problems.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity double_flop is
  generic(g_width    : integer := 1;
          g_clk_rise : string  := "TRUE"
          );
  port(
    clk_i : in  std_logic;
    sig_i : in  std_logic_vector(g_width -1 downto 0);
    sig_o : out std_logic_vector(g_width -1 downto 0)
    );
end double_flop;
architecture rtl of double_flop is

  signal s_1 : std_logic_vector(g_width -1 downto 0);

begin

-------------------rise edge process------------------
  G1 : if (g_clk_rise = "TRUE") generate
  begin
    process(clk_i)
    begin
      if rising_edge(clk_i) then
        s_1   <= sig_i;
        sig_o <= s_1;
      end if;
    end process;
  end generate G1;

-------------------fall edge process------------------
  G2 : if (g_clk_rise = "FALSE") generate
  begin
    process(clk_i)
    begin
      if falling_edge(clk_i) then
        s_1   <= sig_i;
        sig_o <= s_1;
      end if;
    end process;
  end generate G2;

end rtl;

----------------------------------------------------------------------------------
-----------------------------------Triple flopping--------------------------------
----------------------------------------------------------------------------------
-- Description: double flopping stage. This is a synchronization stage 
-- whose purpose is to reduce metastability problems.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity triple_flop is
  generic(g_width    : integer := 1;
          g_clk_rise : string  := "TRUE"
          );
  port(
    clk_i : in  std_logic;
    sig_i : in  std_logic_vector(g_width -1 downto 0);
    sig_o : out std_logic_vector(g_width -1 downto 0)
    );
end triple_flop;
architecture rtl of triple_flop is

  signal s_1 : std_logic_vector(g_width -1 downto 0);
  signal s_2 : std_logic_vector(g_width -1 downto 0);

begin

-------------------rise edge process------------------
  G1 : if (g_clk_rise = "TRUE") generate
  begin
    process(clk_i)
    begin
      if rising_edge(clk_i) then
        s_1   <= sig_i;
        s_2   <= s_1;
        sig_o <= s_2;
      end if;
    end process;
  end generate G1;

-------------------fall edge process------------------
  G2 : if (g_clk_rise = "FALSE") generate
  begin
    process(clk_i)
    begin
      if falling_edge(clk_i) then
        s_1   <= sig_i;
        s_2   <= s_1;
        sig_o <= s_2;
      end if;
    end process;
  end generate G2;

end rtl;

----------------------------------------------------------------------------------
-------------------------------Rising edge detection------------------------------
----------------------------------------------------------------------------------
-- Description: rising edge detection.
-- Generate a Tclk wide pulse on the input rising edge
--
--                  
--             _   _   _   _   _   _   _  
-- clk_i     _/ \_/ \_/ \_/ \_/ \_/ \_/ \...
--                      _________________...
-- sig_i     __________/                     
--                          ___      
-- sig_o     ______________/   \_________...
--                                  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity r_edge_detect is
  generic(g_clk_rise : string := "TRUE"
          );
  port(
    clk_i : in  std_logic;
    sig_i : in  std_logic;
    sig_o : out std_logic
    );
end r_edge_detect;

architecture rtl of r_edge_detect is

  signal s_int : std_logic;

begin
  G1 : if (g_clk_rise = "TRUE") generate
  begin
    process(clk_i)
    begin
      if rising_edge(clk_i) then
        s_int <= sig_i;
        if s_int = '0' and sig_i = '1' then
          sig_o <= '1';
        else
          sig_o <= '0';
        end if;
      end if;
    end process;
  end generate G1;

  G2 : if (g_clk_rise = "FALSE") generate
  begin
    process(clk_i)
    begin
      if falling_edge(clk_i) then
        s_int <= sig_i;
        if s_int = '0' and sig_i = '1' then
          sig_o <= '1';
        else
          sig_o <= '0';
        end if;
      end if;
    end process;
  end generate G2;

end rtl;

----------------------------------------------------------------------------------
-------------------------------Falling edge detection-----------------------------
----------------------------------------------------------------------------------
-- Description: falling edge detection.
-- Generate a Tclk wide pulse on the input falling edge
--
--                  
--             _   _   _   _   _   _   _  
-- clk_i     _/ \_/ \_/ \_/ \_/ \_/ \_/ \...
--           ______________
-- sig_i                   \_____________...     
--                              ___      
-- sig_o     __________________/   \_____...
--                                  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity f_edge_detect is
  generic(g_clk_rise : string := "TRUE"
          );
  port(
    clk_i : in  std_logic;
    sig_i : in  std_logic;
    sig_o : out std_logic
    );
end f_edge_detect;

architecture rtl of f_edge_detect is

  signal s_int : std_logic;

begin
  G1 : if (g_clk_rise = "TRUE") generate
  begin
    process(clk_i)
    begin
      if rising_edge(clk_i) then
        s_int <= sig_i;
        if s_int = '1' and sig_i = '0' then
          sig_o <= '1';
        else
          sig_o <= '0';
        end if;
      end if;
    end process;
  end generate G1;

  G2 : if (g_clk_rise = "FALSE") generate
  begin
    process(clk_i)
    begin
      if falling_edge(clk_i) then
        s_int <= sig_i;
        if s_int = '1' and sig_i = '0' then
          sig_o <= '1';
        else
          sig_o <= '0';
        end if;
      end if;
    end process;
  end generate G2;

end rtl;
----------------------------------------------------------------------------------
-----------------------------------Set Reset FFD----------------------------------
----------------------------------------------------------------------------------
-- Description: D Flip-Flop with synchronous Set and Reset.
-- It can work both on the rising and falling clock edges by selecting the
-- generic g_clk_rise parameter.
--                  
--           
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity set_reset_ffd is
  generic(g_clk_rise : string := "TRUE"
          );
  port(
    clk_i   : in  std_logic;
    set_i   : in  std_logic;
    reset_i : in  std_logic;
    q_o     : out std_logic
    );
end set_reset_ffd;

architecture rtl of set_reset_ffd is

begin
  G1 : if (g_clk_rise = "TRUE") generate
  begin
    process(clk_i)
    begin
      if rising_edge(clk_i) then
        if (reset_i = '1') then
          q_o <= '0';
        elsif (set_i = '1') then
          q_o <= '1';
        end if;
      end if;
    end process;
  end generate G1;

  G2 : if (g_clk_rise = "FALSE") generate
  begin
    process(clk_i)
    begin
      if falling_edge(clk_i) then
        if (reset_i = '1') then
          q_o <= '0';
        elsif (set_i = '1') then
          q_o <= '1';
        end if;
      end if;
    end process;
  end generate G2;

end rtl;

----------------------------------------------------------------------------------
------------------------------------PISO Register---------------------------------
----------------------------------------------------------------------------------
-- Left shift register. PISO architecture. Load pin. Reset pin. Shift pin.
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity piso is
  generic(g_width    : integer := 8;
          g_clk_rise : string  := "TRUE"
          );
  port(
    clk_i   : in  std_logic;
    reset_i : in  std_logic;
    load_i  : in  std_logic;
    shift_i : in  std_logic;
    p_i     : in  std_logic_vector(g_width -1 downto 0);
    s_o     : out std_logic
    );
end piso;
architecture rtl of piso is

  signal s_int : std_logic_vector(g_width -1 downto 0);

begin

-------------------rise edge process------------------
  G1 : if (g_clk_rise = "TRUE") generate
  begin
    process(clk_i, reset_i)
    begin
      if reset_i = '1' then
        s_int <= (others => '1');
      elsif rising_edge(clk_i) then
        if load_i = '1' then
          s_int <= p_i;
        elsif shift_i = '1' then
          s_int <= s_int(g_width -2 downto 0) & '1';
        end if;
      end if;
    end process;
  end generate G1;

-------------------fall edge process------------------
  G2 : if (g_clk_rise = "FALSE") generate
  begin
    process(clk_i, reset_i)
    begin
      if reset_i = '1' then
        s_int <= (others => '1');
      elsif falling_edge(clk_i) then
        if load_i = '1' then
          s_int <= p_i;
        elsif shift_i = '1' then
          s_int <= s_int(g_width -1 downto 1) & '1';
        end if;
      end if;
    end process;
  end generate G2;
  s_o <= s_int(g_width -1);
end rtl;

----------------------------------------------------------------------------------
--------------------------------------COUNTDOWN-----------------------------------
----------------------------------------------------------------------------------
-- Countdown timer. Load pin. Reset pin. Enable countdown pin.
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity countdown is
  generic(g_width    : integer := 8;
          g_clk_rise : string  := "TRUE"
          );
  port(
    clk_i    : in  std_logic;
    reset_i  : in  std_logic;
    load_i   : in  std_logic;
    enable_i : in  std_logic;
    p_i      : in  std_logic_vector(g_width -1 downto 0);
    p_o      : out std_logic_vector(g_width -1 downto 0)
    );
end countdown;
architecture rtl of countdown is

  signal s_int : unsigned(g_width -1 downto 0);

begin

-------------------rise edge process------------------
  G1 : if (g_clk_rise = "TRUE") generate
  begin
    process(clk_i, reset_i)
    begin
      if reset_i = '1' then
        s_int <= (others => '0');
      elsif rising_edge(clk_i) then
        if load_i = '1' then
          s_int <= unsigned(p_i);
        elsif enable_i = '1' then
          s_int <= s_int -1;
        end if;
      end if;
    end process;
  end generate G1;

-------------------fall edge process------------------
  G2 : if (g_clk_rise = "FALSE") generate
  begin
    process(clk_i, reset_i)
    begin
      if reset_i = '1' then
        s_int <= (others => '0');
      elsif falling_edge(clk_i) then
        if load_i = '1' then
          s_int <= unsigned(p_i);
        elsif enable_i = '1' then
          s_int <= s_int -1;
        end if;
      end if;
    end process;
  end generate G2;
  p_o <= std_logic_vector(s_int);
end rtl;

-------------------------------------------------------------------------------
-- Pulse Stretcher
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity pulse_stretcher is
  generic (
    g_num_of_steps : positive
    );
  port (
    clk_i : in  std_logic;
    rst_i : in  std_logic;
    d_i   : in  std_logic;
    q_o   : out std_logic
    );
end entity pulse_stretcher;

architecture rtl of pulse_stretcher is

  type t_state is (st0_idle,
                   st1_pulsing
                   );

  signal s_state : t_state;
  signal s_idle : std_logic;
  signal s_num_of_steps : std_logic_vector(15 downto 0);
  signal s_p_o : std_logic_vector(15 downto 0);
  signal s_stop : std_logic;
  signal s_not_idle : std_logic;

begin  -- architecture rtl

  -- FSM
  p_update_state : process (clk_i, rst_i) is
  begin  -- process p_update_state
    if rst_i = '1' then                 -- asynchronous reset (active high)
      s_state <= st0_idle;
    elsif rising_edge(clk_i) then       -- rising clock edge
      case s_state is
        --
        when st0_idle =>
          if d_i = '1' then
            s_state <= st1_pulsing;
          end if;
        --
        when st1_pulsing =>
          if s_stop = '1' then
            s_state <= st0_idle;
          end if;
        --
        when others =>
          null;
      --
      end case;
    end if;
  end process p_update_state;

  p_update_output : process (s_state) is
  begin  -- process p_update_output
    case s_state is
      --
      when st0_idle =>
        s_idle <= '1';
      --
      when st1_pulsing =>
        s_idle <= '0';
      --
      when others =>
        null;
    --
    end case;
  end process p_update_output;

  -- countdown
  s_num_of_steps <= std_logic_vector(to_unsigned(g_num_of_steps, 16));
  s_not_idle <= not s_idle;

  countdown_1: entity work.countdown
    generic map (
      g_width    => 16,
      g_clk_rise => "TRUE"
      )
    port map (
      clk_i    => clk_i,
      reset_i  => rst_i,
      load_i   => s_idle,
      enable_i => s_not_idle,
      p_i      => s_num_of_steps,
      p_o      => s_p_o
      );

  s_stop <= not or_reduce(s_p_o);

  q_o <= s_not_idle;

end architecture rtl;
