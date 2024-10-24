--=============================================================================
-- Module Name  : ces_math_fi_mult_add
-- Library      : ces_math_lib
-- Project      : CES MATH
-- Company      : Campera Electronic Systems Srl
-- Author       : A.Campera
-------------------------------------------------------------------------------
-- Description:   fixed point multiplier and adder (MAC)
--
--
-------------------------------------------------------------------------------
-- (c) Copyright 2014 Campera Electronic Systems Srl. Via Aurelia 136, Stagno
-- (Livorno), 57122, Italy. <www.campera-es.com>. All rights reserved.
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
-------------------------------------------------------------------------------
-- Revision History:
-- Date          Version   Author      Description
-- 21/10/2014    1.0.0     A.Campera   Initial release
--
-- 18/05/2017    1.0.0     MCO         Reset cancelled (non used in this type
--                                     of module), or updated to new g_rst when
--                                     present in a called entity.
--
-- 19/12/2017    1.1.0     ACA         Only synchronous reset supported, generic
--                                     used to define the reset level.
--
--=============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

-------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------
--* @brief fixed point multiplier
entity ces_math_fi_mult_add is
  generic(
    g_din_a_w          : natural   := 24;   --* input a width
    g_din_a_binpnt     : natural   := 15;    --* input a binary point
    g_din_b_w          : natural   := 18;   --* input b width
    g_din_b_binpnt     : natural   := 12;    --* input b binary point
    g_din_c_w          : natural   := 46;   --* input c width
    g_din_c_binpnt     : natural   := 27;    --* input c binary point
    g_dout_w           : natural   := 46;   --* output d width
    g_dout_binpnt      : natural   := 27;    --* output d binary point
    g_add_sub          : natural   := C_CES_ADD;    --* C_CES_ADD or C_CES_SUB
    g_round_mode       : integer   := C_CES_ROUND;   --* output rounding mode
    g_representation   : integer   := C_CES_SIGNED;  --* input a type
    g_overflow         : natural   := C_CES_WRAP;    --* Overflow style: C_CES_SATURATE or C_CES_WRAP
    --* number of pipeline stages
    g_pipe_stages      : natural   := 3
    );
  port(
    clk_i  : in  std_logic;             --* input clock
    din1_i : in  std_logic_vector(g_din_a_w - 1 downto 0);  --* input a
    din2_i : in  std_logic_vector(g_din_b_w - 1 downto 0);  --* input b
    din3_i : in  std_logic_vector(g_din_c_w - 1 downto 0);  --* input c
    dout_o : out std_logic_vector(g_dout_w - 1 downto 0) := (others => '0')    --* output d = a*b+c
    );

end ces_math_fi_mult_add;

architecture a_rtl of ces_math_fi_mult_add is

  -------------------------------------------------------------------------------
  -- constants definition
  -------------------------------------------------------------------------------
  constant C_MULT_BINPNT : natural := g_din_a_binpnt + g_din_b_binpnt;
  constant C_MULT_WIDTH  : natural := g_din_a_w + g_din_b_w;

  constant C_SUM_W       : natural := C_MULT_WIDTH+1 ; --f_sel_a_b( g_dout_w<C_MULT_WIDTH + 1, C_MULT_WIDTH + 1 , g_dout_w);
  -------------------------------------------------------------------------------
  -- types definition
  -------------------------------------------------------------------------------
  type t_pipe is array (0 to g_pipe_stages) of std_logic_vector(C_SUM_W - 1 downto 0);
  -------------------------------------------------------------------------------
  -- signals definition
  -------------------------------------------------------------------------------
  signal s_prod          : std_logic_vector(C_MULT_WIDTH - 1 downto 0) := (others => '0');
  signal s_din3          : std_logic_vector(g_din_c_w - 1 downto 0) := (others => '0');
  signal s_sum           : std_logic_vector(C_SUM_W - 1 downto 0) := (others => '0');

  signal s_pipe_reg      : t_pipe := (others => (others => '0'));      -- basic pipeline register
  signal s_typesel       : integer;

  attribute use_dsp48 : string;
  attribute use_dsp48 of s_sum : signal is "yes";

begin

  -- input type selector
  -- typesel = 0 if type is signed
  -- typesel = 1 if type is unsigned
  s_typesel <= 0 when (g_representation = C_CES_SIGNED) else 1 when (g_representation = C_CES_UNSIGNED);

  proc_mult : process(clk_i)
  begin  -- process mult_proc
    if rising_edge(clk_i) then
        case s_typesel is
          when 0 =>
          s_prod <= std_logic_vector(signed(din1_i) * signed(din2_i)) ;
          when 1 =>
          s_prod <= std_logic_vector(unsigned(din1_i) * unsigned(din2_i));
          when others =>
          s_prod <= std_logic_vector(signed(din1_i) * signed(din2_i));
        end case;

        --s_din3 <= f_convert_type (din3_i, g_din_c_w, g_din_c_binpnt,
        --                   g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
        --                   g_round_mode,
        --                   g_overflow);

        s_din3 <= din3_i;
    end if;
  end process proc_mult;

  add_gen : if g_add_sub = C_CES_ADD generate
    gen_signed_sum: if g_representation = C_CES_SIGNED generate
      s_sum <= 	std_logic_vector(
      signed(f_convert_type (s_prod, C_MULT_WIDTH, C_MULT_BINPNT,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      + signed(f_convert_type (s_din3, g_din_c_w, g_din_c_binpnt,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      );
    end generate gen_signed_sum;
    gen_unsigned_sum: if g_representation = C_CES_UNSIGNED generate
      s_sum <= std_logic_vector(
      unsigned(f_convert_type (s_prod, C_MULT_WIDTH, C_MULT_BINPNT,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      + unsigned(f_convert_type (s_din3, g_din_c_w, g_din_c_binpnt,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      );
    end generate gen_unsigned_sum;
  end generate add_gen;

  sub_gen : if g_add_sub = C_CES_SUB generate
    gen_signed_sub: if g_representation = C_CES_SIGNED generate
      s_sum <= std_logic_vector(
      signed(f_convert_type (s_prod, C_MULT_WIDTH, C_MULT_BINPNT,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      - signed(f_convert_type (s_din3, g_din_c_w, g_din_c_binpnt,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      );
    end generate gen_signed_sub;
    gen_unsigned_sub: if g_representation = C_CES_UNSIGNED generate
      s_sum <= std_logic_vector(
      unsigned(f_convert_type (s_prod, C_MULT_WIDTH, C_MULT_BINPNT,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      - unsigned(f_convert_type (s_din3, g_din_c_w, g_din_c_binpnt,
      g_representation, C_SUM_W, C_MULT_BINPNT, g_representation,
      C_CES_TRUNC,
      C_CES_WRAP))
      );
    end generate gen_unsigned_sub;
  end generate sub_gen;

  -- pipeline registers instantiation
  s_pipe_reg(0) <= s_sum;
  gen_pipe_regs : for i in 1 to g_pipe_stages generate
    proc_pipe : process(clk_i)
    begin
      if rising_edge(clk_i) then
          s_pipe_reg(i) <= s_pipe_reg(i - 1);
      end if;
    end process proc_pipe;
  end generate gen_pipe_regs;


  dout_o <= f_convert_type (s_pipe_reg(g_pipe_stages), C_SUM_W, C_MULT_BINPNT,
  g_representation, g_dout_w, g_dout_binpnt, g_representation,
  g_round_mode,
  g_overflow);

end a_rtl;
