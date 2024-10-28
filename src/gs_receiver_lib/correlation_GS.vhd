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
    sync_i   : in std_logic;
    first_time_i  : in fi_complex_number;
    second_time_i : in fi_complex_number;
    rx_signal_i   : in fi_complex_number;
    corr_total_o : out fi_complex_number;
    dv_o : out std_logic
    );
end correlation_GS;

architecture Behavioral of correlation_GS is
  constant C_LATENCY    : natural := 6;
  
  type t_array_75 is array(0 to 74) of fi_complex_number;
  
  signal s_delay_buff : t_array_75;
  signal s_corr_1 : fi_complex_number;
  signal s_corr_2 : fi_complex_number;
  
  signal s_corr_dv : std_logic;
  signal s_sum_ena : std_logic;
  signal s_corr_total : fi_complex_number;
  
begin

  inst_XCORR_1: gs_receiver_lib.XCORR
    generic map (
      G_DATA_WIDTH => 32,
      G_BIN_POINT  => 16
    )
    port map (
      rstn_i => rstn_i,
      clk_i  => clk_i,
      sync_i => sync_i,
      din1_i => s_delay_buff(74),
      din2_i => first_time_i,
      data_o => s_corr_1,
      dv_o   => s_corr_dv
    );

  inst_XCORR_2: gs_receiver_lib.XCORR
    generic map (
      G_DATA_WIDTH => 32,
      G_BIN_POINT  => 16
    )
    port map (
      rstn_i => rstn_i,
      clk_i  => clk_i,
      sync_i => sync_i,
      din1_i => rx_signal_i,
      din2_i => second_time_i,
      data_o => s_corr_2,
      dv_o   => open
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
      din1_i    => s_corr_1.real_num,
      din2_i    => s_corr_2.real_num,
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
      din1_i    => s_corr_1.imag_num,
      din2_i    => s_corr_2.imag_num,
      dout_o    => s_corr_total.imag_num
    ); 


  proc_delay_buffer: process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        s_delay_buff <= (others=>(others=>(others=>'0')));
      else
        s_delay_buff <= s_delay_buff(73 downto 0) & rx_signal_i;
      end if;
    end if;
  end process proc_delay_buffer;   
  
  proc_output: process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        dv_o <= '0';
        s_sum_ena <= '0';
        corr_total_o <= (others=>(others=>'0'));
      else
        s_sum_ena <= s_corr_dv;
        if(s_sum_ena='1')then
          corr_total_o <= s_corr_total;
          dv_o <= '1';
        else
          dv_o   <= '0';
        end if;
      end if;
    end if;
  end process proc_output;                           
end Behavioral;
