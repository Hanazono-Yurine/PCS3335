library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;
use ieee.numeric_bit.rising_edge;

entity shiftregister is
	generic (
		WIDTH : natural := 8 -- Size in bits
	);
	port (
		clock, reset, serial_i : in std_logic;
		loadOrShift : in std_logic_vector( 1 downto 0 );
		data_i : in std_logic_vector( WIDTH-1 downto 0 );
		data_o : out std_logic_vector( WIDTH-1 downto 0 );
		serial_o_r, serial_o_l : out std_logic
	);
end shiftregister;

architecture arch_reg of shiftregister is
	signal data_temp : std_logic_vector( WIDTH-1 downto 0 ) := (others => '0');
begin

	process(clock)
	begin
		if ( reset = '1' ) then
			data_temp <= (others => '0');
		end if;

		if ( rising_edge(clock) ) then

			if ( loadOrShift = "11" ) then
				data_temp <= data_i;
			elsif ( loadOrShift = "01" ) then
				data_temp <= serial_i & data_temp( WIDTH-1 downto 1 );
			elsif ( loadOrShift = "10" ) then
				data_temp <= data_temp( WIDTH-2 downto 0 ) & serial_i;
			end if;

		end if;
	end process;

	data_o <= data_temp;
	serial_o_l <= data_temp( WIDTH-1 );
	serial_o_r <= data_temp( 0 );

end architecture;
