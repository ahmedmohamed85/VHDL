library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;
library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;
library gs_receiver_lib;
use gs_receiver_lib.gs_receiver_pkg.all;

entity tb_threshold_exceeding_checking is
end tb_threshold_exceeding_checking;

architecture sim of tb_threshold_exceeding_checking is
  -- Component declaration
  component threshold_exceeding_checking
    generic (
      G_OUTPUT_DATA_WIDTH   : integer := 32;
      G_OUTPUT_BIN_POINT    : integer := 16
    );
    port (
      rstn_i        : in  std_logic;
      clk_i         : in  std_logic;
      rx_signal_i   : in  fi_complex_number;
      open_window_o : out std_logic;
      ma_o          : out std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0)
    );
  end component;

  -- Signals
  signal rstn_i        : std_logic := '0';
  signal clk_i         : std_logic := '0';
  signal rx_signal_i   : fi_complex_number;
  signal open_window_o : std_logic;
  signal ma_o          : std_logic_vector(31 downto 0);

  -- Clock generation process
  constant clk_period : time := 10 ns;
begin
  -- Instantiate the unit under test (UUT)
  uut: threshold_exceeding_checking
    generic map (
      G_OUTPUT_DATA_WIDTH => 32,
      G_OUTPUT_BIN_POINT  => 16
    )
    port map (
      rstn_i        => rstn_i,
      clk_i         => clk_i,
      rx_signal_i   => rx_signal_i,
      open_window_o => open_window_o,
      ma_o          => ma_o
    );

  -- Clock process
  clk_process : process
  begin
    clk_i <= '1';
    wait for clk_period / 2;
    clk_i <= '0';
    wait for clk_period / 2;
  end process;

    -- Set rx_signal_i to specified fixed-point values
    rx_signal_i.real_num <= std_logic_vector(to_signed(2**16, 32));  -- 1 in fixed-point (32-bit width, 16-bit binary point)
    rx_signal_i.imag_num <= std_logic_vector(to_signed(2**17, 32));  -- 2 in fixed-point (32-bit width, 16-bit binary point)
    
    
  -- Stimulus process
  stim_proc: process
  begin
    -- Reset
    rstn_i <= '0';
    wait for 200 ns;
    rstn_i <= '1';
    wait for 20 ns;


    wait for 100 ns;

    -- Additional test cases can be added here

    -- Stop simulation
    wait;
  end process stim_proc;
end sim;
