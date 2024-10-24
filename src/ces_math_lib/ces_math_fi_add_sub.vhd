--=============================================================================
-- Module Name : ces_math_fi_add_sub
-- Library     : ces_math_lib
-- Project     : CES MATH
-- Company     : Campera Electronic Systems Srl
-- Author      : A.Campera, C.Gerval
-------------------------------------------------------------------------------
-- Description:   entity declaration of common_fi_add_sub. On the basis of
-- g_direction it can implement sum or subtraction (or both).
-- depending on g_direction and sel_add_i, perform dout_o=din1_i+din2_i or
-- dout_o=din1_i-din2_i in fixed-point number for signed
-- or unsigned representation of data
-------------------------------------------------------------------------------
-- (c) Copyright 2014 Campera Electronic Systems Srl. Via Aurelia 136, Stagno
-- (Livorno), 57122, Italy. <www.campera-es.com>. All rights reserved.
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
-------------------------------------------------------------------------------
-- Revision History:
-- Date        Version  Author    Description
-- 2015/05/25  1.0.0    C.Gerval  Initial release
-- 18/05/2017  1.0.0    MCO       Reset cancelled (non used in this type
--                                of module), or updated to new g_rst when
--                                present in a called entity.
-- 19/12/2017  1.1.0    ACA       Only synchronous reset supported, generic
--                                used to define the reset level.
--
--=============================================================================

-------------------------------------------------------------------------------
-- LIBRARIES
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;
library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;

-------------------------------------------------------------------------------
-- ENTITY
---------------------------------------------------------------------------------
--* @brief entity declaration of common_fi_add_sub. On the basis of
--* g_direction it can implement sum or subtraction (or both).
--* depending on g_direction and sel_add_i, perform dout_o=din1_i+din2_i or
--* dout_o=din1_i-din2_i in fixed-point number for signed
--* or unsigned representation of data
entity ces_math_fi_add_sub is
  generic(
    --* or C_CES_SUB, or C_CES_ADDSUB and use sel_add_i
    g_direction       : integer   := C_CES_ADD;
    --* Representation of signals: C_CES_SIGNED or C_CES_UNSIGNED
    g_representation  : natural   := C_CES_SIGNED;
    --* 0 or 1, number of register
    g_pipeline_input  : natural   := 0;
    --* >= 0, delay value
    g_pipeline_output : natural   := 1;
    --* size of input 1
    g_din1_w          : natural   := 8;
    --* binary point of input 1
    g_din1_binpnt     : natural   := 2;
    --* size of input 2
    g_din2_w          : natural   := 8;
    --* binary point of input 2
    g_din2_binpnt     : natural   := 2;
    --* binary point of input 1
    g_dout_w          : natural   := 9;
    --* binary point of output
    g_dout_binpnt     : natural   := 2;
    --* rounding mode: round (C_CES_ROUND) or truncate (C_CES_TRUNC)
    g_round_mode      : natural   := C_CES_TRUNC
    );
  port(
    --* Global clock signal
    clk_i     : in  std_logic;
    --* Clock enable: '1' when new input samples are written
    ce_i      : in  std_logic;
    --* only used for g_direction C_CES_ADDSUB
    sel_add_i : in  std_logic := '1';
    --* input 1
    din1_i    : in  std_logic_vector(g_din1_w - 1 downto 0);
    --* input 2
    din2_i    : in  std_logic_vector(g_din2_w - 1 downto 0);
    --* output (if input 1 < input 2 and g_representation=UNSIGNED, then output=input 1 - input 2 is true in signed representation
    dout_o    : out std_logic_vector(g_dout_w - 1 downto 0)
    );
end ces_math_fi_add_sub;

-------------------------------------------------------------------------------
-- ARCHITECTURE
-------------------------------------------------------------------------------
architecture a_rtl of ces_math_fi_add_sub is

  --* binary point in full-precision
  constant C_RES_BINPNT : natural := f_max(g_din1_binpnt, g_din2_binpnt);
  --* size of the result in full-precision
  constant C_RES_W      : natural := f_max(g_din1_w - g_din1_binpnt, g_din2_w - g_din2_binpnt) + C_RES_BINPNT + 1;

  --* Pipelined input 1
  signal s_din1_p       : std_logic_vector(din1_i'range);
  --* Pipelinde input 2
  signal s_din2_p       : std_logic_vector(din2_i'range);
  --* Direction flag
  signal s_in_add       : std_logic;
  --* Input direction
  signal s_sel_add_i_p  : std_logic;
  --* Input 1 formated after pipeline
  signal s_din1_tmp     : std_logic_vector(C_RES_W - 1 downto 0);
  --* Input 2 formated after pipeline
  signal s_din2_tmp     : std_logic_vector(C_RES_W - 1 downto 0);
  --* Output formated after pipeline
  signal s_result_inf_p : std_logic_vector(C_RES_W - 1 downto 0);
  --* Output formated without pipeline
  signal s_result_tmp   : std_logic_vector(C_RES_W - 1 downto 0);

begin  -- Begin architecture a_rtl

  -- Flag to choose to add or to substract
  s_in_add <= '1' when g_direction = C_CES_ADD or (g_direction = C_CES_ADDSUB and sel_add_i = '1') else '0';
  --* Wired input
  gen_no_input_reg : if g_pipeline_input = 0 generate
    s_din1_p      <= din1_i;
    s_din2_p      <= din2_i;
    s_sel_add_i_p <= s_in_add;
  end generate gen_no_input_reg;
  --* register input
  gen_input_reg : if g_pipeline_input > 0 generate
    proc_reg : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if ce_i = '1' then
          s_din1_p      <= din1_i;
          s_din2_p      <= din2_i;
          s_sel_add_i_p <= s_in_add;
        end if;
      end if;
    end process proc_reg;
  end generate gen_input_reg;
  --* Format input 1
  --  inst_format_din1 : entity ces_math_lib.ces_math_format_comb
  --    generic map(
  --      g_din_w          => g_din1_w,
  --      g_din_binpnt     => g_din1_binpnt,
  --      g_dout_w         => C_RES_W,
  --      g_dout_binpnt    => C_RES_BINPNT,
  --      g_round_mode     => g_round_mode,
  --      g_representation => g_representation
  --      )
  --    port map(
  --      din_i  => s_din1_p,
  --      dout_o => s_din1_tmp
  --      );
  s_din1_tmp <= f_convert_type (s_din1_p, g_din1_w, g_din1_binpnt,

  g_representation, C_RES_W, C_RES_BINPNT, g_representation,
  g_round_mode,
  C_CES_WRAP);
  --* Format input 2
  --  inst_format_din2 : entity ces_math_lib.ces_math_format_comb
  --    generic map(
  --      g_din_w          => g_din2_w,
  --      g_din_binpnt     => g_din2_binpnt,
  --      g_dout_w         => C_RES_W,
  --      g_dout_binpnt    => C_RES_BINPNT,
  --      g_round_mode     => g_round_mode,
  --      g_representation => g_representation
  --      )
  --    port map(
  --      din_i  => s_din2_p,
  --      dout_o => s_din2_tmp
  --      );
  s_din2_tmp <= f_convert_type (s_din2_p, g_din2_w, g_din2_binpnt,

  g_representation, C_RES_W, C_RES_BINPNT, g_representation,
  g_round_mode,
  C_CES_WRAP);
  --* Add/sub depending on the representation of data
  gen_signed : if g_representation = C_CES_SIGNED generate
    s_result_tmp <= f_add_sig(s_din1_tmp, s_din2_tmp, C_RES_W) when s_sel_add_i_p = '1'
    else f_sub_sig(s_din1_tmp, s_din2_tmp, C_RES_W);
  end generate gen_signed;
  gen_unsigned : if g_representation = C_CES_UNSIGNED generate
    s_result_tmp <= f_add_uns(s_din1_tmp, s_din2_tmp, C_RES_W) when s_sel_add_i_p = '1'
    else f_sub_uns(s_din1_tmp, s_din2_tmp, C_RES_W);
  end generate gen_unsigned;
  --* Format output / pipeline, depending on the size of the output to reduce the size of the memory (3 cases)
  --* First case: if the output is not in full precision, truncate or round the result s_result_tmp depending on g_round_mode before storage
  gen_output_pipe_format : if g_dout_w < C_RES_W generate
    --* Truncate or round output
    inst_format_result : entity work.ces_math_fi_format
    generic map(
      g_din_w          => C_RES_W,
      g_din_binpnt     => C_RES_BINPNT,
      g_dout_w         => g_dout_w,
      g_pipe_stages    => g_pipeline_output,
      g_dout_binpnt    => g_dout_binpnt,
      g_round_mode     => g_round_mode,
      g_overflow => C_CES_WRAP,
      g_representation => g_representation
      )
    port map(
      clk_i  => clk_i,
      din_i  => s_result_tmp,
      dout_o => dout_o
      );
  end generate gen_output_pipe_format;
  --* Second case: if the size of output is larger than in full precision, format the output after storage
  gen_output_format_pipe : if g_dout_w >= C_RES_W generate
    --*pipeline
    inst_output_format_pipe : entity ces_util_lib.ces_util_delay
    generic map(
      g_delay   => g_pipeline_output,
      g_data_w  => C_RES_W
      )
    port map(
      clk_i  => clk_i,
      din_i  => s_result_tmp,
      dout_o => s_result_inf_p
      );
    --* format output
    --    inst_format_dout : entity ces_math_lib.ces_math_format_comb
    --      generic map(
    --        g_din_w          => C_RES_W,
    --        g_din_binpnt     => C_RES_BINPNT,
    --        g_dout_w         => g_dout_w,
    --        g_dout_binpnt    => g_dout_binpnt,
    --        g_round_mode     => g_round_mode,
    --        g_representation => g_representation
    --        )
    --      port map(
    --        din_i  => s_result_inf_p,
    --        dout_o => dout_o
    --        );

    dout_o <= f_convert_type (s_result_inf_p, C_RES_W, C_RES_BINPNT,
    g_representation, g_dout_w, g_dout_binpnt, g_representation,
    g_round_mode,
    C_CES_WRAP);
  end generate gen_output_format_pipe;

end a_rtl;
