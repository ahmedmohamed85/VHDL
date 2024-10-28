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

entity coarse_maximum is
  generic (
    G_DATA_WIDTH   : integer := 32;  -- Width of the input and output data
    G_BIN_POINT    : integer := 16    -- Binary point for fixed-point representation
    );
  Port ( 
    rstn_i : in std_logic;
    clk_i  : in std_logic;
    sync_i   : in std_logic;
    first_time_i  : in fi_complex_number;
    second_time_i : in fi_complex_number;
    open_window_i   : in std_logic;
    corr_total_o : in fi_complex_number;
    pos_max_corr_tot_o : out std_logic_vector(7 downto 0);
    max_found_o : out std_logic
    );
end coarse_maximum;

architecture Behavioral of coarse_maximum is
  type t_delay_buffer is array(0 to 224) of std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal s_delay_buff : t_delay_buffer;
  signal s_open_window : std_logic;
  signal s_abs_square  : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal s_max_value   : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal s_counter_window : unsigned(7 downto 0);
  signal s_pos_max_corr_tot : unsigned(7 downto 0);
begin

  inst_ces_math_fi_abs_square: entity ces_math_lib.ces_math_fi_abs_square
    generic map (
        G_OUTPUT_DATA_WIDTH => G_DATA_WIDTH,
        G_OUTPUT_BIN_POINT  => G_BIN_POINT
    )
    port map (
        clk_i         => clk_i,
        dv_i          => open_window_i,
        complex_in_i  => corr_total_o,
        abs_square_o  => s_abs_square,
        dv_o          => s_open_window
    );
    
  proc_delay_buffer: process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        s_counter_window <= (others=>'0');
        s_max_value      <= (others=>'0');
        s_delay_buff     <= (others=>(others=>'0'));
        max_found_o      <= '0';
      else
        if(s_open_window='1')then
          if(unsigned(s_max_value) < unsigned(s_abs_square))then
            s_max_value        <= s_abs_square;
            s_pos_max_corr_tot <= s_counter_window;
          end if;
          s_counter_window <= s_counter_window + 1;
          max_found_o      <= '0';
        elsif(s_counter_window/=0)then --* end of window
          s_counter_window   <= (others=>'0');
          s_max_value        <= (others=>'0');
          s_pos_max_corr_tot <= (others=>'0');
          pos_max_corr_tot_o <= std_logic_vector(s_pos_max_corr_tot);
          max_found_o        <= '1';
        else
          max_found_o        <= '0';
        end if;
      end if;
    end if;
  end process proc_delay_buffer; 
end Behavioral;
