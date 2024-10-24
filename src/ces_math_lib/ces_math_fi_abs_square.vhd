library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;
library gs_receiver_lib;
use gs_receiver_lib.gs_receiver_pkg.all;

entity ces_math_fi_abs_square is
  generic(
    G_OUTPUT_DATA_WIDTH : natural := 32; 
    G_OUTPUT_BIN_POINT  : natural := 16
  );
  port(
    clk_i         : in  std_logic;
    dv_i          : in  std_logic;    -- Data valid input
    complex_in_i  : in  complex_number;
    abs_square_o   : out std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0); -- Output for absolute square
    dv_o          : out std_logic      -- Data valid output
  );
end entity ces_math_fi_abs_square;

architecture rtl of ces_math_fi_abs_square is

--  signal s_real_sq      : std_logic_vector(2*C_DATA_WIDTH-1 downto 0);
--  signal s_imag_sq      : std_logic_vector(2*C_DATA_WIDTH-1 downto 0);
--  signal s_abs_square    : std_logic_vector(2*C_DATA_WIDTH-1 downto 0);

  signal s_dv_delay      : std_logic_vector(5 downto 0) := (others => '0');

  -- Signals for multiplier instances
  signal s_mult_real_out : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  signal s_mult_imag_out : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);

  -- Signals for adder instance
  signal s_adder_out     : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);

begin

  -- Real part square (real_num * real_num)
  inst_mult_real: entity ces_math_lib.ces_math_fi_mult
    generic map (
        g_din_a_w      => C_DATA_WIDTH,   -- Input width for real numbers
        g_din_a_binpnt => C_BIN_POINT,     -- Input binary point for real numbers
        g_din_b_w      => C_DATA_WIDTH,   -- Input width for real numbers
        g_din_b_binpnt => C_BIN_POINT,     -- Input binary point for real numbers
        g_dout_w       => G_OUTPUT_DATA_WIDTH,   -- Output width for multiplication
        g_dout_binpnt  => G_OUTPUT_BIN_POINT      -- Output binary point for multiplication
    )
    port map(
      clk_i  => clk_i,
      din1_i => complex_in_i.real_num,
      din2_i => complex_in_i.real_num,
      dout_o => s_mult_real_out
    );

  -- Imaginary part square (imag_num * imag_num)
  inst_mult_imag: entity ces_math_lib.ces_math_fi_mult
    generic map (
        g_din_a_w      => C_DATA_WIDTH,   -- Input width for real numbers
        g_din_a_binpnt => C_BIN_POINT,     -- Input binary point for real numbers
        g_din_b_w      => C_DATA_WIDTH,   -- Input width for real numbers
        g_din_b_binpnt => C_BIN_POINT,     -- Input binary point for real numbers
        g_dout_w       => G_OUTPUT_DATA_WIDTH,   -- Output width for multiplication
        g_dout_binpnt  => G_OUTPUT_BIN_POINT      -- Output binary point for multiplication
    )
    port map(
      clk_i  => clk_i,
      din1_i => complex_in_i.imag_num,
      din2_i => complex_in_i.imag_num,
      dout_o => s_mult_imag_out
    );

  -- Add real part square and imaginary part square
  inst_adder: entity ces_math_lib.ces_math_fi_add_sub
      generic map (
          g_direction      => C_CES_ADD,
          g_representation => C_CES_SIGNED,
          g_din1_w        => G_OUTPUT_DATA_WIDTH,
          g_din1_binpnt   => G_OUTPUT_BIN_POINT,
          g_din2_w        => G_OUTPUT_DATA_WIDTH,
          g_din2_binpnt   => G_OUTPUT_BIN_POINT,
          g_dout_w        => G_OUTPUT_DATA_WIDTH,
          g_dout_binpnt   => G_OUTPUT_BIN_POINT
      )
    port map(
      clk_i   => clk_i,
      ce_i    => '1',
      din1_i  => s_mult_real_out,
      din2_i  => s_mult_imag_out,
      dout_o  => s_adder_out
    );

  -- Assign the final absolute square result
  abs_square_o <= s_adder_out;

  -- Data valid signal delayed by 5 clock cycles
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      s_dv_delay <= s_dv_delay(4 downto 0) & dv_i;
    end if;
  end process;

  dv_o <= s_dv_delay(5);

end architecture rtl;
