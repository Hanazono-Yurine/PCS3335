library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBestForShiftTransmitter is
	port (
		clockInput      : in std_logic;
		reset           : in std_logic;
		tsrDataInput		: in std_logic_vector( 7 downto 0 );
		tsrControl      : in std_logic_vector(2 downto 0);
		tsrOutput       : out std_logic;
	);
end entity;

architecture insides of waifusAreTheBestForShiftTransmitter is

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

	signal parityOdd, parityEven : std_logic := '0';
	signal sendBit, serial_out : std_logic := '0';
	signal loadFromTHR : std_logic := '0';
	signal registerControl : std_logic_vector( 1 downto 0);

begin

	parityOdd <= xor tsrInput when tsrControl = "001" else '1';
	parityEven <= not (xor tsrInput) when tsrControl = "001" else '1';

	TSR : shiftregister
	generic map (
		WIDTH => 8
	)
	port map (
		clock       => clockInput,
		reset       => reset,
		serial_i    => '0',
		loadOrShift => registerControl,
		data_i      => tsrInput,
		--data_o      => tsrOutput
		serial_o_r  => serial_out
		--serial_o_l  => serial_o_l
	);

	sendBit <= '0' when tsrControl = "001" else
						 serial_out when tsrControl = "010" else
						 parityEven when tsrControl = "100" else
						 parityOdd when tsrControl = "101" else
						 '1' when tsrControl = "011";

	registerControl <= "11" when tsrControl = "111" else
										 "01" when tsrControl = "010" else
										 "00";
						 
	tsrOutput < sendBit;

end architecture;
