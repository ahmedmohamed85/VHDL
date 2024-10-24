library IEEE;
use IEEE.std_logic_1164.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;
library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;

library gs_receiver_lib;
use gs_receiver_lib.gs_receiver_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity tb_ces_math_fi_abs_square is
    -- No ports for the test bench
end entity tb_ces_math_fi_abs_square;

architecture sim of tb_ces_math_fi_abs_square is
    -- Constants
    constant C_DATA_WIDTH : natural := 32;  -- Width for the complex number
    constant G_OUTPUT_DATA_WIDTH : natural := 32; 
    constant G_OUTPUT_BIN_POINT  : natural := 16; 
    constant C_DV_DELAY   : natural := 4;    -- Delay for dv_o signal

    -- Signals to connect to the unit under test (UUT)
    signal clk_i         : std_logic := '0';
    signal dv_i          : std_logic := '0';    
    signal complex_in_i  : complex_number;  -- Complex input
    signal abs_square_o   : std_logic_vector(G_OUTPUT_DATA_WIDTH - 1 downto 0); -- Absolute square output
    signal dv_o          : std_logic;  -- Data valid output

    -- Clock period definition
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz clock

begin
    -- Instantiate the unit under test (UUT)
    uut: entity work.ces_math_fi_abs_square
        generic map (
            G_OUTPUT_DATA_WIDTH => G_OUTPUT_DATA_WIDTH,
            G_OUTPUT_BIN_POINT  => G_OUTPUT_BIN_POINT
        )
        port map (
            clk_i        => clk_i,
            dv_i         => dv_i,
            complex_in_i => complex_in_i,
            abs_square_o  => abs_square_o,
            dv_o         => dv_o
        );

    -- Clock generation process
    clk_process: process
    begin
        while true loop
            clk_i <= not clk_i;  -- Toggle clock
            wait for CLK_PERIOD / 2;  -- Half clock period
        end loop;
    end process;

    -- Stimulus process
    stimulus: process
    begin
        -- Initialize inputs
        dv_i <= '0';
        complex_in_i.real_num <= (others => '0');  -- Real part = 0
        complex_in_i.imag_num <= (others => '0');  -- Imaginary part = 0
        
        wait for 2 * CLK_PERIOD;  -- Wait for clock to stabilize
        
        -- First test case: (1.0 + 2.0i) -> abs_square = 1.0^2 + 2.0^2 = 5.0
        complex_in_i.real_num <= std_logic_vector(to_signed(1 * 2**16, C_DATA_WIDTH));  -- 1.0 in fixed-point
        complex_in_i.imag_num <= std_logic_vector(to_signed(2 * 2**16, C_DATA_WIDTH));  -- 2.0 in fixed-point
        dv_i <= '1';  -- Set data valid
        wait for CLK_PERIOD;  -- Wait for a clock cycle
        dv_i <= '0';  -- Clear data valid
        
        wait for 2 * CLK_PERIOD;  -- Wait for output to stabilize
        
        -- Second test case: (3.5 + 4.5i) -> abs_square = 3.5^2 + 4.5^2 = 30.5
        complex_in_i.real_num <= std_logic_vector(to_signed(3 * 2**16, C_DATA_WIDTH));  -- 3.5 in fixed-point
        complex_in_i.imag_num <= std_logic_vector(to_signed(4 * 2**16, C_DATA_WIDTH));  -- 4.5 in fixed-point
        dv_i <= '1';  -- Set data valid
        wait for CLK_PERIOD;  -- Wait for a clock cycle
        dv_i <= '0';  -- Clear data valid
        
        wait for 2 * CLK_PERIOD;  -- Wait for output to stabilize
        
        -- Third test case: (-1.5 - 1.5i) -> abs_square = (-1.5)^2 + (-1.5)^2 = 4.5
        complex_in_i.real_num <= std_logic_vector(to_signed(-1 * 2**16, C_DATA_WIDTH));  -- -1.5 in fixed-point
        complex_in_i.imag_num <= std_logic_vector(to_signed(-2 * 2**16, C_DATA_WIDTH));  -- -1.5 in fixed-point
        dv_i <= '1';  -- Set data valid
        wait for CLK_PERIOD;  -- Wait for a clock cycle
        dv_i <= '0';  -- Clear data valid
        
        wait for 2 * CLK_PERIOD;  -- Wait for output to stabilize

        -- End the simulation after all test cases
        wait;
    end process;

end architecture sim;
