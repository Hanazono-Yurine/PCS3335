library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity mainEntityExp2 is
    port (
        --output display-7-seg counter
        counter_seg2, counter_seg1, counter_seg0: out bit_vector(6 downto 0);

        --output display-7-seg shiftregister
        reg_seg2, reg_seg1, reg_seg0: out bit_vector(6 downto 0);

        --input counter
        counter_clock, counter_reset, counter_enable, counter_load, counter_up : in std_logic;
		-- counter_data_i : in std_logic_vector( 9 downto 0 );
        
        --input shiftregister
        reg_clock, reg_reset, reg_serial_i : in std_logic;
		reg_loadOrShift : in std_logic_vector( 1 downto 0 );
		-- reg_data_i : in std_logic_vector( 9 downto 0 );

        --entrada em paralelo das chaves
        keys_data_i : in std_logic_vector( 9 downto 0 );

        --origem do reg_data_i
        reg_source_data_i: in std_logic -- 0 -> reg_data_i <= chaves; 1 -> reg_data_i <= contador
    );
end entity;

