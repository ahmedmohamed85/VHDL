--==============================================================================
-- Module Name  : ces_math_fi_format
-- Library      : ces_math_lib
-- Project      : TIME DELAY BEAMFORMER
-- Company      : Campera Electronic Systems Srl
-- Author       : C. Gerval
--------------------------------------------------------------------------------
-- Description: format data for unsigned or signed representation, depending on input
-- and output width : (round or truncate) or padding 
--------------------------------------------------------------------------------
-- (c) Copyright 2014 Campera Electronic Systems Srl. Via Aurelia 136, Stagno
-- (Livorno), 57122, Italy. <www.campera-es.com>. All rights reserved. 
-- THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--------------------------------------------------------------------------------
-- Revision History:
-- Date        Version  Author      Description
-- 08/05/2015  1.0.0    C. Gerval   Initial release 
--
-- 19/12/2017  1.1.0    ACA         Only synchronous reset supported, generic
--                                  used to define the reset level.
--==============================================================================                        

-------------------------------------------------------------------------------
-- LIBRARIES
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ces_util_lib;
use ces_util_lib.ces_util_pkg.all;

library ces_math_lib;
use ces_math_lib.ces_math_pkg.all;

-------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------
--* @brief format data for unsigned or signed representation, depending on input
--* and output width : (round or truncate) or padding
entity ces_math_fi_format is
  generic(
    --* Number of bits encoding RX signals
    g_din_w          : natural := 18;
    --* Number of fractionnal bits encoding RX signals
    g_din_binpnt     : natural := 17;
    --* Number of bits encoding signals from memory (TX)
    g_dout_w         : natural := 18;
    --* Number of fractionnal bits encoding signals from memory (TX)
    g_dout_binpnt    : natural := 17;
    --* Number of pipelines on output (at least one is recommended with rounding)
    g_pipe_stages    : natural   := 1;
    --* Rounding mode (round: C_CES_ROUND, or truncate: C_CES_TRUNC)
    g_round_mode     : natural   := C_CES_ROUND; 
    --* Overflow style: C_CES_SATURATE or C_CES_WRAP
    g_overflow       : natural   := C_CES_SATURATE;
    --* Representation of signals: C_CES_SIGNED or C_CES_UNSIGNED
    g_representation : natural   := C_CES_SIGNED
    );
  port(
    --* Global clock signal
    clk_i  : in  std_logic;
    --* Signal to format
    din_i  : in  std_logic_vector(g_din_w - 1 downto 0);
    --* Signal formatted
    dout_o : out std_logic_vector(g_dout_w - 1 downto 0)
    );
end ces_math_fi_format;

-------------------------------------------------------------------------------
-- ARCHITECTURE
-------------------------------------------------------------------------------
architecture a_rtl of ces_math_fi_format is
  signal s_dout : std_logic_vector(g_dout_w - 1 downto 0);
  
begin  -- Begin architecture a_rtl                                                              
  
  --* Format output
  
  --s_dout <= f_trunc(din_i, g_din_w, g_din_binpnt, g_representation, g_dout_w, g_dout_binpnt, g_representation) when g_round_mode = C_CES_TRUNC
  --else f_round_towards_inf(din_i, g_din_w, g_din_binpnt, g_representation, g_dout_w, g_dout_binpnt, g_representation);
  
  s_dout <= f_convert_type (din_i,g_din_w, g_din_binpnt,
  g_representation, g_dout_w, g_dout_binpnt, g_representation,
  g_round_mode, g_overflow);
  
  
  gen_pipe : if g_pipe_stages > 0 generate
    inst_output_pipe : entity ces_util_lib.ces_util_delay
    generic map(
      g_delay   => g_pipe_stages,
      g_data_w  => g_dout_w
      )
    port map(
      clk_i  => clk_i,
      din_i  => s_dout,
      dout_o => dout_o
      );
  end generate gen_pipe; 
  
  gen_no_pipe : if g_pipe_stages = 0 generate
    dout_o <= s_dout;
  end generate gen_no_pipe;
  
end a_rtl;
