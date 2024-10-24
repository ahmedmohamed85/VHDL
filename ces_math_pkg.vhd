--==============================================================================
-- Module Name : ces_math_pkg
-- Library     : ces_math_lib
-- Project     : FLACU
-- Company     : ERA Electronic System Srl
-- Author      : G. Dalle Mura
--------------------------------------------------------------------------------
-- Description:  mathematical package containing useulf types and functions
--------------------------------------------------------------------------------
-- (c) Copyright 2021 Era Electronic Systems S.R.L. Via Gustavo Benucci, 206, 
-- 06135 Perugia PG, Italy. <http://www.eraes.it/ >. All rights reserved. 
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--------------------------------------------------------------------------------
-- Revision History:
-- Date        Version  Author        Description
-- 22/05/2014  1.0.0    GDM           Initial Release
-- 15/10/2017  1.0.1    MCO           New utility functions added (MISCELLANEA FUNCTIONS)
-- 19/10/2017  1.0.1    MCO           Target reconnaissance function and type added
--                                    ().
--==============================================================================
--
-- Libraries:
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

--* @brief mathematical package containing useulf types and functions
package ces_math_pkg is

  ------------------------------------------------------------------------------
  --Constants
  ------------------------------------------------------------------------------
  --+ math
  constant C_NOF_COMPLEX       : natural := 2;  -- real and imaginary part of complex number
  constant C_SIGN_W            : natural := 1;  -- use only 1 sign bit
  --+ Arithmetic types
  constant C_CES_UNSIGNED      : integer := 1;  -- unsigned data type
  constant C_CES_SIGNED        : integer := 2;  -- signed data type
  constant C_CES_FIXED         : integer := 3;  -- fixed point data type
  constant C_CES_FLOAT         : integer := 4;  -- floating point data type
  --+ Rounding style
  constant C_CES_TRUNC         : integer := 1;  -- truncate
  constant C_CES_ROUND         : integer := 2;  -- round
  --+ Overflow style
  constant C_CES_SATURATE      : integer := 1;  -- Saturation 
  constant C_CES_WRAP          : integer := 2;  -- wrap
  --+ Rounding style
  constant C_CES_ROUND_NEAREST : integer := 1;  -- Default, nearest LSB '0'
  constant C_CES_ROUND_INF     : integer := 2;  -- Round toward positive infinity
  constant C_CES_ROUND_NEGINF  : integer := 3;  -- Round toward negative infinity
  constant C_CES_ROUND_ZERO    : integer := 4;  -- Round toward zero (truncate)
  -- Sorting order 
  --* Decreasing order
  constant C_CES_DECREASE      : natural := 0;
  --* Increasing order
  constant C_CES_INCREASE      : natural := 1;
  -- Interpolation modes           
  --* Without interpolation
  constant C_NO_INTERP         : natural := 0;
  --* Linear interpolation mode
  constant C_INTERP_LINEAR     : natural := 1;
  -- Choose sort
  --* Heap sort
  constant C_HEAP_SORT         : natural := 0;
  --* Parallel sort       
  constant C_PARALLEL_SORT     : natural := 1;
  --+ max or min
  constant C_CES_MAX           : natural := 1;
  constant C_CES_MIN           : natural := 0;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  --user defined types
  -- define a complex type
  --  if a is t_complex => a = a.re + j*a.im
  --  type t_complex is array (0 to 1) of signed;

  --unconstrained array of complex type
  --  type t_complex_array is array (integer range <>) of t_complex;

  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  --user defined functions
  ------------------------------------------------------------------------------
  -- Bit\digit reverse ordering functions
  -- CES_TAG: bit reverse, radix 2, radix 4
  ------------------------------------------------------------------------------
  --* @brief bit reverse module 2
  function f_bitrev2(a : in unsigned) return unsigned;

  --* @brief bit reverse module 4
  function f_bitrev4(a : in unsigned) return unsigned;

  ------------------------------------------------------------------------------
  -- Functions over complex numbers
  ------------------------------------------------------------------------------
  -- compute complex conjugate of a complex number
  --  if a is t_complex => f_conj(a) = a.re - j*a.im
  --  function f_conj (a: in t_complex) return t_complex;

  -- invert real and imaginary part: used in complex mltiplier
  --  if a is t_complex => f_swap_cmplx(a) = a.im + j*a.re
  --  function f_swap_cmplx (a: in t_complex) return t_complex;

  -- compute the product of a complex by j
  --  if a is t_complex => f_j_cmplx(a) = j*(a.re+j*a.im) = -a.im + j*a.re
  --  function f_j_cmplx (a: in t_complex) return t_complex;

  -- compute the doubling of a complex, taking into account the sign
  -- if a is t_complex => f_mult2cmplx(a) = 2*a.re + j*2*a.im
  --  function f_mult2cmplx (a: in t_complex) return t_complex;

  --  --overload complex math
  --  function "+" (a:t_complex; b:t_complex) return t_complex; 

  --* @brief add n '0' lsbits to vec
  function f_scale(vec : std_logic_vector; n : natural) return std_logic_vector;
  --* @brief OVERLOADED: SIGNED add n '0' lsbits to vec 
  function f_scale(vec : signed; n : natural) return signed;

  --+ @brief tests used in f_convert_type
  function f_pos(inp           : std_logic_vector; arith : integer) return boolean;
  function f_all_same(inp      : std_logic_vector) return boolean;
  function f_all_zeros(inp     : std_logic_vector) return boolean;
  function f_is_point_five(inp : std_logic_vector) return boolean;
  function f_all_ones(inp      : std_logic_vector) return boolean;

  -- ARITHMENTICAL FUCTIONS ---------------------------------------------------
  --* @brief vec + dec, treat slv operands as unsigned, dec is an integer.
  function f_incr_uns(vec  : std_logic_vector; dec : integer) return std_logic_vector;
  --* @brief vec + dec, treat slv operands as unsigned, dec is an unsigned.
  function f_incr_uns(vec  : std_logic_vector; dec : unsigned) return std_logic_vector;
  --* @brief l_vec + r_vec, treat slv operands as signed,   slv output width is res_w
  function f_add_sig(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector;
  --* @brief l_vec - r_vec, treat slv operands as signed,   slv output width is res_w
  function f_sub_sig(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector;
  --* @brief l_vec + r_vec, treat slv operands as unsigned, slv output width is res_w
  function f_add_uns(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector;
  --* @brief l_vec - r_vec, treat slv operands as unsigned, slv output width is res_w
  function f_sub_uns(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector;

  --* @brief l_vec + r_vec, treat slv operands as signed,   slv output width is l_vec'length
  function f_add_sig(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector;
  --* @brief l_vec - r_vec, treat slv operands as signed,   slv output width is l_vec'length
  function f_sub_sig(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector;
  --* @brief l_vec + r_vec, treat slv operands as unsigned, slv output width is l_vec'length
  function f_add_uns(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector;
  --* @brief l_vec - r_vec, treat slv operands as unsigned, slv output width is l_vec'length
  function f_sub_uns(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector;

  ------------------------------------------------------------------------------
  -- Quantization Functions

  --* @brief truncation
  function f_trunc(inp              : std_logic_vector; old_width, old_bin_pt, old_arith, new_width, new_bin_pt, new_arith : integer) return std_logic_vector;
  --+ @brief rounding
  function f_round_towards_inf(inp  : std_logic_vector; old_width, old_bin_pt, old_arith, new_width, new_bin_pt, new_arith : integer) return std_logic_vector;
  function f_round_towards_even(inp : std_logic_vector; old_width, old_bin_pt, old_arith, new_width, new_bin_pt, new_arith : integer) return std_logic_vector;
  --+ @brief formatting 
  function f_full_precision_num_width(quantization, overflow, old_width,
                                      old_bin_pt,
                                      old_arith,
                                      new_width, new_bin_pt, new_arith : integer)
    return integer;
  function f_quantized_num_width(quantization, overflow, old_width, old_bin_pt,
                                 old_arith, new_width, new_bin_pt, new_arith
                                 : integer)
    return integer;
  function f_format_input(inp : std_logic_vector; old_width, delta, new_width, arith : integer) return std_logic_vector;
  function f_convert_type (inp : std_logic_vector; old_width, old_bin_pt,

                           old_arith, new_width, new_bin_pt, new_arith,
                           quantization,
                           overflow : integer)
    return std_logic_vector;
  function f_cast (inp       : std_logic_vector; old_bin_pt,
                   new_width, new_bin_pt,
                   new_arith : integer)
    return std_logic_vector;

  --+ @brief overflow
  function f_saturation_arith(inp : std_logic_vector; old_width, old_bin_pt,

                              old_arith, new_width, new_bin_pt, new_arith
                              : integer) return std_logic_vector;

  function f_wrap_arith(inp : std_logic_vector; old_width, old_bin_pt,

                        old_arith, new_width, new_bin_pt, new_arith : integer)
    return std_logic_vector;
  ------------------------------------------------------------------------------
  -- Binary point alignment functions

  --  -- Returns the number of fractional bits after alignment of fixed point num
  --  function f_fractional_bits(a_bin_pt, b_bin_pt : integer) return integer;
  --
  --  -- Returns the number of integer bits after alignment of fixed point num.
  --  function f_integer_bits(a_width, a_bin_pt, b_width, b_bin_pt : integer)
  --    return integer;

  --* @brief sign extend the MSB
  function f_sign_ext(inp : std_logic_vector; new_width : integer) return std_logic_vector;

  --* @brief zero extend the MSB
  function f_zero_ext(inp : std_logic_vector; new_width : integer) return std_logic_vector;

  --* @brief zero extend the MSB
  function f_zero_ext(inp : std_logic; new_width : integer) return std_logic_vector;

  --* @brief Pad LSB with zeros
  function f_pad_LSB(inp : std_logic_vector; new_width : integer) return std_logic_vector;

  --* @brief Pad LSB with zeros and add a zero or sign extend the MSB
  function f_pad_LSB(inp    : std_logic_vector; new_width, arith : integer) return std_logic_vector;
  --* @brief extend the MSB
  function f_extend_MSB(inp : std_logic_vector; new_width, arith : integer) return std_logic_vector;

  function f_count_l_zeros(signal s_vector   : std_logic_vector) return std_logic_vector;
  function f_count_zeros_mul(signal s_vector : unsigned) return std_logic_vector;

  function f_ramp_array(g_array_size, g_data_w, g_representation, init, step : in integer) return std_logic_vector;

  ------------------------------------------------------------------------------
  -- Debugging functions
  ------------------------------------------------------------------------------
  -- synthesis translate_off

  -- Check for Undefined values
  function f_is_XorU(inp : std_logic_vector) return boolean;

  -- synthesis translate_on

  -------------------------------------------------------------------------------------------
  -------- MISCELLANEA FUNCTIONS ---------------------------------------------------------
  -------------------------------------------------------------------------------------------

  -- counts the trailing zeroes on the left in a vector: "000101100110100" -> 3
  function f_count_delta(vector_i : unsigned) return unsigned;

  -- counts the tail zeroes on the right in a vector: "000101100110100" -> 2
  function f_count_tail(vector_i : unsigned) return unsigned;

  -- counts the length of a vector from the first 1 on the left: "000101100110100" -> 12
  function f_count_length(vector_i : unsigned) return unsigned;

  -- counts the length of the central nonzero section of a vector, from 1 to 1: "000101100110100" -> 10
  function f_count_kernel(vector_i : unsigned) return unsigned;

  -- says whether a vector is all made of 1's or not;
  function f_all_ones(vector_i : unsigned) return std_logic;

  -- says whether all the vector elements left of a given index are all zeros;
  function f_left_clear(vector_i : unsigned; ind : natural) return std_logic;

  -- same as the usual resize, but the 0's padding is made on the right instead: "001101" -> "0010100000" instead of "00000001101"
  function f_resize_right(vector_in : unsigned; length_out : natural) return unsigned;

  -- the vector is shifted to the rightmost position, till its least significant 1 bumps on the right border: "0000110100000" -> "0000000001101"
  function f_bump_right(in_vector : unsigned) return unsigned;

  -- the vector is shifted to the leftmost position, till its most significant 1 bumps on the left border: "0000110100000" -> "1101000000000"
  function f_bump_left(in_vector : unsigned) return unsigned;

  -- same as usual shift, but a padding with 1's can be chosen by commenting the due line in the function body;
  function f_rightshift(vector_i : unsigned; delta_i : natural) return unsigned;
  function f_leftshift(vector_i  : unsigned; delta_i : natural) return unsigned;

  -- returns a std_logic '0' or '1' based oh whether the integer is zero or nonzero;
  function f_int_to_sl(in_num : integer) return std_logic;

  function f_divide_by_two(number_i : integer; depth_i : natural) return integer;

  function f_multiply_by_three(number_i : unsigned) return unsigned;

  -- makes the square of the input (say the self convolution); the length is the same of the input, so take care of overflow;
  function f_square(number_i : unsigned) return unsigned;

  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  -- TARGET RECONNAISSANCE TYPE AND FUNCTION -------------------------------------
  -------------------------------------------------------------------------------------------

  type t_multiplier_size is array (0 to 1) of natural;
  --
  --function f_multiplier_size_get(target_i : t_target) return t_multiplier_size;
  --



  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------

end package ces_math_pkg;

package body ces_math_pkg is

  ------------------------------------------------------------------------------
  -- Bit\digit reverse ordering functions
  ------------------------------------------------------------------------------
  -- bit reverse module 2
  function f_bitrev2(a : in unsigned) return unsigned is
    variable v_result : unsigned(a'range);
  begin
    for i in a'range loop
      v_result(i) := a(a'high - i);
    end loop;
    return v_result;
  end;  --f_bitrev2


  -- bit reverse module 4
  function f_bitrev4(a : in unsigned) return unsigned is
    variable v_result : unsigned(a'range);
  begin
    for i in 0 to (a'length / 2 - 1) loop
      v_result(2 * i + 1 downto 2 * i) := a(a'length - 2 * i - 1 downto a'length - 2 * i - 2);
    end loop;
    return v_result;
  end;  --f_bitrev4

  ------------------------------------------------------------------------------
  -- Functions over complex numbers
  ------------------------------------------------------------------------------
  -- complex conjugate
  --  function f_conj (a: in t_complex)
  --    return t_complex is
  --  begin
  --    return (a(0),-a(1));
  --  end; --f_conj

  -- swap real and imaginary parts
  --  function f_swap_cmplx (a: in t_complex)
  --    return t_complex is
  --  begin
  --    return (a(1),a(0));
  --  end; -- f_swap_cmplx

  --result is j*a (a=a0+ja1 => result=j*a=-a1+ja0)
  --  function f_j_cmplx (a: in t_complex)
  --    return t_complex is
  --  begin
  --    return (-a(1),a(0));
  --  end; --f_j_cmplx


  -- multiply a complex by 2 (with sign)
  --  function f_mult2cmplx(a: in t_complex)
  --    return t_complex is
  --  begin
  --    return (a(0)(a(0)'left) & a(0)(a(0)'left-2 downto 0) & '0',
  --    a(1)(a(1)'left) & a(1)(a(1)'left-2 downto 0) & '0');
  --  end function; --f_mult2cmplx


  --  function "+" (a:t_complex; b:t_complex) return t_complex is
  --  begin
  --    return (a.re+b.re, a.im+b.im);
  --  end function;

  function f_scale(vec : std_logic_vector; n : natural) return std_logic_vector is
    constant C_VEC_W   : natural                                  := vec'length;
    constant C_SCALE_W : natural                                  := C_VEC_W + n;
    variable v_res     : std_logic_vector(C_SCALE_W - 1 downto 0) := (others => '0');
  begin
    v_res(C_SCALE_W - 1 downto n) := vec;  -- scale by adding n zero bits at the right
    return v_res;
  end;

  -- OVERLOADED: SIGNED
  function f_scale(vec : signed; n : natural) return signed is
    constant C_VEC_W   : natural                        := vec'length;
    constant C_SCALE_W : natural                        := C_VEC_W + n;
    variable v_res     : signed(C_SCALE_W - 1 downto 0) := (others => '0');
  begin
    v_res(C_SCALE_W - 1 downto n) := vec;  -- scale by adding n zero bits at the right
    return v_res;
  end;


  -- Test if a number is positive
  function f_pos(inp : std_logic_vector; arith : integer) return boolean is
    constant C_WIDTH : integer := inp'length;
    variable v_vec   : std_logic_vector(C_WIDTH - 1 downto 0);

  begin
    v_vec := inp;
    if arith = C_CES_UNSIGNED then
      return true;
    else
      if v_vec(C_WIDTH - 1) = '0' then
        return true;
      else
        return false;
      end if;
    end if;

    -- Error
    return true;
  end;  --f_pos

  function f_max_signed(width : integer) return std_logic_vector is
    variable v_ones   : std_logic_vector(width - 2 downto 0);
    variable v_result : std_logic_vector(width - 1 downto 0);
  begin
    v_ones                       := (others => '1');
    v_result(width - 1)          := '0';
    v_result(width - 2 downto 0) := v_ones;
    return v_result;
  end;  --f_max_signed


  function f_min_signed(width : integer) return std_logic_vector is
    variable v_zeros  : std_logic_vector(width - 2 downto 0);
    variable v_result : std_logic_vector(width - 1 downto 0);
  begin
    v_zeros                      := (others => '0');
    v_result(width - 1)          := '1';
    v_result(width - 2 downto 0) := v_zeros;
    return v_result;
  end;  --f_min_signed



  -- Check if all the bits are the same
  function f_all_same(inp : std_logic_vector) return boolean is
    constant C_WIDTH  : integer := inp'length;
    variable v_result : boolean;
    variable v_vec    : std_logic_vector(C_WIDTH - 1 downto 0);
  begin
    v_vec    := inp;
    v_result := true;
    if C_WIDTH > 0 then
      for i in 1 to C_WIDTH - 1 loop
        if v_vec(i) /= v_vec(0) then
          v_result := false;
        end if;
      end loop;
    end if;
    return v_result;
  end;  --f_all_same


  -- Check if a number is all zeros
  function f_all_zeros(inp : std_logic_vector) return boolean is
    constant C_WIDTH  : integer := inp'length;
    variable v_vec    : std_logic_vector(C_WIDTH - 1 downto 0);
    variable v_zero   : std_logic_vector(C_WIDTH - 1 downto 0);
    variable v_result : boolean;
  begin
    v_zero := (others => '0');
    v_vec  := inp;

      if (f_slv2uns(v_vec) = f_slv2uns(v_zero)) then
        v_result := true;
      else
        v_result := false;
      end if;
    return v_result;
  end;  --f_all_zeros

  -- Check if a number is point five
  function f_is_point_five(inp : std_logic_vector) return boolean is
    constant C_WIDTH  : integer := inp'length;
    variable v_vec    : std_logic_vector(C_WIDTH - 1 downto 0);
    variable v_result : boolean;
  begin
    v_vec := inp;

      if (C_WIDTH > 1) then
        if ((v_vec(C_WIDTH - 1) = '1') and (f_all_zeros(v_vec(C_WIDTH - 2 downto 0)) = true)) then
          v_result := true;
        else
          v_result := false;
        end if;
      else
        if (v_vec(C_WIDTH - 1) = '1') then
          v_result := true;
        else
          v_result := false;
        end if;
      end if;

    return v_result;
  end;  --f_is_point_five

  -- Check if a number is all ones
  function f_all_ones(inp : std_logic_vector) return boolean is
    constant C_WIDTH  : integer := inp'length;
    variable v_vec    : std_logic_vector(C_WIDTH - 1 downto 0);
    variable v_one    : std_logic_vector(C_WIDTH - 1 downto 0);
    variable v_result : boolean;
  begin
    v_one := (others => '1');
    v_vec := inp;

      if (f_slv2uns(v_vec) = f_slv2uns(v_one)) then
        v_result := true;
      else
        v_result := false;
      end if;
    return v_result;
  end;  --f_all_ones 

  function f_incr_uns(vec : std_logic_vector; dec : integer) return std_logic_vector is
    variable v_dec : integer;
  begin
    if dec < 0 then
      v_dec := -dec;
      return std_logic_vector(unsigned(vec) - v_dec);
    else
      v_dec := dec;
      return std_logic_vector(unsigned(vec) + v_dec);
    end if;
  end;

  function f_incr_uns(vec : std_logic_vector; dec : unsigned) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(vec) + dec);
  end;

  function f_add_sig(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector is
  begin
    return std_logic_vector(f_ces_resize(signed(l_vec), res_w) + signed(r_vec));
  end;

  function f_sub_sig(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector is
  begin
    return std_logic_vector(f_ces_resize(signed(l_vec), res_w) - signed(r_vec));
  end;

  function f_add_uns(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector is
  begin
    return std_logic_vector(f_ces_resize(unsigned(l_vec), res_w) + unsigned(r_vec));
  end;

  function f_sub_uns(l_vec : std_logic_vector; r_vec : std_logic_vector; res_w : natural) return std_logic_vector is
  begin
    return std_logic_vector(f_ces_resize(unsigned(l_vec), res_w) - unsigned(r_vec));
  end;

  function f_add_sig(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector is
  begin
    return f_add_sig(l_vec, r_vec, l_vec'length);
  end;

  function f_sub_sig(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector is
  begin
    return f_sub_sig(l_vec, r_vec, l_vec'length);
  end;

  function f_add_uns(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector is
  begin
    return f_add_uns(l_vec, r_vec, l_vec'length);
  end;

  function f_sub_uns(l_vec : std_logic_vector; r_vec : std_logic_vector) return std_logic_vector is
  begin
    return f_sub_uns(l_vec, r_vec, l_vec'length);
  end;

  function f_full_precision_num_width(quantization, overflow, old_width,
                                      old_bin_pt, old_arith,
                                      new_width, new_bin_pt, new_arith : integer)
    return integer
  is
    variable v_result : integer;
  begin
    v_result := old_width + 2;
    return v_result;
  end;

  function f_quantized_num_width(quantization, overflow, old_width, old_bin_pt,
                                 old_arith, new_width, new_bin_pt, new_arith
                                 : integer)
    return integer
  is
	variable v_result      : integer;
  begin
    v_result      := (old_width + 2) + (new_bin_pt - old_bin_pt);
    return v_result;
  end;

  function f_convert_type (inp                    : std_logic_vector; old_width, old_bin_pt,
                           old_arith, new_width, new_bin_pt, new_arith,
                           quantization, overflow : integer)
    return std_logic_vector
  is
    constant C_FP_WIDTH : integer :=
      f_full_precision_num_width(quantization, overflow, old_width,
                                 old_bin_pt, old_arith, new_width,
                                 new_bin_pt, new_arith);
    constant C_FP_BIN_PT             : integer := old_bin_pt;
    constant C_FP_ARITH              : integer := old_arith;
    constant C_Q_WIDTH               : integer :=
      f_quantized_num_width(quantization, overflow, old_width, old_bin_pt,
                            old_arith, new_width, new_bin_pt, new_arith);
    constant C_Q_BIN_PT         : integer := new_bin_pt;
    constant C_Q_ARITH          : integer := old_arith;
    variable v_full_precision_result : std_logic_vector(C_FP_WIDTH-1 downto 0);
    variable v_quantized_result : std_logic_vector(C_Q_WIDTH-1 downto 0);
    variable v_result           : std_logic_vector(new_width-1 downto 0);
  begin
    v_result := (others => '0');
    v_full_precision_result := f_cast(inp, old_bin_pt, C_FP_WIDTH, C_FP_BIN_PT,
                                    C_FP_ARITH);
    if (quantization = C_CES_ROUND_INF) then
      v_quantized_result := f_round_towards_inf(v_full_precision_result,
                                              C_FP_WIDTH, C_FP_BIN_PT,
                                              C_FP_ARITH, C_Q_WIDTH, C_Q_BIN_PT,
                                              C_Q_ARITH);
    elsif (quantization = C_CES_ROUND_NEAREST) then
      v_quantized_result := f_round_towards_even(v_full_precision_result,
                                               C_FP_WIDTH, C_FP_BIN_PT,
                                               C_FP_ARITH, C_Q_WIDTH, C_Q_BIN_PT,
                                               C_Q_ARITH);
    else
      v_quantized_result := f_trunc(v_full_precision_result, C_FP_WIDTH, C_FP_BIN_PT,
                                  C_FP_ARITH, C_Q_WIDTH, C_Q_BIN_PT, C_Q_ARITH);
    end if;
    if (overflow = C_CES_SATURATE) then
      v_result := f_saturation_arith(v_quantized_result, C_Q_WIDTH, C_Q_BIN_PT,
                                   C_Q_ARITH, new_width, new_bin_pt, new_arith);
    else
      v_result := f_wrap_arith(v_quantized_result, C_Q_WIDTH, C_Q_BIN_PT, C_Q_ARITH,
                             new_width, new_bin_pt, new_arith);
    end if;
    return v_result;
  end;

  function f_cast (inp                   : std_logic_vector; old_bin_pt, new_width,
                   new_bin_pt, new_arith : integer)
    return std_logic_vector
  is
    constant C_OLD_WIDTH  : integer := inp'length;
    constant C_RIGHT_OF_DP : integer := (new_bin_pt - old_bin_pt);
    variable v_vec         : std_logic_vector(C_OLD_WIDTH-1 downto 0);
    variable v_result      : std_logic_vector(new_width-1 downto 0);
    variable v_j           : integer;
  begin
    v_vec := inp;
    for i in new_width-1 downto 0 loop
      v_j := i - C_RIGHT_OF_DP;
      if (v_j > C_OLD_WIDTH-1) then
        if (new_arith = C_CES_UNSIGNED) then
          v_result(i) := '0';
        else
          v_result(i) := v_vec(C_OLD_WIDTH-1);
        end if;
      elsif (v_j >= 0) then
        v_result(i) := v_vec(v_j);
      else
        v_result(i) := '0';
      end if;
    end loop;
    return v_result;
  end;

  ------------------------------------------------------------------------------
  -- Quantization Functions

  -- Truncate LSB bits
  function f_trunc(inp : std_logic_vector; old_width, old_bin_pt, old_arith, new_width, new_bin_pt, new_arith : integer) return std_logic_vector is
    -- Number of binary digits to add/subract to the right of the decimal
    -- point
    constant C_RIGHT_OF_DP : integer := (old_bin_pt - new_bin_pt);
    variable v_vec         : std_logic_vector(old_width - 1 downto 0);
    variable v_result      : std_logic_vector(new_width - 1 downto 0);
  begin
    v_vec := inp;

    if C_RIGHT_OF_DP >= 0 then
      -- Sign Extent or zero extend if necessary
      if new_arith = C_CES_UNSIGNED then
        v_result := f_zero_ext(v_vec(old_width - 1 downto C_RIGHT_OF_DP), new_width);
      else
        v_result := f_sign_ext(v_vec(old_width - 1 downto C_RIGHT_OF_DP), new_width);
      end if;
    else
      -- Pad LSB with zeros and sign extend by one bit
      if new_arith = C_CES_UNSIGNED then
        v_result := f_zero_ext(f_pad_LSB(v_vec, old_width + abs (C_RIGHT_OF_DP)), new_width);
      else
        v_result := f_sign_ext(f_pad_LSB(v_vec, old_width + abs (C_RIGHT_OF_DP)), new_width);
      end if;
    end if;
    return v_result;
  end;  --f_trunc


  -- Round towards infinity
  function f_round_towards_inf(inp : std_logic_vector; old_width, old_bin_pt, old_arith, new_width, new_bin_pt, new_arith : integer) return std_logic_vector is
    -- Number of binary digits to add/subract to the right of the decimal
    -- point
    constant C_RIGHT_OF_DP : integer := (old_bin_pt - new_bin_pt);

    variable v_vec                : std_logic_vector(old_width - 1 downto 0);
    variable v_one_or_zero        : std_logic_vector(new_width - 1 downto 0);
    variable v_truncated_val      : std_logic_vector(new_width - 1 downto 0);
    variable v_result             : std_logic_vector(new_width - 1 downto 0);
  begin
    v_vec := inp;

    if C_RIGHT_OF_DP >= 0 then
      -- Sign extend or zero extend to size of output
      if new_arith = C_CES_UNSIGNED then
        v_truncated_val := f_zero_ext(v_vec(old_width - 1 downto C_RIGHT_OF_DP),
                                    new_width);
      else
        v_truncated_val := f_sign_ext(v_vec(old_width - 1 downto C_RIGHT_OF_DP),
                                    new_width);
      end if;
    else
      -- Pad LSB with zeros and sign extend by one bit
      if new_arith = C_CES_UNSIGNED then
        v_truncated_val := f_zero_ext(f_pad_LSB(v_vec, old_width + abs (C_RIGHT_OF_DP)), new_width);
      else
        v_truncated_val := f_sign_ext(f_pad_LSB(v_vec, old_width + abs (C_RIGHT_OF_DP)), new_width);
      end if;
    end if;

    -- Figure out if '1' should be added to the truncated number
    v_one_or_zero := (others => '0');

    if (new_arith = C_CES_SIGNED) then
      -- Roundeing logic for signed numbers
      --   Example:
      --                 Fix(5,-2) = 101.11 (bin) -2.25 (dec)
      --   Converted to: Fix(4,-1) = 101.1  (bin) -2.5  (dec)
      --   Note: same algorithm used for unsigned numbers can't be used.

      -- 1st check the sign bit of the input to see if it is a positive
      -- number
      if (v_vec(old_width - 1) = '0') then
        v_one_or_zero(0) := '1';
      end if;

      -- 2nd check if digits being truncated are all zeros
      --  (in example it is bit zero)
      if (C_RIGHT_OF_DP >= 2) and (C_RIGHT_OF_DP <= old_width) then
        if (f_all_zeros(v_vec(C_RIGHT_OF_DP - 2 downto 0)) = false) then
          v_one_or_zero(0) := '1';
        end if;
      end if;

      -- 3rd check if the bit right before the truncation point is '1'
      -- or '0' (in example it is bit one)
      if (C_RIGHT_OF_DP >= 1) and (C_RIGHT_OF_DP <= old_width) then
        if v_vec(C_RIGHT_OF_DP - 1) = '0' then
          v_one_or_zero(0) := '0';
        end if;
      else
        -- No rounding to be performed
        v_one_or_zero(0) := '0';
      end if;
    else
      -- For an unsigned number just check if the bit right before the
      -- truncation point is '1' or '0'
      if (C_RIGHT_OF_DP >= 1) and (C_RIGHT_OF_DP <= old_width) then
        v_one_or_zero(0) := v_vec(C_RIGHT_OF_DP - 1);
      end if;
    end if;

    if new_arith = C_CES_SIGNED then
      v_result := f_sig2slv(f_slv2sig(v_truncated_val) + f_slv2sig(v_one_or_zero));
    else
      v_result := f_uns2slv(f_slv2uns(v_truncated_val) + f_slv2uns(v_one_or_zero));
    end if;

    return v_result;
  end;  --f_round_towards_inf


  -- Round towards even values
  function f_round_towards_even(inp : std_logic_vector; old_width, old_bin_pt, old_arith, new_width, new_bin_pt, new_arith : integer) return std_logic_vector is
    -- Number of binary digits to add/subract to the right of the decimal
    -- point
    constant C_RIGHT_OF_DP : integer := (old_bin_pt - new_bin_pt);

    variable v_vec                : std_logic_vector(old_width - 1 downto 0);
    variable v_one_or_zero        : std_logic_vector(new_width - 1 downto 0);
    variable v_truncated_val      : std_logic_vector(new_width - 1 downto 0);
    variable v_result             : std_logic_vector(new_width - 1 downto 0);
  begin
    v_vec := inp;

    if C_RIGHT_OF_DP >= 0 then
      -- Sign extend or zero extend to size of output
      if new_arith = C_CES_UNSIGNED then
        v_truncated_val := f_zero_ext(v_vec(old_width - 1 downto C_RIGHT_OF_DP),
                                    new_width);
      else
        v_truncated_val := f_sign_ext(v_vec(old_width - 1 downto C_RIGHT_OF_DP),
                                    new_width);
      end if;

    else
      -- Pad LSB with zeros and sign extend by one bit
      if new_arith = C_CES_UNSIGNED then
        v_truncated_val := f_zero_ext(f_pad_LSB(v_vec, old_width + abs (C_RIGHT_OF_DP)), new_width);
      else
        v_truncated_val := f_sign_ext(f_pad_LSB(v_vec, old_width + abs (C_RIGHT_OF_DP)), new_width);
      end if;
    end if;

    -- Figure out if '1' should be added to the truncated number
    v_one_or_zero := (others => '0');

    -- For the truncated bits just check if the bits after the
    -- truncation point are 0.5
    if (C_RIGHT_OF_DP >= 1) and (C_RIGHT_OF_DP <= old_width) then
      if (f_is_point_five(v_vec(C_RIGHT_OF_DP - 1 downto 0)) = false) then
        v_one_or_zero(0) := v_vec(C_RIGHT_OF_DP - 1);
      else
        v_one_or_zero(0) := v_vec(C_RIGHT_OF_DP);
      end if;
    end if;

    if new_arith = C_CES_SIGNED then
      v_result := f_sig2slv(f_slv2sig(v_truncated_val) + f_slv2sig(v_one_or_zero));
    else
      v_result := f_uns2slv(f_slv2uns(v_truncated_val) + f_slv2uns(v_one_or_zero));
    end if;

    return v_result;
  end;  --f_round_towards_even

  function f_format_input(inp : std_logic_vector; old_width, delta, new_width, arith : integer) return std_logic_vector is
    variable v_vec        : std_logic_vector(old_width - 1 downto 0);
    variable v_padded_inp : std_logic_vector((old_width + delta) - 1 downto 0);
    variable v_result     : std_logic_vector(new_width - 1 downto 0);
  begin
    v_vec := inp;
    if (delta > 0) then
      v_padded_inp := f_pad_LSB(v_vec, old_width + delta);
      v_result     := f_extend_MSB(v_padded_inp, new_width, arith);
    else
      v_result := f_extend_MSB(v_vec, new_width, arith);
    end if;
    return v_result;
  end;


  function f_saturation_arith(inp : std_logic_vector; old_width, old_bin_pt,
                              old_arith, new_width, new_bin_pt, new_arith
                              : integer)
    return std_logic_vector
  is
    variable v_vec      : std_logic_vector(old_width-1 downto 0);
    variable v_result   : std_logic_vector(new_width-1 downto 0);
    variable v_overflow : boolean;
  begin
    v_vec      := inp;
    v_overflow := true;
    v_result   := (others => '0');
    if (new_width >= old_width) then
      v_overflow := false;
    end if;
    if ((old_arith = C_CES_SIGNED and new_arith = C_CES_SIGNED) and (old_width > new_width)) then
      if f_all_same(v_vec(old_width-1 downto new_width-1)) then
        v_overflow := false;
      end if;
    end if;
    if (old_arith = C_CES_SIGNED and new_arith = C_CES_UNSIGNED) then
      if (old_width > new_width) then
        if f_all_zeros(v_vec(old_width-1 downto new_width)) then
          v_overflow := false;
        end if;
      else
        if (old_width = new_width) then
          if (v_vec(new_width-1) = '0') then
            v_overflow := false;
          end if;
        end if;
      end if;
    end if;
    if (old_arith = C_CES_UNSIGNED and new_arith = C_CES_UNSIGNED) then
      if (old_width > new_width) then
        if f_all_zeros(v_vec(old_width-1 downto new_width)) then
          v_overflow := false;
        end if;
      else
        if (old_width = new_width) then
          v_overflow := false;
        end if;
      end if;
    end if;
    if ((old_arith = C_CES_UNSIGNED and new_arith = C_CES_SIGNED) and (old_width > new_width)) then
      if f_all_same(v_vec(old_width-1 downto new_width-1)) then
        v_overflow := false;
      end if;
    end if;
    if v_overflow then
      if new_arith = C_CES_SIGNED then
        if v_vec(old_width-1) = '0' then
          v_result := f_max_signed(new_width);
        else
          v_result := f_min_signed(new_width);
        end if;
      else
        if ((old_arith = C_CES_SIGNED) and v_vec(old_width-1) = '1') then
          v_result := (others => '0');
        else
          v_result := (others => '1');
        end if;
      end if;
    else
      if (old_arith = C_CES_SIGNED) and (new_arith = C_CES_UNSIGNED) then
        if (v_vec(old_width-1) = '1') then
          v_vec := (others => '0');
        end if;
      end if;
      if new_width <= old_width then
        v_result := v_vec(new_width-1 downto 0);
      else
        if new_arith = C_CES_UNSIGNED then
          v_result := f_zero_ext(v_vec, new_width);
        else
          v_result := f_sign_ext(v_vec, new_width);
        end if;
      end if;
    end if;
    return v_result;
  end;

  function f_wrap_arith(inp                                         : std_logic_vector; old_width, old_bin_pt,
                        old_arith, new_width, new_bin_pt, new_arith : integer)
    return std_logic_vector
  is
    variable v_result       : std_logic_vector(new_width-1 downto 0);
    variable v_result_arith : integer;
  begin
    if (old_arith = C_CES_SIGNED) and (new_arith = C_CES_UNSIGNED) then
      v_result_arith := C_CES_SIGNED;
    end if;
    v_result := f_cast(inp, old_bin_pt, new_width, new_bin_pt, v_result_arith);
    return v_result;
  end;

  ------------------------------------------------------------------------------
  -- Binary point alignment functions

  -- sign extend the MSB
  function f_sign_ext(inp : std_logic_vector; new_width : integer) return std_logic_vector is
    constant C_OLD_WIDTH : integer := inp'length;
    variable v_vec       : std_logic_vector(C_OLD_WIDTH - 1 downto 0);
    variable v_result    : std_logic_vector(new_width - 1 downto 0);
  begin
    v_vec := inp;
    -- sign extend
    if new_width >= C_OLD_WIDTH then
      v_result(C_OLD_WIDTH - 1 downto 0) := v_vec;
      if new_width - 1 >= C_OLD_WIDTH then
        for i in new_width - 1 downto C_OLD_WIDTH loop
          v_result(i) := v_vec(C_OLD_WIDTH - 1);
        end loop;
      end if;
    else
      v_result(new_width - 1 downto 0) := v_vec(new_width - 1 downto 0);
    end if;

    return v_result;
  end;  --f_sign_ext


  -- zero extend the MSB
  function f_zero_ext(inp : std_logic_vector; new_width : integer) return std_logic_vector is
    constant C_OLD_WIDTH : integer := inp'length;
    variable v_vec       : std_logic_vector(C_OLD_WIDTH - 1 downto 0);
    variable v_result    : std_logic_vector(new_width - 1 downto 0);
  begin
    v_vec := inp;

    -- zero extend
    if new_width >= C_OLD_WIDTH then
      v_result(C_OLD_WIDTH - 1 downto 0) := v_vec;
      if new_width - 1 >= C_OLD_WIDTH then
        for i in new_width - 1 downto C_OLD_WIDTH loop
          v_result(i) := '0';
        end loop;
      end if;
    else
      v_result(new_width - 1 downto 0) := v_vec(new_width - 1 downto 0);
    end if;

    return v_result;
  end;  --f_zero_ext


  -- zero extend the MSB
  function f_zero_ext(inp : std_logic; new_width : integer) return std_logic_vector is
    variable v_result : std_logic_vector(new_width - 1 downto 0);
  begin
    v_result(0) := inp;
    for i in new_width - 1 downto 1 loop
      v_result(i) := '0';
    end loop;

    return v_result;
  end;  --f_zero_ext

  -- Pad LSB with zeros
  function f_pad_LSB(inp : std_logic_vector; new_width : integer) return std_logic_vector is
    constant C_ORIG_WIDTH : integer := inp'length;
    -- Added for XST
    constant C_PAD_POS    : integer := new_width - C_ORIG_WIDTH - 1;
    variable v_vec        : std_logic_vector(C_ORIG_WIDTH - 1 downto 0);
    variable v_result     : std_logic_vector(new_width - 1 downto 0);
    variable v_pos        : integer;
    

  begin
    v_vec := inp;
    v_pos := new_width - 1;
    if (new_width >= C_ORIG_WIDTH) then
      for i in C_ORIG_WIDTH - 1 downto 0 loop
        v_result(v_pos) := v_vec(i);
        v_pos         := v_pos - 1;
      end loop;
      if C_PAD_POS >= 0 then
        for i in C_PAD_POS downto 0 loop
          v_result(i) := '0';
        end loop;
      end if;
    end if;

    return v_result;
  end;  --f_pad_LSB


  -- Pad LSB with zeros and add a zero or sign extend the MSB
  function f_pad_LSB(inp : std_logic_vector; new_width, arith : integer) return std_logic_vector is
    constant C_ORIG_WIDTH : integer := inp'length;
    variable v_vec        : std_logic_vector(C_ORIG_WIDTH - 1 downto 0);
    variable v_result     : std_logic_vector(new_width - 1 downto 0);
    variable v_pos        : integer;
  begin
    v_vec := inp;
    v_pos := new_width - 1;

    if (arith = C_CES_UNSIGNED) then
      -- set MSB to zero
      v_result(v_pos) := '0';
      v_pos         := v_pos - 1;
    else
      -- sign extend
      v_result(v_pos) := v_vec(C_ORIG_WIDTH - 1);
      v_pos         := v_pos - 1;
    end if;

    if (new_width >= C_ORIG_WIDTH) then
      for i in C_ORIG_WIDTH - 1 downto 0 loop
        v_result(v_pos) := v_vec(i);
        v_pos         := v_pos - 1;
      end loop;
      if v_pos >= 0 then
        for i in v_pos downto 0 loop
          v_result(i) := '0';
        end loop;
      end if;
    end if;

    return v_result;
  end;  --f_pad_LSB

  function f_extend_MSB(inp : std_logic_vector; new_width, arith : integer) return std_logic_vector is
    constant C_ORIG_WIDTH : integer := inp'length;
    variable v_vec        : std_logic_vector(C_ORIG_WIDTH - 1 downto 0);
    variable v_result     : std_logic_vector(new_width - 1 downto 0);
  begin
    v_vec := inp;
    if arith = C_CES_UNSIGNED then
      v_result := f_zero_ext(v_vec, new_width);
    else
      v_result := f_sign_ext(v_vec, new_width);
    end if;
    return v_result;
  end;

  function f_count_l_zeros(signal s_vector : std_logic_vector) return std_logic_vector is
    variable v_count : std_logic_vector(5 downto 0);
  begin
    v_count := "000000";
    for i in s_vector'range loop
      case s_vector(i) is
        when '0'    => v_count := std_logic_vector(unsigned(v_count) + 1);
        when others => exit;
      end case;
    end loop;
    return v_count;
  end f_count_l_zeros;

  --
  function f_count_zeros_mul(signal s_vector : unsigned) return std_logic_vector is
    variable v_count : std_logic_vector(5 downto 0);
  begin
    v_count := "000000";
    for i in 105 downto 52 loop
      case s_vector(i) is
        when '0'    => v_count := std_logic_vector(unsigned(v_count) + 1);
        when others => exit;
      end case;
    end loop;
    return v_count;
  end f_count_zeros_mul;

  -- CGE merged function f_ramp_array 
  function f_ramp_array(g_array_size, g_data_w, g_representation, init, step : in integer) return std_logic_vector is
    variable v_result : std_logic_vector(g_array_size * g_data_w - 1 downto 0);

  begin
    for index in 0 to g_array_size - 1 loop
      if g_representation = C_CES_UNSIGNED then
        v_result((index + 1) * g_data_w - 1 downto index * g_data_w) := std_logic_vector(to_unsigned(step * index + init, g_data_w));
      elsif g_representation = C_CES_SIGNED then
        v_result((index + 1) * g_data_w - 1 downto index * g_data_w) := std_logic_vector(to_signed(step * index + init, g_data_w));
      end if;
    end loop;

    return v_result;
  end function f_ramp_array;

  ------------------------------------------------------------------------------
  -- Debugging functions
  ------------------------------------------------------------------------------
  -- synthesis translate_off
  -- Check for Undefined values
  function f_is_XorU(inp : std_logic_vector) return boolean is
    constant C_WIDTH  : integer := inp'length;
    variable v_vec    : std_logic_vector(C_WIDTH - 1 downto 0);
    variable v_result : boolean;
  begin
    v_vec    := inp;
    v_result := false;
    for i in 0 to C_WIDTH - 1 loop
      if (v_vec(i) = 'U') or (v_vec(i) = 'X') then
        v_result := true;
      end if;
    end loop;
    return v_result;
  end;  --f_is_XorU
  -- synthesis translate_on 

  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------

  function f_count_delta(vector_i : unsigned) return unsigned is
    variable v_vector : unsigned(vector_i'left downto 0);
    --variable v_delta : natural range 0 to vector_i'length := vector_i'length;
    variable v_delta  : unsigned(f_ceil_log2(vector_i'length) downto 0) := to_unsigned(vector_i'length, f_ceil_log2(vector_i'length)+1);
  begin
    v_vector := vector_i;
    for i in 0 to v_vector'left loop
      if v_vector(v_vector'left -i) = '1' then
        --v_delta := i;
        v_delta := to_unsigned(i, v_delta'length);
        exit;
      end if;
    end loop;
    return v_delta;
  end;
  --
  function f_count_length(vector_i : unsigned) return unsigned is
    variable v_vector : unsigned(vector_i'left downto 0);
    variable v_delta  : unsigned(f_ceil_log2(vector_i'length) downto 0) := to_unsigned(vector_i'length, f_ceil_log2(vector_i'length)+1);  --natural range 0 to vector_i'length := vector_i'length;
  begin
    v_vector := vector_i;
    for i in 0 to v_vector'left loop
      if v_vector(v_vector'left -i) = '1' then
        v_delta := to_unsigned(v_vector'length, v_delta'length) -to_unsigned(i, v_delta'length);
        exit;
      end if;
    end loop;
    return v_delta;
  end;
  --
  function f_count_tail(vector_i : unsigned) return unsigned is
    variable v_vector : unsigned(vector_i'left downto 0);
    variable v_delta  : unsigned(f_ceil_log2(vector_i'length) downto 0) := (others => '0');  --natural range 0 to vector_i'length := 0;
  begin
    v_vector := vector_i;
    for i in 0 to v_vector'left loop
      if v_vector(i) = '1' then
        v_delta := to_unsigned(i, v_delta'length);
        exit;
      else
        v_delta := to_unsigned(v_vector'length, v_delta'length);
      end if;
    end loop;
    return v_delta;
  end;
  --
  function f_count_kernel(vector_i : unsigned) return unsigned is
    variable v_vector : unsigned(vector_i'left downto 0);
    variable v_kernel : unsigned(f_ceil_log2(vector_i'length) downto 0) := (others => '0');  --natural range 0 to vector_i'length := 0;
    variable v_i      : unsigned(f_ceil_log2(vector_i'length) downto 0);  --natural range 0 to vector_i'length;   
  begin
    v_vector := vector_i;
    if v_vector > 0 then
      for i in 0 to v_vector'left loop
        if v_vector(v_vector'left -i) = '1' then
          v_i := to_unsigned(i, v_i'length);
          exit;
        end if;
      end loop;
      for j in 0 to v_vector'left loop
        if v_vector(j) = '1' then
          v_kernel := to_unsigned(v_vector'length, v_i'length) -v_i -to_unsigned(j, v_i'length);
          exit;
        end if;
      end loop;
    else
      v_kernel := (others => '0');
    end if;
    return v_kernel;
  end;
  --
  function f_all_ones(vector_i : unsigned) return std_logic is
    variable v_vector : unsigned(vector_i'left downto 0);
    variable v_result : std_logic := '1';
  begin
    v_vector := vector_i;
    --        if v_vector > 0 then
    --            for i in 0 to v_vector'left loop
    --                if v_vector(i) = '0' then
    --                    v_result := '0';
    --                    exit;
    --                end if;
    --            end loop;
    --        else
    --            v_result := '0';
    --        end if;
    if not v_vector = 0 then
      v_result := '1';
    else
      v_result := '0';
    end if;
    return v_result;
  end;
  --
  --
  function f_left_clear(vector_i : unsigned; ind : natural) return std_logic is
    variable v_vector : unsigned(vector_i'left downto 0);
    variable v_result : std_logic := '1';
  begin
    v_vector := vector_i;
    for i in 1 to v_vector'left loop
      if v_vector(ind +i) = '1' then
        v_result := '0';
        exit;
      end if;
    end loop;
    return v_result;
  end;
  --
  function f_resize_right(vector_in : unsigned; length_out : natural) return unsigned is
    variable v_vector_out : unsigned(length_out -1 downto 0);
  begin
    if vector_in'length <= length_out then
      for i in 0 to vector_in'left loop
        v_vector_out(v_vector_out'left -i) := vector_in(vector_in'left -i);
      end loop;
      v_vector_out(v_vector_out'left -vector_in'length downto 0) := (others => '0');
    else
      v_vector_out(v_vector_out'left downto 0) := vector_in(vector_in'left downto vector_in'left - v_vector_out'left);
    end if;
    return v_vector_out;
  end;
  --
  function f_bump_right(in_vector : unsigned) return unsigned is
    variable v_vector : unsigned(in_vector'left downto 0);
  begin
    v_vector := in_vector;
    --if v_vector > 0 then
    for i in 0 to v_vector'left loop
      if v_vector(i) = '1' then
        v_vector := (i-1 downto 0 => '0') & v_vector(v_vector'left downto i);
        exit;
      end if;
    end loop;
    --end if;
    return v_vector;
  end;
  --
  function f_int_to_sl(in_num : integer) return std_logic is
    variable v_sl : std_logic;
  begin
    if in_num = 0 then
      v_sl := '0';
    else
      v_sl := '1';
    end if;
    return v_sl;
  end;
  --
  function f_bump_left(in_vector : unsigned) return unsigned is
    variable v_vector : unsigned(in_vector'left downto 0);
  begin
    v_vector := in_vector;
    --if v_vector > 0 then
    for i in 0 to v_vector'left loop
      if v_vector(v_vector'left-i) = '1' then
        --v_vector := v_vector(v_vector'left-i downto 0) & (i-1 downto 0 => '0');
        v_vector := shift_left(v_vector, i);
        exit;
      end if;
    end loop;
    --end if;
    return v_vector;
  end;
  --
  function f_rightshift(vector_i : unsigned; delta_i : natural) return unsigned is
    variable v_vector : unsigned(vector_i'left downto 0) := (others => '0');
  --variable v_vector : unsigned(vector_i'left downto 0) := (others => '11');
  begin
    for i in delta_i to vector_i'left loop
      v_vector(i -delta_i) := vector_i(i);
    end loop;
    return v_vector;
  end;
  --
  function f_leftshift(vector_i : unsigned; delta_i : natural) return unsigned is
    variable v_vector : unsigned(vector_i'left downto 0) := (others => '0');
  --variable v_vector : unsigned(vector_i'left downto 0) := (others => '11');
  begin
    for i in 0 to vector_i'left -delta_i loop
      v_vector(i +delta_i) := vector_i(i);
    end loop;
    return v_vector;
  end;
  --
  function f_divide_by_two(number_i : integer; depth_i : natural) return integer is
    variable v_number : unsigned(depth_i -1 downto 0);
    variable v_result : integer;
  begin
    if number_i >= 0 then
      v_number := '0' & to_unsigned(number_i, depth_i)(v_number'left downto 1);
      v_result := to_integer(v_number);
    else
      v_number := '0' & to_unsigned(-number_i, depth_i)(v_number'left downto 1);
      v_result := -to_integer(v_number);
    end if;
    return v_result;
  end;
  --
  --    function f_multiply_by_three(number_i: integer; depth_i: natural) return integer is
  --        variable v_number : unsigned(depth_i -1 downto 0);
  --        variable v_result : integer;
  --    begin
  --        if number_i >= 0 then
  --            v_number := to_unsigned(number_i,depth_i)(v_number'left -2 downto 0) & "00" -to_unsigned(number_i,depth_i);
  --            v_result := to_integer(v_number);
  --        else
  --            v_number := to_unsigned(-number_i,depth_i)(v_number'left -2 downto 0) & "00" -to_unsigned(-number_i,depth_i);
  --            v_result := -to_integer(v_number);
  --        end if;
  --        return v_result;
  --    end;
  --
  function f_multiply_by_three(number_i : unsigned) return unsigned is
    variable v_number : unsigned(number_i'left downto 0);
    variable v_result : unsigned(number_i'left downto 0);
  begin
    v_number := number_i(v_number'left -2 downto 0) & "00" - number_i;
    v_result := v_number;
    return v_result;
  end;
  --
  function f_square(number_i : unsigned) return unsigned is
    variable v_number : unsigned(2*number_i'length -1 downto 0) := (others => '0');
    variable v_aux_in : unsigned(2*number_i'length -1 downto 0) := (others => '0');
    variable v_result : unsigned(number_i'left downto 0);
  begin
    for i in 0 to number_i'left loop
      if number_i(i) = '1' then
        v_aux_in(number_i'left +i downto i)                := number_i;
        v_aux_in(v_aux_in'left downto number_i'left +i +1) := (others => '0');
        if i > 0 then
          v_aux_in(i -1 downto 0) := (others => '0');
        end if;
      else
        v_aux_in := (others => '0');
      end if;
      v_number := v_number +v_aux_in;
      v_result := v_number(v_result'left downto 0);
    end loop;
    return v_result;
  end;

  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------

--  function f_multiplier_size_get(target_i : t_target) return t_multiplier_size is
--    variable v_multiplier : t_multiplier_size;
--  begin
--    if target_i.vendor = C_XILINX and target_i.family = C_SPARTAN6 then
--      v_multiplier(0) := 24;
--      v_multiplier(1) := 17;
--    elsif target_i.vendor = C_XILINX and target_i.family = C_SPARTAN6 then
--      v_multiplier(0) := 24;
--      v_multiplier(1) := 17;
--    end if;
--    return v_multiplier;
--  end;

  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------


end ces_math_pkg;
