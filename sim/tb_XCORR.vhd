library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std.all;
use std.env.all;
library std;
use std.textio.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;

library gs_receiver_lib;
use gs_receiver_lib.gs_receiver_pkg.all;

entity tb_XCORR is
end tb_XCORR;

architecture behavior of tb_XCORR is
  function init_array_from_hex(file_name: string) return t_array_64 is
      file hex_file: TEXT open READ_MODE is file_name;
      variable line_buf : line;
      variable hex_value : std_logic_vector(31 downto 0);  -- Assuming each hex value is 8 characters (32 bits)
      variable v_array : t_array_64;
      variable i : integer := 0;
  begin
      
      -- Read each line from the file
      while not endfile(hex_file) loop
          readline(hex_file, line_buf);
          HREAD(line_buf, v_array(i));
          i := i + 1;
      end loop;
  
      -- Close the file
      file_close(hex_file);
  
      return v_array; 
  end function init_array_from_hex;
  -- Constants for testbench
  constant CLK_PERIOD : time := 10 ns;

  -- Testbench signals
  signal rstn_i   : std_logic := '0';
  signal clk_i    : std_logic := '0';
  signal sync_i   : std_logic := '0';
  signal din1_i   : fi_complex_number := (others => (others => '0'));
  signal din2_i   : fi_complex_number := (others => (others => '0'));
  signal data_o   : fi_complex_number;
  signal dv_o     : std_logic;
  signal s_r1_array            : t_array_64:= init_array_from_hex("r1.txt");
  signal s_i1_array            : t_array_64:= init_array_from_hex("i1.txt");
  signal s_r2_array            : t_array_64:= init_array_from_hex("r3.txt");
  signal s_i2_array            : t_array_64:= init_array_from_hex("i3.txt");
  -- DUT instantiation
  component XCORR
    generic (
      G_DATA_WIDTH   : integer := 32;
      G_BIN_POINT    : integer := 16
      );
    port (
      rstn_i : in std_logic;
      clk_i  : in std_logic;
      sync_i   : in std_logic;
      din1_i : in fi_complex_number;
      din2_i : in fi_complex_number;
      data_o : out fi_complex_number;
      dv_o : out std_logic
      );
  end component;

begin
  -- Instantiate the Device Under Test (DUT)
  DUT: XCORR
    generic map (
      G_DATA_WIDTH => 32,
      G_BIN_POINT  => 16
      )
    port map (
      rstn_i => rstn_i,
      clk_i  => clk_i,
      sync_i => sync_i,
      din1_i => din1_i,
      din2_i => din2_i,
      data_o => data_o,
      dv_o   => dv_o
      );

  -- Clock generation
  clk_process: process
  begin
    clk_i <= '0';
    wait for CLK_PERIOD / 2;
    clk_i <= '1';
    wait for CLK_PERIOD / 2;
  end process clk_process;

  -- Reset and stimulus process
  stimulus: process
  begin
    -- Reset the system
    rstn_i <= '0';
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    rstn_i <= '1';
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    for j in 0 to 3 loop
      sync_i <= '1';
      din1_i.real_num <= s_r1_array(0);
      din1_i.imag_num <= s_i1_array(0);
      din2_i.real_num <= s_r2_array(0);
      din2_i.imag_num <= s_i2_array(0);
      wait until rising_edge(clk_i);
      sync_i <= '0';
      for i in 1 to 63 loop
        din1_i.real_num <= s_r1_array(i);
        din1_i.imag_num <= s_i1_array(i);
        din2_i.real_num <= s_r2_array(i);
        din2_i.imag_num <= s_i2_array(i);
        wait until rising_edge(clk_i);
      end loop;
    end loop;
    -- Stop simulation
    stop;
    wait;
  end process stimulus;
end behavior;
