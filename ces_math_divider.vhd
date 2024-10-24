--=============================================================================
-- Module Name : ces_math_divider
-- Library     : ces_math_lib
-- Project     : CES MATH
-- Company     : Campera Electronic Systems Srl
-- Author      : A.Campera
-------------------------------------------------------------------------------
-- Description: divider unsigned by unsigned  A/B with quotient and remainder
--
--
-------------------------------------------------------------------------------
-- (c) Copyright 2014 Campera Electronic Systems Srl. Via Aurelia 136, Stagno
-- (Livorno), 57122, Italy. <www.campera-es.com>. All rights reserved.
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
-------------------------------------------------------------------------------
-- Revision History:
-- Date        Version  Author     Description
-- 2014/10/19  1.0.1    GDM        Intial release
-- 18/05/2017  1.0.1    MCO        Reset cancelled (non used in this type
--                                 of module), or updated to new g_rst when
--                                 present in a called entity.
-- 23/01/2019  1.0.2    MCO        Signed processing added (formerly unsigned
--                                 only). Signals dv_i and dv_o added, and latency
--                                 calculation.
--
--=============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ces_math_lib;
library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

-------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------
--* @brief divider unsigned by unsigned  A/B with quotient and remainder
entity ces_math_divider is
	generic(
		g_dividend_w : integer := 8;        --* data a width
		g_divisor_w  : integer := 6;        --* data b width       
		g_grain      : integer := 2;        --* shall be 2 ate the moment (radix)
		g_depth      : integer := 1;        --* Every how many steps include a register
		g_is_signed  : integer := 1					--* Signed (1) or unsigned (0) inputs
		);
	port(
		clk_i      : in std_logic;          --* input clock
		dv_i       : in std_logic;
		dividend_i : in std_logic_vector(g_dividend_w - 1 downto 0);  --* dividend
		divisor_i  : in std_logic_vector(g_divisor_w - 1 downto 0);   --* divisor
		dv_o       : out std_logic;
		q_o        : out std_logic_vector(g_dividend_w - 1 downto 0);  --*quotient
		r_o        : out std_logic_vector(g_divisor_w - 1 downto 0)    --* remainder
		);
end ces_math_divider;

architecture a_rtl of ces_math_divider is
	
	constant C_PREV : integer := g_dividend_w / 2;
	constant C_REM : integer := C_PREV rem g_depth;
	constant C_LATENCY_U : integer := C_PREV / g_depth + C_REM + 2;
	constant C_LATENCY_S : integer := C_PREV / g_depth + C_REM + 3;
	
	signal s_dv_u             : std_logic_vector(0 to C_LATENCY_U-1);
	signal s_dv_s             : std_logic_vector(0 to C_LATENCY_S-1);
	signal s_sign             : std_logic_vector(0 to C_LATENCY_S-1);
	
	signal s_rem, s_reg_y_rem : std_logic_vector(g_divisor_w - 1 downto 0);
	signal s_quot             : std_logic_vector(g_dividend_w - 1 downto 0);
	signal s_dividend_s       : signed(g_dividend_w - 1 downto 0);  --* dividend
	signal s_divisor_s        : signed(g_divisor_w - 1 downto 0);   --* divisor
	signal s_dividend_u       : std_logic_vector(g_dividend_w - 1 downto 0);  --* dividend
	signal s_divisor_u        : std_logic_vector(g_divisor_w - 1 downto 0);   --* divisor
	signal s_q_s              : signed(g_dividend_w - 1 downto 0);  --*quotient
	signal s_r_s              : signed(g_divisor_w - 1 downto 0);    --* remainder
	signal s_q_u              : std_logic_vector(g_dividend_w - 1 downto 0);  --*quotient
	signal s_r_u              : std_logic_vector(g_divisor_w - 1 downto 0);    --* remainder
	
	type t_matrix_rem is array (0 to g_dividend_w / g_grain - 1) of std_logic_vector(g_divisor_w downto 0);
	signal s_rem_in  : t_matrix_rem;
	signal s_rem_out : t_matrix_rem;
	type t_matrix_y is array (0 to g_dividend_w / g_grain - 1) of std_logic_vector(g_divisor_w downto 0);
	signal s_reg_y   : t_matrix_y;
	type t_matrix_3y is array (0 to g_dividend_w / g_grain - 1) of std_logic_vector(g_divisor_w + 1 downto 0);
	signal s_reg_3y  : t_matrix_3y;
	type t_matrix_x is array (0 to g_dividend_w / g_grain - 1) of std_logic_vector(g_dividend_w - 1 downto 0);
	signal s_reg_x   : t_matrix_x;
	type t_matrix_q is array (0 to g_dividend_w / g_grain - 1) of std_logic_vector(g_dividend_w - 1 downto 0);
	signal s_reg_q   : t_matrix_q;
	
	signal s_rem_no_adj : std_logic_vector(g_divisor_w downto 0);
	
begin
	
	-- unsigned processing
	gen_unsigned : if g_is_signed = 0 generate
		s_dividend_u <= dividend_i;--input
		s_divisor_u <= divisor_i;
		--
		q_o <= s_q_u;--output
		r_o <= s_r_u;
		--
		proc_dv : process(clk_i)
		begin
			if rising_edge(clk_i) then
				for i in 0 to s_dv_u'right loop
					if i = 0 then
						s_dv_u(i) <= dv_i;
					else
						s_dv_u(i) <= s_dv_u(i-1);
					end if;
				end loop;
			end if;
		end process proc_dv;
		--
		dv_o <= s_dv_u(s_dv_u'right);
	end generate gen_unsigned;
	
	-- signed processing
	gen_signed : if g_is_signed = 1 generate
		-- signed inputs lead to unsigned	(positive) values:
		s_dividend_s <= signed(dividend_i) when dividend_i(dividend_i'left) = '0' else -signed(dividend_i);
		s_divisor_s <= signed(divisor_i) when divisor_i(divisor_i'left) = '0' else -signed(divisor_i);
		-- but trace of correct output sign is kept (see below);
		--
		-- output:
		q_o <= std_logic_vector(s_q_s);
		r_o <= std_logic_vector(s_r_s);
		--
		proc_load_and_sign_processing : process(clk_i)
		begin
			if rising_edge(clk_i) then
				s_dividend_u <= std_logic_vector(s_dividend_s);
				s_divisor_u <= std_logic_vector(s_divisor_s);
			end if;
		end process proc_load_and_sign_processing;
		--
		proc_dv : process(clk_i)
		begin
			if rising_edge(clk_i) then
				for i in 0 to s_dv_s'right loop
					if i = 0 then
						s_dv_s(i) <= dv_i;
						-- this is the correct output sign:
						s_sign(i) <= dividend_i(dividend_i'left) xor divisor_i(divisor_i'left);
					else
						s_dv_s(i) <= s_dv_s(i-1);
						-- the output sign is transported through:
						s_sign(i) <= s_sign(i-1);
					end if;
				end loop;
			end if;
		end process proc_dv;
		--
		-- the right sign is attributed to the output:
		s_q_s <= signed(s_q_u) when s_sign(s_sign'right) = '0' else -signed(s_q_u);
		s_r_s <= signed(s_r_u) when s_sign(s_sign'right) = '0' else -signed(s_r_u);
		--
		dv_o <= s_dv_s(s_dv_s'right);
	end generate gen_signed;
	
	
	proc_ff_0 : process(clk_i)
	begin
		if rising_edge(clk_i) then
			s_reg_y(0)   <= ('0' & s_divisor_u);
			s_reg_3y(0)  <= std_logic_vector(unsigned(('0' & s_divisor_u)) + unsigned(('0' & s_divisor_u & '0')));
			s_reg_x(0)   <= s_dividend_u;
			s_q_u        <= s_quot;
			s_quot       <= not s_reg_q(g_dividend_w / g_grain - 1);
			s_rem_no_adj <= s_rem_out(g_dividend_w / g_grain - 1);
			s_reg_y_rem  <= s_reg_y(g_dividend_w / g_grain - 1)(g_divisor_w - 1 downto 0);
			s_r_u        <= s_rem;
		end if;
	end process proc_ff_0;
	
	s_rem_in(0) <= (others => '0');
	
	gen_1 : for i in 0 to g_dividend_w / g_grain - 1 generate
		inst_cell : entity ces_math_lib.ces_math_div_r4_half_cell
		generic map(
			g_data_w => g_divisor_w
			)
		port map(
			op_r_i   => s_rem_in(i),
			op_y_i   => s_reg_y(i),
			op_3y_i  => s_reg_3y(i),
			x_1_i    => s_reg_x(i)(g_dividend_w - 1 - i * 2),
			x_0_i    => s_reg_x(i)(g_dividend_w - 2 - i * 2),
			n_qneg_o => s_reg_q(i)(g_dividend_w - 1 - i * 2 downto g_dividend_w - 2 - i * 2),
			new_r_o  => s_rem_out(i)
			);
	end generate gen_1;
	
	gen_2 : for i in 0 to g_dividend_w / g_grain - 2 generate
		gen_2c : if (i + 1) mod g_depth /= 0 generate
			s_rem_in(i + 1)                                                  <= s_rem_out(i);
			s_reg_y(i + 1)                                                   <= s_reg_y(i);
			s_reg_3y(i + 1)                                                  <= s_reg_3y(i);
			s_reg_x(i + 1)                                                   <= s_reg_x(i);
			s_reg_q(i + 1)(g_dividend_w - 1 downto g_dividend_w - 2 - i * 2) <= s_reg_q(i)(g_dividend_w - 1 downto g_dividend_w - 2 - i * 2);
		end generate gen_2c;
		gen_2ff : if (i + 1) mod g_depth = 0 generate
			proc_ffs : process(clk_i)
			begin
				if clk_i'event and clk_i = '1' then  --clk_i rising edge
					s_rem_in(i + 1)                                                  <= s_rem_out(i);
					s_reg_y(i + 1)                                                   <= s_reg_y(i);
					s_reg_3y(i + 1)                                                  <= s_reg_3y(i);
					s_reg_x(i + 1)                                                   <= s_reg_x(i);
					s_reg_q(i + 1)(g_dividend_w - 1 downto g_dividend_w - 2 - i * 2) <= s_reg_q(i)(g_dividend_w - 1 downto g_dividend_w - 2 - i * 2);
				end if;
			end process proc_ffs;
		end generate gen_2ff;
	end generate gen_2;
	
	proc_adder : process(s_rem_no_adj, s_reg_y_rem)
	begin
		if s_rem_no_adj(g_divisor_w) = '1' then
			s_rem <= std_logic_vector(unsigned(s_rem_no_adj(g_divisor_w - 1 downto 0)) + unsigned(s_reg_y_rem(g_divisor_w - 1 downto 0)));
		else
			s_rem <= s_rem_no_adj(g_divisor_w - 1 downto 0);
		end if;
	end process proc_adder;
	
end a_rtl;
