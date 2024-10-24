library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ces_math_fi_add_sub is
end tb_ces_math_fi_add_sub;

architecture behavior of tb_ces_math_fi_add_sub is

    -- Constants for fixed-point representation
    constant C_CES_ADD    : integer := 0;
    constant C_CES_SUB    : integer := 1;
    constant C_CES_SIGNED : integer := 0;
    constant C_CES_UNSIGNED : integer := 1;
    constant C_CES_TRUNC  : integer := 0;
    constant C_CES_ROUND  : integer := 1;

    -- Signal declarations for the test
    signal clk_i     : std_logic := '0';
    signal ce_i      : std_logic := '1';
    signal sel_add_i : std_logic := '1'; -- 1 for addition, 0 for subtraction
    signal din1_i    : std_logic_vector(31 downto 0);
    signal din2_i    : std_logic_vector(31 downto 0);
    signal dout_o    : std_logic_vector(31 downto 0);

    -- Component declaration of the design under test (DUT)
    component ces_math_fi_add_sub
        generic(
            g_direction       : integer := C_CES_ADD;
            g_representation  : natural := C_CES_SIGNED;
            g_pipeline_input  : natural := 0;
            g_pipeline_output : natural := 1;
            g_din1_w          : natural := 32;
            g_din1_binpnt     : natural := 16;
            g_din2_w          : natural := 32;
            g_din2_binpnt     : natural := 16;
            g_dout_w          : natural := 32;
            g_dout_binpnt     : natural := 16;
            g_round_mode      : natural := C_CES_TRUNC
        );
        port(
            clk_i     : in  std_logic;
            ce_i      : in  std_logic;
            sel_add_i : in  std_logic := '1';
            din1_i    : in  std_logic_vector(g_din1_w - 1 downto 0);
            din2_i    : in  std_logic_vector(g_din2_w - 1 downto 0);
            dout_o    : out std_logic_vector(g_dout_w - 1 downto 0)
        );
    end component;



begin

    -- Instantiate the DUT (Design Under Test)
    DUT: ces_math_fi_add_sub
        generic map (
            g_direction       => C_CES_ADD,       -- Perform addition
            g_representation  => C_CES_SIGNED,    -- Signed fixed-point numbers
            g_pipeline_input  => 0,               -- No pipeline at input
            g_pipeline_output => 1,               -- 1 clock cycle delay at output
            g_din1_w          => 32,              -- Data width of input 1
            g_din1_binpnt     => 16,              -- Binary point of input 1
            g_din2_w          => 32,              -- Data width of input 2
            g_din2_binpnt     => 16,              -- Binary point of input 2
            g_dout_w          => 32,              -- Data width of output
            g_dout_binpnt     => 16,              -- Binary point of output
            g_round_mode      => C_CES_TRUNC      -- Truncate the result
        )
        port map (
            clk_i     => clk_i,
            ce_i      => ce_i,
            sel_add_i => '0',
            din1_i    => din1_i,
            din2_i    => din2_i,
            dout_o    => dout_o
        );
    -- Clock generation process
    process
    begin
        while true loop
            clk_i <= '0';
            wait for 10 ns;
            clk_i <= '1';
            wait for 10 ns;
        end loop;
    end process;
    
    -- Test process
    process
    begin
        -- Test case 1: Add two positive numbers
        din1_i <= std_logic_vector(to_signed(32768, 32)); -- 0.5 in fixed-point
        din2_i <= std_logic_vector(to_signed(65536, 32)); -- 1.0 in fixed-point
        sel_add_i <= '1'; -- Perform addition
        wait until rising_edge(clk_i);

        -- Test case 2: Subtract two numbers
        din1_i <= std_logic_vector(to_signed(98304, 32)); -- 1.5 in fixed-point
        din2_i <= std_logic_vector(to_signed(32768, 32)); -- 0.5 in fixed-point
        sel_add_i <= '0'; -- Perform subtraction
        wait until rising_edge(clk_i);

        -- Test case 3: Add a positive and a negative number
        din1_i <= std_logic_vector(to_signed(32768, 32)); -- 0.5 in fixed-point
        din2_i <= std_logic_vector(to_signed(-65536, 32)); -- -1.0 in fixed-point
        sel_add_i <= '1'; -- Perform addition
        wait until rising_edge(clk_i);

        -- Test case 4: Add two negative numbers
        din1_i <= std_logic_vector(to_signed(-32768, 32)); -- -0.5 in fixed-point
        din2_i <= std_logic_vector(to_signed(-32768, 32)); -- -0.5 in fixed-point
        sel_add_i <= '1'; -- Perform addition
        wait until rising_edge(clk_i);

        -- Finish the simulation
        wait for 100 ns;
        assert false report "End of simulation" severity note;
        wait;
    end process;

end behavior;
