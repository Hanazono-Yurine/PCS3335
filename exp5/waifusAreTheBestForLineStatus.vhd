library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBestForLineStatus is
	port (
		clockInput	: in std_logic;
		reset 			: in std_logic;
		lsrInput		: in std_logic_vector( 7 downto 0 );
		lsrOutput		: out std_logic_vector( 7 downto 0 )
	);
end entity;

architecture insides of waifusAreTheBestForLineStatus is

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

	signal lsrInputValue	: std_logic_vector( 7 downto 0);
begin

	LCR : shiftregister
	generic map (
		WIDTH => 8
	)
	port map (
		clock       => clockInput,
		reset       => '0',
		serial_i    => '0',
		loadOrShift => "11",
		data_i      => lsrInputValue,
		data_o      => lsrOutput
		--serial_o_r  => serial_out
		--serial_o_l  => serial_o_l
	);

	-- Quando o LSR resetar, ele tem que ficar com "0110 0000"
	-- Entao quando ele resetar, ele vai fazer load desse valor ao inves de resetar de verdade
	lsrInputValue <= lsrInput when reset = '0' else "01100000";

end architecture;
