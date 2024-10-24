--=============================================================================
-- Module Name : ces_math_divider
-- Library     : ces_math_lib
-- Project     : CES MATH
-- Company     : Campera Electronic Systems Srl
-- Author      : A.Campera
-------------------------------------------------------------------------------
-- Description: fixed point divider module  A/B with quotient and remainder
--
--
-------------------------------------------------------------------------------
-- (c) Copyright 2014 Campera Electronic Systems Srl. Via Aurelia 136, Stagno
-- (Livorno), 57122, Italy. <www.campera-es.com>. All rights reserved.
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
-------------------------------------------------------------------------------
-- Revision History:
-- Date        Version  Author         Description
-- 13/09/2015  1.0.0    ACA           initial release
-- 18/05/2017  1.0.0    MCO           Reset cancelled (non used in this type
--                                    of module), or updated to new g_rst when
--                                    present in a called entity. 
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
--* @brief divider unsigned by unsigned  A/B with quotient and remainder
entity ces_math_fi_divider is
  generic(
    --* Representation of signals: C_CES_SIGNED or C_CES_UNSIGNED
    g_representation  : natural   := C_CES_SIGNED;
    --* dividend width
    g_dividend_w      : integer   := 8;
    --* dividend binary point
    g_dividend_binpnt : integer   := 7;
    --* divisor width       
    g_divisor_w       : integer   := 8;
    --* divisor binary point
    g_divisor_binpnt  : integer   := 7;
    --* quotient width
    g_q_w             : integer   := 8;
    --* quotient binary point
    g_q_binpnt        : integer   := 7;
    --* remainder width       
    g_r_w             : integer   := 8;
    --* remainder binary point
    g_r_binpnt        : integer   := 7;
    --* shall be 2 at the moment (radix)
    g_grain           : integer   := 2;
    --* Every how many steps include a register
    g_depth           : integer   := 1
    );
  port(
    clk_i      : in std_logic;          --* input clock
    dividend_i : in std_logic_vector(g_dividend_w - 1 downto 0);  --* dividend
    divisor_i  : in std_logic_vector(g_divisor_w - 1 downto 0);   --* divisor

    q_o : out std_logic_vector(g_q_w - 1 downto 0);  --* quotient
    r_o : out std_logic_vector(g_r_w - 1 downto 0)   --* remainder
    );
end ces_math_fi_divider;

architecture a_rtl of ces_math_fi_divider is
  constant C_DIV_W     : natural := f_sel_a_b((g_dividend_w + g_divisor_w) mod 2 = 0, g_dividend_w + g_divisor_w, g_dividend_w + g_divisor_w + 1);
  constant C_DIV_DELAY : natural := C_DIV_W/g_grain/g_depth + 2;
  signal s_a_pre       : std_logic_vector(C_DIV_W - 1 downto 0);
  signal s_b_pre       : std_logic_vector(C_DIV_W - 1 downto 0);
  signal s_q_pre       : std_logic_vector(C_DIV_W - 1 downto 0);
  signal s_r_pre       : std_logic_vector(C_DIV_W - 1 downto 0);
  -- 
  signal s_q_post      : std_logic_vector(C_DIV_W - 1 downto 0);
  signal s_r_post      : std_logic_vector(C_DIV_W - 1 downto 0);
  --unsigned internal data                                   
  signal s_a_uns       : unsigned(g_dividend_w - 1 downto 0);
  signal s_b_uns       : unsigned(g_divisor_w - 1 downto 0);
  signal s_sign        : std_logic;
  signal s_sign_d      : std_logic;
  --dividend sign
  signal s_div_sign_d  : std_logic;
  --out signed app data
  signal s_q_out_sig   : signed(C_DIV_W - 1 downto 0);
  signal s_r_out_sig   : signed(C_DIV_W - 1 downto 0);
begin

  --* handling input data sign 
  gen_signed : if g_representation = C_CES_SIGNED generate
    s_a_uns(s_a_uns'left)              <= '0';
    s_b_uns(s_b_uns'left)              <= '0';
    s_a_uns(g_dividend_w - 2 downto 0) <= f_sig2uns(signed(dividend_i), dividend_i(dividend_i'left));
    s_b_uns(g_divisor_w - 2 downto 0)  <= f_sig2uns(signed(divisor_i), divisor_i(divisor_i'left));
    s_sign                             <= dividend_i(dividend_i'left) xor divisor_i(divisor_i'left);
  end generate gen_signed;

  gen_unsigned : if g_representation = C_CES_UNSIGNED generate
    s_a_uns <= unsigned(dividend_i);
    s_b_uns <= unsigned(divisor_i);
    s_sign  <= '0';
  end generate gen_unsigned;

  s_a_pre <= std_logic_vector(shift_left(resize(s_a_uns, C_DIV_W), g_divisor_w));  -- multiply dividend_i by 2^g_b_w
  s_b_pre <= std_logic_vector(resize(s_b_uns, C_DIV_W));

  inst_divider : entity ces_math_lib.ces_math_divider
    generic map(
      g_dividend_w => C_DIV_W,
      g_divisor_w  => C_DIV_W,
      g_grain      => g_grain,
      g_depth      => g_depth
      )
    port map(
      clk_i      => clk_i,
      dv_i       => '1', -- CHECK: added to compile the file
      dividend_i => s_a_pre,
      divisor_i  => s_b_pre,
      q_o        => s_q_pre,
      r_o        => s_r_pre
      );

  inst_delay_sign_q : entity ces_util_lib.ces_util_delay
    generic map(
      g_delay     => C_DIV_DELAY,
      g_data_w    => 1
      )
    port map(
      clk_i     => clk_i,
      din_i(0)  => s_sign,
      dout_o(0) => s_sign_d
      );

  inst_delay_sign_r : entity ces_util_lib.ces_util_delay
    generic map(
      g_delay     => C_DIV_DELAY,
      g_data_w    => 1
      )
    port map(
      clk_i     => clk_i,
      din_i(0)  => dividend_i(dividend_i'left),
      dout_o(0) => s_div_sign_d
      );

  --* handling output data sign 
  gen_out_signed : if g_representation = C_CES_SIGNED generate
    s_q_out_sig <= f_uns2sig(unsigned(s_q_pre(s_q_pre'left-1 downto 0)), s_sign_d);
    s_r_out_sig <= f_uns2sig(unsigned(s_r_pre(s_r_pre'left-1 downto 0)), s_div_sign_d);
    s_q_post    <= std_logic_vector(shift_right(s_q_out_sig, g_divisor_w-g_divisor_binpnt));  -- re-align binary point.
    s_r_post    <= std_logic_vector(shift_right(s_r_out_sig, g_divisor_w-g_divisor_binpnt));  -- re-align binary point. 
    inst_format_q : entity ces_math_lib.ces_math_fi_format
      generic map(
        g_din_w          => C_DIV_W,
        g_din_binpnt     => g_dividend_binpnt + (g_divisor_w - g_divisor_binpnt),
        g_dout_w         => g_q_w,
        g_dout_binpnt    => g_q_binpnt,
        g_pipe_stages    => 1,
        g_round_mode     => C_CES_ROUND,
        g_overflow => C_CES_WRAP,
        g_representation => C_CES_SIGNED
        )
      port map(
        clk_i  => clk_i,
        din_i  => std_logic_vector(s_q_out_sig),
        dout_o => q_o
        );


    inst_format_r : entity ces_math_lib.ces_math_fi_format
      generic map(
        g_din_w          => C_DIV_W,
        g_din_binpnt     => g_dividend_binpnt + g_divisor_w,  --g_a_binpnt + (g_divisor_w - g_divisor_binpnt),
        g_dout_w         => g_r_w,
        g_dout_binpnt    => g_r_binpnt,
        g_pipe_stages    => 1,
        g_round_mode     => C_CES_ROUND,
         g_overflow => C_CES_WRAP,
        g_representation => C_CES_SIGNED
        )
      port map(
        clk_i  => clk_i,
        din_i  => std_logic_vector(s_r_out_sig),
        dout_o => r_o
        );
  end generate gen_out_signed;

  gen_out_unsigned : if g_representation = C_CES_UNSIGNED generate
    s_q_post <= std_logic_vector(shift_right(unsigned(s_q_pre), g_divisor_w-g_divisor_binpnt));  -- re-align binary point.
    s_r_post <= std_logic_vector(shift_right(unsigned(s_r_pre), g_divisor_w-g_divisor_binpnt));  -- re-align binary point. 

    inst_format_q : entity ces_math_lib.ces_math_fi_format
      generic map(
        g_din_w          => C_DIV_W,
        g_din_binpnt     => g_dividend_binpnt + (g_divisor_w - g_divisor_binpnt),
        g_dout_w         => g_q_w,
        g_dout_binpnt    => g_q_binpnt,
        g_pipe_stages    => 1,
        g_round_mode     => C_CES_ROUND,
        g_overflow => C_CES_WRAP,
        g_representation => C_CES_UNSIGNED
        )
      port map(
        clk_i  => clk_i,
        din_i  => s_q_pre,
        dout_o => q_o
        );

    inst_format_r : entity ces_math_lib.ces_math_fi_format
      generic map(
        g_din_w          => C_DIV_W,
        g_din_binpnt     => g_dividend_binpnt + g_divisor_w,  --g_a_binpnt + (g_divisor_w - g_divisor_binpnt),
        g_dout_w         => g_r_w,
        g_dout_binpnt    => g_r_binpnt,
        g_pipe_stages    => 1,
        g_round_mode     => C_CES_ROUND,
        g_overflow => C_CES_WRAP,
        g_representation => C_CES_UNSIGNED
        )
      port map(
        clk_i  => clk_i,
        din_i  => s_r_pre,
        dout_o => r_o
        );
  end generate gen_out_unsigned;


end a_rtl;
