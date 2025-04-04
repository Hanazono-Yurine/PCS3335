library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitter is
	port (
		clock153600, reset: in std_logic;
		serialOut: out std_logic;
        --desafio
		go : in std_logic := '0';
		readyLed : out std_logic
	);
end entity;

architecture rtl of transmitter is

	component transmitterTimingControl is
		port (
			clock153600, reset: in std_logic;
			reg_loadOrShift: out std_logic_vector( 1 downto 0 );
			go : in std_logic := '0';
			readyLed : out std_logic
		);
	end component;

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

	signal serial: std_logic;
	signal reg_control: std_logic_vector(1 downto 0);

begin

	TTC: transmitterTimingControl
	port map (
		clock153600       => clock153600,
		reset           => reset,
		reg_loadOrShift => reg_control,
		go              => go,
		readyLed        => readyLed
	);

	TSR: shiftregister
	generic map (
		WIDTH => 11
	)
	port map (
		clock       => clock153600,
		reset       => reset,
		serial_i    => '1',
		loadOrShift => reg_control,
		data_i      => "10010000100",
		--data_o      => data_o,
		serial_o_r  => serial
		--serial_o_l  => serial_o_l
	);

	serialOut <= serial;

end architecture;
