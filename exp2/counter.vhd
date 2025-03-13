library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;
use ieee.numeric_bit.rising_edge;

entity counter is
	generic (
			WIDTH : natural := 8 -- Size in bits
	);
	port (
			clock, reset, enable, load, up : in std_logic;
			data_i : in std_logic_vector( WIDTH-1 downto 0 );
			data_o : out std_logic_vector( WIDTH-1 downto 0 );
	);
end counter;

architecture arch_count of counter is
	signal data_temp : std_logic_vector( WIDTH-1 downto 0 );
begin

	process(clock)
	begin

		if ( rising_edge(clock) and reset = '1' ) then
			data_temp <= (others => '0');
		elsif ( rising_edge(clock) and load = '1' ) then
			data_o <= data_temp;
		elsif ( rising_edge(clock) and up = '1' ) then
			data_temp <= data_temp + 1;
		elsif ( rising_edge(clock) and up = '0' ) then
			data_temp <= data_temp - 1;
		end if;

	end process;

end architecture;
