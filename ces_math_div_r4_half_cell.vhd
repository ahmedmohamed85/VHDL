--=============================================================================
-- Module Name : ces_math_div_r4_half_cell
-- Library     : ces_math_lib
-- Project     : CES MATH
-- Company     : Campera Electronic Systems Srl
-- Author      : A.Campera
-------------------------------------------------------------------------------
-- Description: divider cell unsigned by unsigned
--
--
-------------------------------------------------------------------------------
-- (c) Copyright 2014 Campera Electronic Systems Srl. Via Aurelia 136, Stagno
-- (Livorno), 57122, Italy. <www.campera-es.com>. All rights reserved.
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
-------------------------------------------------------------------------------
-- Revision History:
-- Date        Version  Author         Description
-- 2014-09-19  1.0.0    GDM           initial release
-- 18/05/2017  1.0.0    MCO           Reset cancelled (non used in this type
--                                    of module), or updated to new g_rst when
--                                    present in a called entity.
-- 
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

-------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------
--* @brief divider cell unsigned by unsigned
entity ces_math_div_r4_half_cell is
  generic(
    g_data_w : integer := 8             --* data width
    );
  port(
    op_r_i   : in  std_logic_vector(g_data_w downto 0);
    op_y_i   : in  std_logic_vector(g_data_w downto 0);
    op_3y_i  : in  std_logic_vector(g_data_w + 1 downto 0);
    x_1_i    : in  std_logic;
    x_0_i    : in  std_logic;
    n_qneg_o : out std_logic_vector(1 downto 0);
    new_r_o  : out std_logic_vector(g_data_w downto 0)
    );
end ces_math_div_r4_half_cell;

architecture a_rtl of ces_math_div_r4_half_cell is
  signal s_op_4r    : std_logic_vector(g_data_w + 1 downto 0);
  signal s_a2_pm_b  : unsigned(g_data_w + 1 downto 0);
  signal s_a4_pm_b  : unsigned(g_data_w + 1 downto 0);
  signal s_a4_pm_3b : unsigned(g_data_w + 1 downto 0);
  signal s_sr       : std_logic;
begin
  s_sr    <= op_r_i(g_data_w);
  s_op_4r <= op_r_i(g_data_w - 1 downto 0) & x_1_i & x_0_i;

  s_a2_pm_b  <= unsigned((op_r_i & x_1_i)) + unsigned((op_y_i)) when s_sr = '1' else unsigned((s_sr & op_y_i)) + unsigned(not (op_r_i & x_1_i));
  s_a4_pm_3b <= unsigned(s_op_4r) + unsigned(op_3y_i)           when s_sr = '1' else unsigned(s_op_4r) - unsigned(op_3y_i);
  s_a4_pm_b  <= unsigned(s_op_4r) + unsigned(op_y_i)            when s_sr = '1' else unsigned(s_op_4r) - unsigned(s_sr & op_y_i);

  proc_mux_outps : process(s_a2_pm_b, s_a4_pm_b, s_a4_pm_3b)
  begin
    if s_a2_pm_b(g_data_w) = '1' then
      new_r_o     <= std_logic_vector(s_a4_pm_3b(g_data_w downto 0));
      n_qneg_o(0) <= s_a4_pm_3b(g_data_w);
    else
      new_r_o     <= std_logic_vector(s_a4_pm_b(g_data_w downto 0));
      n_qneg_o(0) <= s_a4_pm_b(g_data_w);
    end if;
  end process proc_mux_outps;

  proc_mux_nqb : process(s_sr, s_a2_pm_b, s_a4_pm_b, s_a4_pm_3b)
  begin
    if s_sr = '1' then                  --11
      n_qneg_o(1) <= s_a2_pm_b(g_data_w);
    else
      n_qneg_o(1) <= not s_a2_pm_b(g_data_w);
    end if;

  end process proc_mux_nqb;

end a_rtl;
