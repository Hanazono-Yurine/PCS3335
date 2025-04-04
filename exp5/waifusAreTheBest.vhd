library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBest is
	port (
		clock 			: in std_logic;
		reset 			: in std_logic;
		serial_out 	: out std_logic;
		--desafio
		go : in std_logic := '0';
		readyLed : out std_logic
	);
end entity;

architecture insides of waifusAreTheBest is

	component transmitterTimingControl is
		port (
			clock153600, reset: in std_logic;
			reg_loadOrShift: out std_logic_vector( 1 downto 0 );
			go : in std_logic := '0';
			readyLed : out std_logic
		);
	end component;

	component transmitterHoldingRegister is
		generic (
			WIDTH : natural := 8
		);
		port (
			clock 	: in std_logic;
			data_i 	: in std_logic_vector( WIDTH-1 downto 0 )
			data_o 	: out std_logic_vector( WIDTH-1 downto 0 )
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

	component baudRateGenerator is
		port(
			clock     : in  std_logic;
			reset     : in  std_logic;
			divisor		: in  std_logic_vector(15 downto 0);
			baudOut_n : out std_logic
		);
	end component;

	component ip_pll_50MHz is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component;

	signal clock_pll : std_logic := '0';
	signal clock_brg : std_logic := '0';
	signal sig_readyLed : std_logic := '0';

	--signal serial_out: std_logic;
	signal ttcRegControl: std_logic_vector(1 downto 0);
	signal thgRegOutput : std_logic_vector( 7 downto 0 );
begin

	baka: ip_pll_50MHz
	port map (
		refclk   => clock,
		rst      => '0',
		outclk_0 => clock_pll
	);

	BRG : baudRateGenerator
	port map (
		clock  		=> clock_pll,
		reset 		=> reset,
		divisor 	=> std_logic_vector(to_unsigned(12,16)),
		baudOut_n => clock_brg
	);

	readyLed <= sig_readyLed;

	TTC: transmitterTimingControl
	port map (
		clock153600     => clock_brg,
		reset           => reset,
		reg_loadOrShift => ttcRegControl,
		go              => go,
		readyLed        => sig_readyLed
	);

	THR : transmitterHoldingRegister
	port map (
		clock 	=> clock_brg,
		data_i 	=> ,
		data_o	=> thgRegOutput
	);

	TSR: shiftregister
	generic map (
		WIDTH => 11
	)
	port map (
		clock       => clock_brg,
		reset       => reset,
		serial_i    => '1',
		loadOrShift => ttcRegControl,
		data_i      => thgRegOutput,
		--data_o      => data_o,
		serial_o_r  => serial_out
		--serial_o_l  => serial_o_l
	);

	serialOut <= serial_out;

end architecture;
