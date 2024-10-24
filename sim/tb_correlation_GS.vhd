library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std.all;

library std;
use std.textio.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;

library gs_receiver_lib;
use gs_receiver_lib.gs_receiver_pkg.all;

entity tb_correlation_GS is
end tb_correlation_GS;

architecture test of tb_correlation_GS is

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
  -- Component declaration of the Unit Under Test (UUT)
  component correlation_GS is
    generic (
      G_DATA_WIDTH   : integer := 32;  -- Width of the input and output data
      G_BIN_POINT    : integer := 16    -- Binary point for fixed-point representation
    );
    port ( 
    rstn_i : in std_logic;
    clk_i  : in std_logic;
    dv_i   : in std_logic;
    sync_symbol_i : in sync_symbol;
    first_time_i  : in t_complex_array_64;
    second_time_i : in t_complex_array_64;
    rx_signal_i   : in t_complex_array_64;
    delayed_rx_signal_i  : in t_complex_array_64;
    corr_total_o : out complex_number;
    dv_o : out std_logic
    );
  end component;

  -- Clock period definitions
  constant clk_period : time := 10 ns;

  -- Signals to connect to UUT
  signal rstn_i                : std_logic := '0';
  signal clk_i                 : std_logic := '0';
  signal dv_i                  : std_logic := '0';
  signal sync_symbol_i         : sync_symbol;
  signal s_r1_array            : t_array_64:= init_array_from_hex("r1.txt");
  signal s_i1_array            : t_array_64:= init_array_from_hex("i1.txt");
  signal s_r2_array            : t_array_64:= init_array_from_hex("r2.txt");
  signal s_i2_array            : t_array_64:= init_array_from_hex("i2.txt");
  signal s_r3_array            : t_array_64:= init_array_from_hex("r3.txt");
  signal s_i3_array            : t_array_64:= init_array_from_hex("i3.txt");
  signal s_r4_array            : t_array_64:= init_array_from_hex("r4.txt");
  signal s_i4_array            : t_array_64:= init_array_from_hex("i4.txt");
  
  signal rx_signal_i      : t_complex_array_64;
  signal first_time_i     : t_complex_array_64;
  signal second_time_i      : t_complex_array_64;
  signal delayed_rx_signal_i : t_complex_array_64;
  signal corr_total_o : complex_number;
  signal corr_total_real_o      : std_logic_vector(31 downto 0);
  signal corr_total_imag_o      : std_logic_vector(31 downto 0);
  signal dv_o                  : std_logic;

begin

 init_proc : process
 begin
 for i in 0 to 63 loop
   rx_signal_i(i).real_num <= s_r1_array(i);
   rx_signal_i(i).imag_num <= s_i1_array(i);
   delayed_rx_signal_i(i).real_num <= s_r2_array(i);
   delayed_rx_signal_i(i).imag_num <= s_i2_array(i);
   
   first_time_i(i).real_num <= s_r3_array(i);
   first_time_i(i).imag_num <= s_i3_array(i);
   
   second_time_i(i).real_num <= s_r4_array(i);
   second_time_i(i).imag_num <= s_i4_array(i);
 end loop;
 wait;
 end process init_proc;
--  sync_symbol_i.first_time <= sync_symbol_i
  -- Instantiate the Unit Under Test (UUT)
  uut: correlation_GS
    generic map (
      G_DATA_WIDTH => 32,
      G_BIN_POINT  => 16
    )
    port map (
      rstn_i => rstn_i,
      clk_i => clk_i,
      dv_i => dv_i,
      sync_symbol_i => sync_symbol_i,
      first_time_i => first_time_i,
      second_time_i => second_time_i,
      rx_signal_i => rx_signal_i,
      delayed_rx_signal_i => delayed_rx_signal_i,
      corr_total_o => corr_total_o,
      dv_o => dv_o
    );

  -- Clock process definitions
  clk_process :process
  begin
    clk_i <= '0';
    wait for clk_period / 2;
    clk_i <= '1';
    wait for clk_period / 2;
  end process;

  -- Stimulus process
  stim_proc: process
  begin
    -- Reset the system
    rstn_i <= '0';
    wait for 20 ns;
    rstn_i <= '1';
    wait until rising_edge(clk_i);
    -- Apply input stimuli
    dv_i <= '1';  -- Enable data valid
    wait until rising_edge(clk_i);
    dv_i <= '0';
    -- Initialize the signals with some test values
    -- Assign real and imaginary inputs (with fractions)
--    rx_signal_real_i <= (others => std_logic_vector(to_signed(16384, 32))); -- 1.0 in Q16 format
--    rx_signal_imag_i <= (others => std_logic_vector(to_signed(8192, 32)));  -- 0.5 in Q16 format
--    delayed_rx_signal_real_i <= (others => std_logic_vector(to_signed(32768, 32))); -- 2.0 in Q16 format
--    delayed_rx_signal_imag_i <= (others => std_logic_vector(to_signed(12288, 32))); -- 0.75 in Q16 format
    
--    -- Initialize the sync symbol with a test pattern
--    sync_symbol_i <= (others => '1');

    -- Wait for a few clock cycles to observe the result
    wait for 100 ns;

    -- Check the outputs (optional: can add assertions here)
    
    -- Disable data valid
    dv_i <= '0';
    
    -- Wait for some time and finish simulation
    wait for 100 ns;
    wait;
  end process;

end test;
