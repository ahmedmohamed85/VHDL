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

entity threshold_exceeding_checking is
  generic (
    G_OUTPUT_DATA_WIDTH   : integer := 32;  -- Width of the input and output data
    G_OUTPUT_BIN_POINT    : integer := 16    -- Binary point for fixed-point representation
    );
  Port ( 
    rstn_i : in std_logic;
    clk_i  : in std_logic;
    rx_signal_i   : in fi_complex_number;
    open_window_o : out std_logic;
    ma_o          : out std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0)
    );
end threshold_exceeding_checking;

architecture Behavioral of threshold_exceeding_checking is

  type t_array_65 is array(0 to 64) of std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
  signal s_shft_reg : t_array_65;
--  signal s_index_cnt : unsigned(5 downto 0);
  signal s_ma : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
  signal s_abs_square_i : fi_complex_number;
  signal s_abs_square_o : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  signal s_add_din1 : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0):=(others=>'0');
  signal s_add_din2 : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0):=(others=>'0');
  signal s_add_o : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0):=(others=>'0');
  signal s_sub_o : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0):=(others=>'0');
  
  signal s_delay_cnt : unsigned(7 downto 0);
  
  signal s_abs_sqr_dv_i : std_logic;
  signal s_abs_sqr_dv_o : std_logic;
  signal s_open_window  : std_logic;
  
begin

  proc_shft_reg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rstn_i='0' then
        s_shft_reg <= (others=>(others=>'0'));
      else
        s_shft_reg <= s_abs_square_o & s_shft_reg(0 to 63);
      end if;
    end if;
  end process proc_shft_reg;
  
  s_abs_square_i <= rx_signal_i;
  
  inst_ces_math_fi_abs_square: entity ces_math_lib.ces_math_fi_abs_square
      generic map (
          G_OUTPUT_DATA_WIDTH => G_OUTPUT_DATA_WIDTH,
          G_OUTPUT_BIN_POINT  => G_OUTPUT_BIN_POINT
      )
      port map (
          clk_i        => clk_i,
          dv_i         => '1',
          complex_in_i => s_abs_square_i,
          abs_square_o => s_abs_square_o,
          dv_o         => s_abs_sqr_dv_o
      );
  
        
  inst_adder: entity ces_math_lib.ces_math_fi_add_sub
    generic map (
        g_direction      => C_CES_ADD,
        g_representation => C_CES_SIGNED,
        --* 0 or 1, number of register
        g_pipeline_input  => 0,
        --* >= 0, delay value
        g_pipeline_output => 0,
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
      din1_i  => s_add_din1,
      din2_i  => s_add_din2,
      dout_o  => s_add_o
    );
    
  s_add_din1 <= (others=>'0') when rstn_i='0' else s_shft_reg(0);
  s_add_din2 <= (others=>'0') when rstn_i='0' else s_sub_o;
  
  inst_sub: entity ces_math_lib.ces_math_fi_add_sub
    generic map (
        g_direction      => C_CES_SUB,
        g_representation => C_CES_SIGNED,
        --* 0 or 1, number of register
        g_pipeline_input  => 0,
        --* >= 0, delay value
        g_pipeline_output => 1,
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
      din1_i  => s_add_o,
      din2_i  => s_shft_reg(64),
      dout_o  => s_sub_o
    );


   gen_ma : for i in G_OUTPUT_DATA_WIDTH-1 downto G_OUTPUT_DATA_WIDTH-6 generate
     s_ma(i) <= s_sub_o(G_OUTPUT_DATA_WIDTH-1); --* sign extend
   end generate gen_ma;        
       
   s_ma(G_OUTPUT_DATA_WIDTH-7 downto 0) <= s_sub_o(G_OUTPUT_DATA_WIDTH-1 downto 6);
                   
--  proc_index : process(clk_i)
--  begin
--    if rising_edge(clk_i) then
--      if rstn_i='0' then
--        s_index_cnt <= (others=>'0');
--      else
--        if(s_abs_sqr_dv_o='0')then
--          s_index_cnt <= (others=>'0');
--        elsif(s_abs_sqr_dv_o='1')then
--          s_index_cnt <= s_index_cnt + 1;
--        end if;
--      end if;
--    end if;
--  end process proc_index;


  proc_fsm : process(clk_i)
  begin
  if rising_edge(clk_i)then
    if rstn_i='0' then
      s_open_window <= '0';
      s_delay_cnt <= (others=>'0');
    else
      if(s_open_window='1')then
        if(s_delay_cnt = 3*75-1)then
          s_delay_cnt <= (others=>'0');
          s_open_window <= '0';
        else
          s_delay_cnt <= s_delay_cnt + 1;
        end if;
      elsif(signed(s_ma) > signed(C_THRESHOLD))then
        s_open_window <= '1';
      end if;
    end if;
  end if;
  end process; 
  
  ma_o <= s_ma;
  
  open_window_o <= s_open_window;
  
end Behavioral;
