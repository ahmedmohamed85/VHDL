library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package gs_receiver_pkg is
    -- Constant declaration
    constant C_DATA_WIDTH : integer := 32;
    constant C_BIN_POINT : integer := 16;
    
    -- fi(0.007,1,32,16)
    constant C_THRESHOLD : std_logic_vector(C_DATA_WIDTH-1 downto 0) := 
    std_logic_vector(to_signed(459,C_DATA_WIDTH));
    -- Type definition
    type complex_number is record
      real_num : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      imag_num : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    end record;
    
    type t_complex_type is array(0 to 1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
    type t_array_64 is array (0 to 63) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
    type t_array_142 is array (0 to 143) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
    --* index 0 real, index 1 imaginary
    
    
    
    type t_complex_array_64 is array(0 to 63)  of complex_number;
    type t_complex_array_142 is array(0 to 63) of complex_number;
    -- Define the record type called sync_symbol
    type sync_symbol is record
        first_time      : t_complex_array_64;  -- Array of 64 elements, each C_DATA_WIDTH bits
        second_time     : t_complex_array_64;  -- Array of 64 elements, each C_DATA_WIDTH bits
        union           : t_complex_array_142;  -- Array of 142 elements, each C_DATA_WIDTH bits
    end record;
end package gs_receiver_pkg;

package body gs_receiver_pkg is


end package body gs_receiver_pkg;
