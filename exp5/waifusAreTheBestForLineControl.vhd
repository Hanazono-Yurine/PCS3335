library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBestForLineControl is
	port (
		clockInput	: in std_logic;
		reset 			: in std_logic;
		lcrInput		: in std_logic_vector( 7 downto 0 );
		lcrOutput		: out std_logic_vector( 7 downto 0 )
	);
end entity;

architecture insides of waifusAreTheBestForLineControl is

	component shiftregister is
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
	end component;

begin

	LCR : shiftregister
	generic map (
		WIDTH => 8
	)
	port map (
		clock       => clockInput,
		reset       => reset,
		serial_i    => '0',
		loadOrShift => "11",
		data_i      => lcrInput,
		data_o      => lcrOutput
		--serial_o_r  => serial_out
		--serial_o_l  => serial_o_l
	);

end architecture;
