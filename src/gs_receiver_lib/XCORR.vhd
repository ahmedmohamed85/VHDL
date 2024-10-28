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

entity XCORR is
  generic (
    G_DATA_WIDTH   : integer := 32;  -- Width of the input and output data
    G_BIN_POINT    : integer := 16    -- Binary point for fixed-point representation
    );
  Port ( 
    rstn_i : in std_logic;
    clk_i  : in std_logic;
    sync_i   : in std_logic;
    din1_i : in fi_complex_number;
    din2_i : in fi_complex_number;
    data_o : out fi_complex_number;
    dv_o : out std_logic
    );
end XCORR;

architecture Behavioral of XCORR is
  signal s_mult_o : fi_complex_number;
  signal s_cmplx_mlt_dv_o : std_logic;
  signal s_acc_i : fi_complex_number;
  signal s_acc_o : fi_complex_number;
begin

  inst_complex_multiplier_1: entity ces_math_lib.ces_math_fi_complex_mult
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_BIN_POINT  => G_BIN_POINT
    )
    port map (
      clk_i      => clk_i,
      dv_i       => sync_i,
      real_1_i   => din1_i.real_num,           -- Connect first real input
      imag_1_i   => din1_i.imag_num,      -- Connect first imaginary input
      real_2_i   => din2_i.real_num,           -- Connect second real input
      imag_2_i   => din2_i.imag_num, -- Connect second imaginary input
      real_o     => s_mult_o.real_num,    -- Connect output real part
      imag_o     => s_mult_o.imag_num,     -- Connect output imaginary part
      dv_o       => s_cmplx_mlt_dv_o
    ); 
    
  s_acc_i <= (others=>(others=>'0')) when s_cmplx_mlt_dv_o='1' else s_acc_o;
  
  inst_accumulator_real: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_mult_o.real_num,
      din2_i    => s_acc_i.real_num,
      dout_o    => s_acc_o.real_num
    );
    
  inst_accumulator_imag: entity ces_math_lib.ces_math_fi_add_sub
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
      din1_i    => s_mult_o.imag_num,
      din2_i    => s_acc_i.imag_num,
      dout_o    => s_acc_o.imag_num
    ); 
    
  proc_output: process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        dv_o <= '0';
        data_o <= (others=>(others=>'0'));
      else
        if(s_cmplx_mlt_dv_o='1')then
          data_o <= s_acc_o;
          dv_o <= '1';
        else
          dv_o   <= '0';
        end if;
      end if;
    end if;
  end process proc_output;
  
end Behavioral;
