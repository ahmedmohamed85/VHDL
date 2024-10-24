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
    dv_i   : in std_logic;
    open_window_i   : in std_logic;
    rx_signal_i   : in t_complex_array_64;
    open_window_o : out std_logic;
    ma_o          : out std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
    dv_o          : out std_logic
    );
end threshold_exceeding_checking;

architecture Behavioral of threshold_exceeding_checking is
  signal s_index_cnt : unsigned(5 downto 0);
  signal s_ma : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
  signal s_abs_square_i : complex_number;
  signal s_abs_square_o : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
  signal s_acc_i : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  signal s_acc_o : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
  signal s_abs_sqr_dv_i : std_logic;
  signal s_abs_sqr_dv_o : std_logic;
  
  type t_state_type is (idle_st, s0_st, s1_st, s2_st);
  signal s_state : t_state_type;
begin

    inst_ces_math_fi_abs_square: entity ces_math_lib.ces_math_fi_abs_square
        generic map (
            G_OUTPUT_DATA_WIDTH => G_OUTPUT_DATA_WIDTH,
            G_OUTPUT_BIN_POINT  => G_OUTPUT_BIN_POINT
        )
        port map (
            clk_i        => clk_i,
            dv_i         => s_abs_sqr_dv_i,
            complex_in_i => s_abs_square_i,
            abs_square_o => s_abs_square_o,
            dv_o         => s_abs_sqr_dv_o
        );
  
  s_acc_i <= s_acc_o when s_abs_sqr_dv_o='1' else (others=>'0');
        
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
      din1_i  => s_abs_square_o,
      din2_i  => s_acc_i,
      dout_o  => s_acc_o
    );
            
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
      s_abs_sqr_dv_i <= '0';
      s_abs_square_i <= (others=>(others=>'0'));
      s_index_cnt <= (others=>'0');
      s_state <= idle_st;
    else
      case s_state is
        when idle_st =>
          if dv_i = '1' then
            s_index_cnt <= (others=>'0');
            s_state <= s0_st;
          end if;
        
        when s0_st =>
          s_abs_sqr_dv_i <= '1';
          s_index_cnt <= s_index_cnt + 1;
          s_abs_square_i <= rx_signal_i(to_integer(s_index_cnt));
          
          if(s_index_cnt = 63)then
            s_state <= s1_st;
          end if;
         
       when s1_st =>
          s_abs_sqr_dv_i <= '0';
          if(s_abs_sqr_dv_o = '0')then
            s_state <= s2_st;
          end if;
          
        when s2_st =>
           for i in G_OUTPUT_DATA_WIDTH-1 downto G_OUTPUT_DATA_WIDTH-6 loop
             s_ma(i) <= s_acc_o(G_OUTPUT_DATA_WIDTH-1);
           end loop;            
           s_ma(G_OUTPUT_DATA_WIDTH-7 downto 0) <= s_acc_o(G_OUTPUT_DATA_WIDTH-7 downto 6);
           dv_o <= '1';
           
           s_state <= idle_st;
      end case;
    end if;
  end if;
  end process; 
  
  ma_o <= s_ma;
  
  open_window_o <= '1' when open_window_i='0' and signed(s_ma) < signed(C_THRESHOLD) else '0';
  
end Behavioral;
