library IEEE;
use IEEE.std_logic_1164.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;
library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;

entity ces_math_fi_complex_mult is
    generic (
        G_DATA_WIDTH   : integer := 32;  -- Width of the input and output data
        G_BIN_POINT    : integer := 16    -- Binary point for fixed-point representation
    );
    port (
        clk_i       : in  std_logic;                            -- Clock input
        dv_i        : in  std_logic;
        real_1_i    : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- First real input
        imag_1_i    : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- First imaginary input
        real_2_i    : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Second real input
        imag_2_i    : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Second imaginary input
        real_o      : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- Output real part
        imag_o      : out std_logic_vector(G_DATA_WIDTH-1 downto 0);   -- Output imaginary part
        dv_o        : out std_logic
    );
end ces_math_fi_complex_mult;

architecture Behavioral of ces_math_fi_complex_mult is
  signal s_real1_real2  : std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Result of real multiplication
  signal s_real1_imag2  : std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Result of imaginary multiplication
  signal s_imag1_real2  : std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Result of imaginary multiplication
  signal s_imag1_imag2  : std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Result of real multiplication
  signal s_temp_real   : std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Intermediate real result
  signal s_temp_imag   : std_logic_vector(G_DATA_WIDTH-1 downto 0);  -- Intermediate imaginary result
  
  signal s_delay       : std_logic_vector(4 downto 0) := (others=>'0');
begin

  proc_dv :process(clk_i)
  begin
  if rising_edge(clk_i)then
    s_delay <= s_delay(s_delay'left-1 downto 0) & dv_i;
  end if;
  end process proc_dv;
  
  dv_o <= s_delay(s_delay'left);
  
    -- Multiplying real_1_i and real_2_i
    real_mul_inst: entity ces_math_lib.ces_math_fi_mult
        generic map (
            g_din_a_w      => G_DATA_WIDTH,   -- Input width for real numbers
            g_din_a_binpnt => G_BIN_POINT,     -- Input binary point for real numbers
            g_din_b_w      => G_DATA_WIDTH,   -- Input width for real numbers
            g_din_b_binpnt => G_BIN_POINT,     -- Input binary point for real numbers
            g_dout_w       => G_DATA_WIDTH,   -- Output width for multiplication
            g_dout_binpnt  => G_BIN_POINT      -- Output binary point for multiplication
        )
        port map (
            clk_i  => clk_i,
            din1_i => real_1_i,
            din2_i => real_2_i,
            dout_o => s_real1_real2
        );

    -- Multiplying imag_1_i and imag_2_i
    imag_mul_inst: entity ces_math_lib.ces_math_fi_mult
        generic map (
            g_din_a_w      => G_DATA_WIDTH,
            g_din_a_binpnt => G_BIN_POINT,
            g_din_b_w      => G_DATA_WIDTH,
            g_din_b_binpnt => G_BIN_POINT,
            g_dout_w       => G_DATA_WIDTH,
            g_dout_binpnt  => G_BIN_POINT
        )
        port map (
            clk_i  => clk_i,
            din1_i => imag_1_i,
            din2_i => imag_2_i,
            dout_o => s_imag1_imag2
        );

    -- Multiplying real_1_i and imag_2_i
    real_part2_inst: entity ces_math_lib.ces_math_fi_mult
        generic map (
            g_din_a_w      => G_DATA_WIDTH,
            g_din_a_binpnt => G_BIN_POINT,
            g_din_b_w      => G_DATA_WIDTH,
            g_din_b_binpnt => G_BIN_POINT,
            g_dout_w       => G_DATA_WIDTH,
            g_dout_binpnt  => G_BIN_POINT
        )
        port map (
            clk_i  => clk_i,
            din1_i => real_1_i,
            din2_i => imag_2_i,
            dout_o => s_real1_imag2
        );

    -- Multiplying imag_1_i and real_2_i
    imag_part1_inst: entity ces_math_lib.ces_math_fi_mult
        generic map (
            g_din_a_w      => G_DATA_WIDTH,
            g_din_a_binpnt => G_BIN_POINT,
            g_din_b_w      => G_DATA_WIDTH,
            g_din_b_binpnt => G_BIN_POINT,
            g_dout_w       => G_DATA_WIDTH,
            g_dout_binpnt  => G_BIN_POINT
        )
        port map (
            clk_i  => clk_i,
            din1_i => imag_1_i,
            din2_i => real_2_i,
            dout_o => s_imag1_real2
        );

    -- Adding real_part1 and imag_part1 for real output
    real_add_inst: entity ces_math_lib.ces_math_fi_add_sub
        generic map (
            g_direction      => C_CES_ADD,
            g_representation => C_CES_SIGNED,
            g_din1_w        => G_DATA_WIDTH,
            g_din1_binpnt   => G_BIN_POINT,
            g_din2_w        => G_DATA_WIDTH,
            g_din2_binpnt   => G_BIN_POINT,
            g_dout_w        => G_DATA_WIDTH,
            g_dout_binpnt   => G_BIN_POINT
        )
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_real1_real2,
            din2_i    => s_imag1_imag2,
            dout_o    => s_temp_real
        );

    -- subtract real_part2 and imag_part2 for imaginary output
    imag_add_inst: entity ces_math_lib.ces_math_fi_add_sub
        generic map (
            g_direction      => C_CES_SUB,
            g_representation => C_CES_SIGNED,
            g_din1_w        => G_DATA_WIDTH,
            g_din1_binpnt   => G_BIN_POINT,
            g_din2_w        => G_DATA_WIDTH,
            g_din2_binpnt   => G_BIN_POINT,
            g_dout_w        => G_DATA_WIDTH,
            g_dout_binpnt   => G_BIN_POINT
        )
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_real1_imag2,
            din2_i    => s_imag1_real2,
            dout_o    => s_temp_imag
        );

    -- Output assignment
    real_o <= s_temp_real; -- (x1x2 + y1y2) 
    imag_o <= s_temp_imag; -- (x1y2 - y1x2)

end Behavioral;
