library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBestForClockGeneration is
	port (
		clockInput 		: in std_logic;
		reset 				: in std_logic;
		lsDivisorReg	: in std_logic_vector( 7 downto 0 );
		msDivisorReg	: in std_logic_vector( 7 downto 0 );
		clockDivided	: out std_logic
	);
end entity;

architecture insides of waifusAreTheBestForClockGeneration is

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

	component baudRateGenerator is
		port(
			clock     : in  std_logic;
			reset     : in  std_logic;
			divisor		: in  std_logic_vector(15 downto 0);
			baudOut_n : out std_logic
		);
	end component;

	signal lsDivisorRegOutput : std_logic_vector( 7 downto 0 );
	signal msDivisorRegOutput : std_logic_vector( 7 downto 0 );
	signal divisorValue 			: std_logic_vector( 15 downto 0 );
begin

	BRG : baudRateGenerator
	port map (
		clock  		=> clockInput,
		reset 		=> reset,
		divisor 	=> divisorValue,
		baudOut_n => clockDivided
	);

	lsDL: shiftregister
	generic map (
		WIDTH => 8
	)
	port map (
		clock       => clockInput,
		reset       => '0',
		serial_i    => '0',
		loadOrShift => "11",
		data_i      => lsDivisorReg,
		data_o      => lsDivisorRegOutput
		--serial_o_r  => serial_out
		--serial_o_l  => serial_o_l
	);

	msDL: shiftregister
	generic map (
		WIDTH => 8
	)
	port map (
		clock       => clockInput,
		reset       => '0',
		serial_i    => '0',
		loadOrShift => "11",
		data_i      => msDivisorReg,
		data_o      => msDivisorRegOutput
		--serial_o_r  => serial_out
		--serial_o_l  => serial_o_l
	);

	divisorValue <= msDivisorRegOutput & lsDivisorRegOutput;

end architecture;
