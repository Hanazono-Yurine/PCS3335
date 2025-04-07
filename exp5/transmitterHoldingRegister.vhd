library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBestForHoldingRegister is
	generic (
		WIDTH : natural := 8
	);
	port (
		clock 	: in std_logic;
		reset   : in std_logic;
		load    : in std_logic;
		data_i 	: in std_logic_vector( WIDTH-1 downto 0 );
		data_o 	: out std_logic_vector( WIDTH-1 downto 0 )
	);
end entity;

architecture behave of waifusAreTheBestForHoldingRegister is

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

	signal loadReg : std_logic_vector( 1 downto 0);

begin

	THR: shiftregister
	generic map (
		WIDTH => WIDTH
	)
	port map (
		clock       => clock,
		reset       => reset,
		serial_i    => '0',
		loadOrShift => loadReg,
		data_i      => data_i,
		data_o      => data_o
		--serial_o_r  => serial
		--serial_o_l  => serial_o_l
	);

	loadReg <= "11" when load = '1' else "00";

end architecture;
