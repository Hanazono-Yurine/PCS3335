library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divisorLatch is
	generic (
		WIDTH : natural := 8
	);
	port (
		clock 	: in std_logic;
		data_i 	: in std_logic_vector( WIDTH-1 downto 0 );
		data_o 	: out std_logic_vector( WIDTH-1 downto 0 )
	);
end entity;

architecture behave of divisorLatch is

	component shiftregister is
		generic (
			WIDTH : natural := 8 -- Size in bits
		);
		port (
			clock, reset, serial_i 	: in std_logic;
			loadOrShift 						: in std_logic_vector( 1 downto 0 );
			data_i 									: in std_logic_vector( WIDTH-1 downto 0 );
			data_o 									: out std_logic_vector( WIDTH-1 downto 0 );
			serial_o_r, serial_o_l 	: out std_logic
		);
	end component;

begin

	DL: shiftregister
	generic map (
		WIDTH => WIDTH
	)
	port map (
		clock       => clock,
		reset       => '0',
		serial_i    => '0',
		loadOrShift => "11",
		data_i      => data_i,
		data_o      => data_o
		--serial_o_r  => serial
		--serial_o_l  => serial_o_l
	);

end architecture;
