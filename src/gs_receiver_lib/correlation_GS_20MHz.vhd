library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std.all;
use std.env.all;
library std;
use std.textio.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;

library gs_receiver_lib;
use gs_receiver_lib.gs_receiver_pkg.all;

entity correlation_GS_20MHz is
  generic (
    G_COEFF_DATA_WIDTH    : integer := 20;
    G_COEFF_BIN_POINT     : integer := 19;
    G_OUTPUT_DATA_WIDTH   : integer := 32;  -- Width of the input and output data
    G_OUTPUT_BIN_POINT    : integer := 22    -- Binary point for fixed-point representation
    );
  port ( 
    clk_i : in std_logic;
    rstn_i : in std_logic;
    corr_total_i : in std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
    corr_1_20MHz_o : out std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0)
    
    );
end correlation_GS_20MHz;

architecture Behavioral of correlation_GS_20MHz is

  --* fi(1, 16, 15)
  type t_coeff_array is array(0 to 256) of std_logic_vector(G_COEFF_DATA_WIDTH-1 downto 0);
  
  type t_data_array is array(natural range <>) of std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
--  type t_data_array_127  is array(0 to 127) of std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
  
  function init_array_from_hex(file_name: string) return t_coeff_array is
      file hex_file: TEXT open READ_MODE is file_name;
      variable line_buf : line;
      variable hex_value : std_logic_vector(G_COEFF_DATA_WIDTH-1 downto 0);  -- Assuming each hex value is 8 characters (32 bits)
      variable v_array : t_coeff_array;
      variable i : integer := 0;
  begin
      
      -- Read each line from the file
      while not endfile(hex_file) loop
          readline(hex_file, line_buf);
          HREAD(line_buf, v_array(i));
          i := i + 1;
      end loop;
  
      -- Close the file
      file_close(hex_file);
  
      return v_array; 
  end function init_array_from_hex;
  

--  signal s_filter_up_corr1 : t_coeff_array := init_array_from_hex("D:\Vivado_projects\receiver_gs\receiver_gs.srcs\sources_1\imports\MATLAB\Filter_up_corr1.txt");
  signal s_filter_up_corr1 : t_coeff_array := init_array_from_hex("D:\Vivado_projects\receiver_gs\receiver_gs.srcs\sources_1\imports\code_receiver_gs\Filter_up_corr1.txt");
  signal s_corr_1_zp : t_data_array(0 to 256);
  signal s_mult_o   : t_data_array(0 to 256);
  signal s_add_stg1 : t_data_array(0 to 127);-- 128
  signal s_add_stg2 : t_data_array(0 to 63); -- 64
  signal s_add_stg3 : t_data_array(0 to 31); -- 32
  signal s_add_stg4 : t_data_array(0 to 15);
  signal s_add_stg5 : t_data_array(0 to 7);
  signal s_add_stg6 : t_data_array(0 to 3);
  signal s_add_stg7 : t_data_array(0 to 1);
  
  signal s_add_stg8        : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
  signal s_delay_buff      : t_data_array(0 to 7);
  signal s_delayed_element : std_logic_vector(G_OUTPUT_DATA_WIDTH-1 downto 0);
  
--  attribute use_dsp48 : string;
--  attribute use_dsp48 of s_add_stg1 : signal is "no";
--  attribute use_dsp48 of s_add_stg3 : signal is "no";
--  attribute use_dsp48 of s_add_stg5 : signal is "no";
  
  
begin

  proc_upsample : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rstn_i='0' then
        s_corr_1_zp  <= (others=>(others=>'0'));
        s_delay_buff <= (others=>(others=>'0'));
      else
        s_delay_buff <= s_mult_o(256) & s_delay_buff(0 to 6);
        
        s_corr_1_zp(0 to 30)   <= (others=>(others=>'0'));
        s_corr_1_zp(31)        <= corr_total_i;
        s_corr_1_zp(32 to 256) <= s_corr_1_zp(0 to 224);
      end if;
    end if;
  end process;
  
  --------------------------------------------------------
  --*                 FIR Filter
  --------------------------------------------------------
  
  --* 257 multiplier
  gen_mult_array : For i in 0 to 256 generate
  inst_mul_array: entity ces_math_lib.ces_math_fi_mult
      generic map (
          g_din_a_w      => G_OUTPUT_DATA_WIDTH,   -- Input width for real numbers
          g_din_a_binpnt => G_OUTPUT_BIN_POINT,     -- Input binary point for real numbers
          g_din_b_w      => G_COEFF_DATA_WIDTH,   -- Input width for real numbers
          g_din_b_binpnt => G_COEFF_BIN_POINT,    -- Input binary point for real numbers
          g_dout_w       => G_OUTPUT_DATA_WIDTH,   -- Output width for multiplication
          g_dout_binpnt  => G_OUTPUT_BIN_POINT      -- Output binary point for multiplication
      )
      port map (
          clk_i  => clk_i,
          din1_i => s_corr_1_zp(i),
          din2_i => s_filter_up_corr1(i),
          dout_o => s_mult_o(i)
      );
  end generate gen_mult_array;
  
  --* adder tree
  gen_adder_array_stg1 : for i in 0 to 127 generate
    inst_ces_math_fi_add_sub: entity ces_math_lib.ces_math_fi_add_sub
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
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_mult_o(i*2),
            din2_i    => s_mult_o((i*2)+1),
            dout_o    => s_add_stg1(i)
        );    
  end generate gen_adder_array_stg1;
  
  gen_adder_array_stg2 : for i in 0 to 63 generate
    inst_ces_math_fi_add_sub: entity ces_math_lib.ces_math_fi_add_sub
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
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_add_stg1(i*2),
            din2_i    => s_add_stg1((i*2)+1),
            dout_o    => s_add_stg2(i)
        );    
  end generate gen_adder_array_stg2;
  
  gen_adder_array_stg3 : for i in 0 to 31 generate
    inst_ces_math_fi_add_sub: entity ces_math_lib.ces_math_fi_add_sub
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
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_add_stg2(i*2),
            din2_i    => s_add_stg2((i*2)+1),
            dout_o    => s_add_stg3(i)
        );    
  end generate gen_adder_array_stg3;
  
  gen_adder_array_stg4 : for i in 0 to 15 generate
    inst_ces_math_fi_add_sub: entity ces_math_lib.ces_math_fi_add_sub
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
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_add_stg3(i*2),
            din2_i    => s_add_stg3((i*2)+1),
            dout_o    => s_add_stg4(i)
        );    
  end generate gen_adder_array_stg4;
  
  gen_adder_array_stg5 : for i in 0 to 7 generate
    inst_ces_math_fi_add_sub: entity ces_math_lib.ces_math_fi_add_sub
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
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_add_stg4(i*2),
            din2_i    => s_add_stg4((i*2)+1),
            dout_o    => s_add_stg5(i)
        );    
  end generate gen_adder_array_stg5;
  
  
  gen_adder_array_stg6 : for i in 0 to 3 generate
    inst_ces_math_fi_add_sub: entity ces_math_lib.ces_math_fi_add_sub
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
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_add_stg5(i*2),
            din2_i    => s_add_stg5((i*2)+1),
            dout_o    => s_add_stg6(i)
        );    
  end generate gen_adder_array_stg6;
  
  gen_adder_array_stg7 : for i in 0 to 1 generate
    inst_ces_math_fi_add_sub: entity ces_math_lib.ces_math_fi_add_sub
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
        port map (
            clk_i     => clk_i,
            ce_i      => '1', -- Clock enable
            din1_i    => s_add_stg6(i*2),
            din2_i    => s_add_stg6((i*2)+1),
            dout_o    => s_add_stg7(i)
        );    
  end generate gen_adder_array_stg7;
  
  gen_adder_array_stg8: entity ces_math_lib.ces_math_fi_add_sub
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
      port map (
          clk_i     => clk_i,
          ce_i      => '1', -- Clock enable
          din1_i    => s_add_stg7(0),
          din2_i    => s_add_stg7(1),
          dout_o    => s_add_stg8
      ); 
      
  int_output_add : entity ces_math_lib.ces_math_fi_add_sub
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
      port map (
          clk_i     => clk_i,
          ce_i      => '1', -- Clock enable
          din1_i    => s_add_stg8,
          din2_i    => s_delay_buff(7),
          dout_o    => corr_1_20MHz_o
      );
end Behavioral;
