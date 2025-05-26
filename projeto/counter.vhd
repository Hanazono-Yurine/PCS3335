library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_bit.rising_edge;

entity counter is
	generic (
		WIDTH : natural := 8 -- Size in bits
	);
	port (
		clock, reset, enable, load, up : in std_logic;
		data_i : in std_logic_vector( WIDTH-1 downto 0 );
		data_o : out std_logic_vector( WIDTH-1 downto 0 )
	);
end counter;

architecture arch_count of counter is
	signal data_temp : unsigned( WIDTH-1 downto 0 ) := (others => '0');
begin

	process(clock, reset)
	begin

		if ( reset = '1' ) then
			data_temp <= (others => '0');
		elsif ( rising_edge(clock) ) then
			if ( load = '1' ) then
				data_temp <= unsigned( data_i );
			elsif ( enable = '1' and up = '1' ) then
				data_temp <= data_temp + 1;
			elsif ( enable = '1' and up = '0' ) then
				data_temp <= data_temp - 1;
			end if;
		end if;

	end process;

	data_o <= std_logic_vector( data_temp );

end architecture;
