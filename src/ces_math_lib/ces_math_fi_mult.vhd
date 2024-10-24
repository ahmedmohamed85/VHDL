--=============================================================================
-- Module Name  : ces_math_fi_mult
-- Library      : ces_math_lib
-- Project      : CES MATH
-- Company      : Campera Electronic Systems Srl
-- Author       : A.Campera
-------------------------------------------------------------------------------
-- Description:   fixed point multiplier
--
--
-------------------------------------------------------------------------------
-- (c) Copyright 2014 Campera Electronic Systems Srl. Via Aurelia 136, Stagno
-- (Livorno), 57122, Italy. <www.campera-es.com>. All rights reserved.
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
-------------------------------------------------------------------------------
-- Revision History:
-- Date          Version    Author         Description
-- 21/10/2014    1.0.0      A.Campera      Initial release
-- 18/05/2017    1.0.0      MCO           Reset cancelled (non used in this type
--                                        of module), or updated to new g_rst when
--                                        present in a called entity.
-- 19/12/2017   1.1.0     ACA         only synchronous reset supported, generic
--                                    used to define the reset level
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
entity ces_math_fi_mult is
  generic(
    g_din_a_w      : natural   := 24;   --* input a width
    g_din_a_binpnt : natural   := 0;    --* input a binary point
    g_din_b_w      : natural   := 24;   --* input b width
    g_din_b_binpnt : natural   := 0;    --* input b binary point
    g_dout_w       : natural   := 48;   --* output c width
    g_dout_binpnt  : natural   := 0;    --* output c binary point
    g_round_mode   : integer   := C_CES_TRUNC;   --* output rounding mode
    g_din_a_type   : integer   := C_CES_SIGNED;  --* input a type
    g_din_b_type   : integer   := C_CES_SIGNED;  --* input b type
    g_dout_type    : integer   := C_CES_SIGNED;  --* output c type   
    --* number of pipeline stages
    g_pipe_stages  : integer   := 3
    );
  port(
    clk_i  : in  std_logic;             --* input clock
    din1_i : in  std_logic_vector(g_din_a_w - 1 downto 0);  --* input a
    din2_i : in  std_logic_vector(g_din_b_w - 1 downto 0);  --* input b
    dout_o : out std_logic_vector(g_dout_w - 1 downto 0)    --* output c = a*b
    );

end ces_math_fi_mult;

architecture a_rtl of ces_math_fi_mult is

  -------------------------------------------------------------------------------
  -- constants definition
  -------------------------------------------------------------------------------
  constant C_MULT_WIDTH  : natural := g_din_a_w + g_din_b_w;
  constant c_MAX_WIDTH   : natural := f_max(g_din_a_w,g_din_b_w);
  -------------------------------------------------------------------------------
  -- types definition
  -------------------------------------------------------------------------------
  type t_pipe is array (0 to g_pipe_stages) of std_logic_vector(C_MULT_WIDTH - 1 downto 0);
  -------------------------------------------------------------------------------
  -- signals definition
  -------------------------------------------------------------------------------
  signal s_pipe_reg      : t_pipe := (others => (others  => '0'));      -- basic pipeline register
  -- internal regster to store multiplication result
  signal s_dout_reg      : std_logic_vector(C_MULT_WIDTH - 1 downto 0):=(others  => '0');
  signal s_typesel       : integer range 1 to 4;
  signal din1_uns_tmp    : unsigned(C_MAX_WIDTH-1 downto 0):=(others  => '0');
  signal din1_sig_tmp    : signed(C_MAX_WIDTH-1 downto 0):=(others  => '0');
  signal din2_uns_tmp    : unsigned(C_MAX_WIDTH-1 downto 0):=(others  => '0');
  signal din2_sig_tmp    : signed(C_MAX_WIDTH-1 downto 0):=(others  => '0');

begin

  din1_uns_tmp <= resize(unsigned(din1_i),C_MAX_WIDTH);
  din1_sig_tmp <= resize(signed(din1_i),C_MAX_WIDTH);

  din2_uns_tmp <= resize(unsigned(din2_i),C_MAX_WIDTH);
  din2_sig_tmp <= resize(signed(din2_i),C_MAX_WIDTH);

  -- input type selector
  -- typesel = 1 if a type is signes and b type is signed
  -- typesel = 2 if a type is signes and b type is unsigned
  -- typesel = 3 if a type is unsignes and b type is signed
  -- typesel = 4 if a type is unsignes and b type is unsigned
  s_typesel <= 1 when (g_din_a_type = C_CES_SIGNED and g_din_b_type = C_CES_SIGNED)
               else 2 when (g_din_a_type = C_CES_SIGNED and g_din_b_type = C_CES_UNSIGNED)
               else 3 when (g_din_a_type = C_CES_UNSIGNED and g_din_b_type = C_CES_SIGNED)
               else 4 when (g_din_a_type = C_CES_UNSIGNED and g_din_b_type = C_CES_UNSIGNED);

  proc_mult : process(clk_i)
  begin  -- process mult_proc
    if rising_edge(clk_i) then
        case s_typesel is
          when 1 =>
            s_dout_reg <= std_logic_vector(resize(din1_sig_tmp * din2_sig_tmp,s_dout_reg'length));
          when 2 =>
            s_dout_reg <= std_logic_vector(resize(din1_sig_tmp * signed(din2_uns_tmp),s_dout_reg'length));
          when 3 =>
            s_dout_reg <= std_logic_vector(resize(signed(din1_uns_tmp) * din2_sig_tmp,s_dout_reg'length));
          when 4 =>
            s_dout_reg <= std_logic_vector(resize(din1_uns_tmp * din2_uns_tmp,s_dout_reg'length));
          when others =>
            s_dout_reg <= std_logic_vector(resize(din1_sig_tmp * din2_sig_tmp,s_dout_reg'length));
        end case;
    end if;
  end process proc_mult;

  -- pipeline registers instantiation
  s_pipe_reg(0) <= s_dout_reg;
  gen_pipe_regs : for i in 1 to g_pipe_stages generate
    proc_pipe : process(clk_i)
    begin
      if rising_edge(clk_i) then
          s_pipe_reg(i) <= s_pipe_reg(i - 1);
      end if;
    end process proc_pipe;
  end generate gen_pipe_regs;

  -- output pipeline connection
  gen_trunc : if g_round_mode = C_CES_TRUNC generate
    dout_o <= f_trunc(s_pipe_reg(g_pipe_stages), g_din_a_w + g_din_b_w, g_din_a_binpnt + g_din_b_binpnt, g_din_a_type, g_dout_w, g_dout_binpnt, g_dout_type);
  end generate gen_trunc;
  gen_round : if g_round_mode = C_CES_ROUND generate
    dout_o <= f_round_towards_even(s_pipe_reg(g_pipe_stages), g_din_a_w + g_din_b_w, g_din_a_binpnt + g_din_b_binpnt, g_din_a_type, g_dout_w, g_dout_binpnt, g_dout_type);
  end generate gen_round;

end a_rtl;
