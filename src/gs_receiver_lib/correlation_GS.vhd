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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity correlation_GS is
  generic (
    G_DATA_WIDTH   : integer := 32;  -- Width of the input and output data
    G_BIN_POINT    : integer := 16    -- Binary point for fixed-point representation
    );
  Port ( 
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
end correlation_GS;

architecture Behavioral of correlation_GS is
  constant C_LATENCY    : natural := 6;
  signal s_mult1_input_1 : complex_number;
  signal s_mult1_input_2 : complex_number;
  signal s_mult1_o : complex_number;
  signal s_mult2_input_1 : complex_number;
  signal s_mult2_input_2 : complex_number;
  signal s_mult2_o : complex_number;
  
  signal s_acc_1_i : complex_number;
  signal s_acc_2_i : complex_number;
  signal s_acc_1_o : complex_number;
  signal s_acc_2_o : complex_number;
  signal s_corr_total : complex_number;

  signal s_cmplx_mlt_dv_i : std_logic;
  signal s_cmplx_mlt_dv_o : std_logic;
  
  type t_state_type is (idle_st, s0_st, s1_st, s2_st);
  signal s_state : t_state_type;

  signal s_input_index  : unsigned(5 downto 0);
  signal s_output_index : unsigned(5 downto 0);
  
  signal s_real_array_1 : t_array_64;
  signal s_real_array_2 : t_array_64;
  signal s_array_2 : t_array_64;
begin

--  inst_complex_multiplier_1 : ces_math_lib.ces_math_fi_complex_mult
  inst_complex_multiplier_1: entity ces_math_lib.ces_math_fi_complex_mult
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_BIN_POINT  => G_BIN_POINT
    )
    port map (
      clk_i      => clk_i,
      dv_i       => s_cmplx_mlt_dv_i,
      real_1_i   => s_mult1_input_1.real_num,           -- Connect first real input
      imag_1_i   => s_mult1_input_1.imag_num,      -- Connect first imaginary input
      real_2_i   => s_mult1_input_2.real_num,           -- Connect second real input
      imag_2_i   => s_mult1_input_2.imag_num, -- Connect second imaginary input
      real_o     => s_mult1_o.real_num,    -- Connect output real part
      imag_o     => s_mult1_o.imag_num,     -- Connect output imaginary part
      dv_o       => s_cmplx_mlt_dv_o
    ); 
  
  inst_complex_multiplier_2: entity ces_math_lib.ces_math_fi_complex_mult
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_BIN_POINT  => G_BIN_POINT
    )
    port map (
      clk_i      => clk_i,
      dv_i       => s_cmplx_mlt_dv_i,
      real_1_i   => s_mult2_input_1.real_num,           -- Connect first real input
      imag_1_i   => s_mult2_input_1.imag_num,      -- Connect first imaginary input
      real_2_i   => s_mult2_input_2.real_num,           -- Connect second real input
      imag_2_i   => s_mult2_input_2.imag_num, -- Connect second imaginary input
      real_o     => s_mult2_o.real_num,    -- Connect output real part
      imag_o     => s_mult2_o.imag_num,     -- Connect output imaginary part
      dv_o       => open
    );
  
  s_acc_1_i <= s_acc_1_o when s_cmplx_mlt_dv_o='1' else (others=>(others=>'0'));
  
  inst_accumulator_1_real: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_mult1_o.real_num,
      din2_i    => s_acc_1_i.real_num,
      dout_o    => s_acc_1_o.real_num
    );

  inst_accumulator_1_imag: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_mult1_o.imag_num,
      din2_i    => s_acc_1_i.imag_num,
      dout_o    => s_acc_1_o.imag_num
    );    


  s_acc_2_i <= s_acc_2_o when s_cmplx_mlt_dv_o='1' else (others=>(others=>'0'));
  
  inst_accumulator_2_real: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_mult2_o.real_num,
      din2_i    => s_acc_2_i.real_num,
      dout_o    => s_acc_2_o.real_num
    );

   
  inst_accumulator_2_imag: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_mult2_o.imag_num,
      din2_i    => s_acc_2_i.imag_num,
      dout_o    => s_acc_2_o.imag_num
    );     

  inst_corr_total_real: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_acc_1_o.real_num,
      din2_i    => s_acc_2_o.real_num,
      dout_o    => s_corr_total.real_num
    ); 

  inst_corr_total_imag: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_acc_1_o.imag_num,
      din2_i    => s_acc_2_o.imag_num,
      dout_o    => s_corr_total.imag_num
    ); 
                     
  proc_fsm : process(clk_i)
  begin
  if rising_edge(clk_i)then
    if rstn_i='0' then
      s_cmplx_mlt_dv_i <= '0';
      s_mult1_input_1 <= (others=>(others=>'0'));
      s_mult1_input_2 <= (others=>(others=>'0'));
      s_mult2_input_1 <= (others=>(others=>'0'));
      s_mult2_input_2 <= (others=>(others=>'0'));
      s_state <= idle_st;
    else
      case s_state is
        when idle_st =>
          if dv_i = '1' then
            s_input_index  <= (others=>'0');
            s_output_index <= (others=>'0');
            s_state <= s0_st;
          end if;
        
        when s0_st =>
          s_cmplx_mlt_dv_i <= '1';
          s_input_index <= s_input_index + 1;
          s_mult1_input_1 <= rx_signal_i(to_integer(s_input_index));
          s_mult1_input_2 <= first_time_i(to_integer(s_input_index));
          
          s_mult2_input_1 <= delayed_rx_signal_i(to_integer(s_input_index));
          s_mult2_input_2 <= second_time_i(to_integer(s_input_index));
          
          if(s_input_index = 63)then
            s_state <= s1_st;
          end if;
         
       when s1_st =>
          s_cmplx_mlt_dv_i <= '0';
          if(s_cmplx_mlt_dv_o = '0')then
            s_state <= s2_st;
          end if;
          
        when s2_st =>
             corr_total_o<= s_corr_total;             
             dv_o <= '1';
           
           s_state <= idle_st;
      end case;
    end if;
  end if;
  end process;        
end Behavioral;
