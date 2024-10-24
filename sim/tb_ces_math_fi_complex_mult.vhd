library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;
entity tb_ces_math_fi_complex_mult is
end tb_ces_math_fi_complex_mult;

architecture behavior of tb_ces_math_fi_complex_mult is

    -- Parameters
    constant G_DATA_WIDTH : integer := 32;
    constant G_BIN_POINT  : integer := 16;

    -- Signals for DUT inputs
    signal clk_i    : std_logic := '0';
    signal real_1_i : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal imag_1_i : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal real_2_i : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal imag_2_i : std_logic_vector(G_DATA_WIDTH-1 downto 0);

    -- Signals for DUT outputs
    signal real_o   : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal imag_o   : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    
    
    signal dv_i : std_logic;
    signal dv_o : std_logic;
    -- Counter
    signal counter : integer := 0;

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin

    -- Clock generation process
    clk_process : process
    begin
        clk_i <= '0';
        wait for clk_period / 2;
        clk_i <= '1';
        wait for clk_period / 2;
    end process clk_process;

    -- Instantiate the Unit Under Test (UUT)
    uut: entity ces_math_lib.ces_math_fi_complex_mult
        generic map (
            G_DATA_WIDTH => G_DATA_WIDTH,
            G_BIN_POINT  => G_BIN_POINT
        )
        port map (
            clk_i     => clk_i,
            dv_i     => dv_i,
            real_1_i  => real_1_i,
            imag_1_i  => imag_1_i,
            real_2_i  => real_2_i,
            imag_2_i  => imag_2_i,
            real_o    => real_o,
            imag_o    => imag_o,
            dv_o      => dv_o
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Initialize inputs
        wait until rising_edge(clk_i);
        dv_i <= '1';
        counter <= counter + 1;
        real_1_i <= (others => '0');
        imag_1_i <= (others => '0');
        real_2_i <= (others => '0');
        imag_2_i <= (others => '0');
        wait until rising_edge(clk_i);
        counter <= counter + 1;
        -- Apply first set of inputs
        real_1_i <= std_logic_vector(to_signed(16384, G_DATA_WIDTH)); -- 1.0 in fixed-point 16-bit binary point
        imag_1_i <= std_logic_vector(to_signed(16384, G_DATA_WIDTH)); -- 1.0 in fixed-point
        real_2_i <= std_logic_vector(to_signed(32768, G_DATA_WIDTH)); -- 2.0 in fixed-point
        imag_2_i <= std_logic_vector(to_signed(32768, G_DATA_WIDTH)); -- 2.0 in fixed-point

        wait until rising_edge(clk_i);
        counter <= counter + 1;
        -- Apply second set of inputs
        real_1_i <= std_logic_vector(to_signed(-16384, G_DATA_WIDTH)); -- -1.0 in fixed-point
        imag_1_i <= std_logic_vector(to_signed(8192, G_DATA_WIDTH));   -- 0.5 in fixed-point
        real_2_i <= std_logic_vector(to_signed(8192, G_DATA_WIDTH));   -- 0.5 in fixed-point
        imag_2_i <= std_logic_vector(to_signed(-16384, G_DATA_WIDTH)); -- -1.0 in fixed-point

        wait until rising_edge(clk_i);
        counter <= counter + 1;
        -- Apply first set of inputs
        real_1_i <= std_logic_vector(to_signed(16384, G_DATA_WIDTH)); -- 1.0 in fixed-point 16-bit binary point
        imag_1_i <= std_logic_vector(to_signed(16384, G_DATA_WIDTH)); -- 1.0 in fixed-point
        real_2_i <= std_logic_vector(to_signed(32768, G_DATA_WIDTH)); -- 2.0 in fixed-point
        imag_2_i <= std_logic_vector(to_signed(32768, G_DATA_WIDTH)); -- 2.0 in fixed-point

        wait until rising_edge(clk_i);
        dv_i <= '0';
        -- Stop simulation
        wait;
    end process stim_proc;

end behavior;
