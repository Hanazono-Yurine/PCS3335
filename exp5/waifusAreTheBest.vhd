library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBest is
	port (
		clock 			: in std_logic;
		reset 			: in std_logic;
		--desafio
		busLine   : in std_logic_vector( 8 downto 0 );
		busSelect : in std_logic_vector( 3 downto 0 );
		serial_out 	: out std_logic;
		lsrDebugger : out std_logic_vector( 7 downto 0 )
	);
end entity;

architecture insides of waifusAreTheBest is

	component waifusAreTheBestForDivisorLatch is
		port (
			clock 	: in std_logic;
			data_i 	: in std_logic_vector( 7 downto 0 );
			data_o 	: out std_logic_vector( 7 downto 0 )
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

	component waifusAreTheBestForTransmitter is
		port (
			clock, reset	: in std_logic;
			thrSend       : in std_logic;
			lcrConfig     : in std_logic_vector( 6 downto 0 );
			thrData       : in std_logic_vector( 7 downto 0 );
			serialOut			: out std_logic;
			lsrStatus     : out std_logic_vector( 1 downto 0 )
		);
	end component;

	component waifusAreTheBestForHoldingRegister is
		generic (
			WIDTH : natural := 8
		);
		port (
			clock   : in std_logic;
			reset   : in std_logic;
			load    : in std_logic;
			data_i  : in std_logic_vector( WIDTH-1 downto 0 );
			data_o  : out std_logic_vector( WIDTH-1 downto 0 )
		);
	end component;

	component waifusAreTheBestForLineControl is
		port (
			clockInput	: in std_logic;
			reset 			: in std_logic;
			lcrInput		: in std_logic_vector( 7 downto 0 );
			lcrOutput		: out std_logic_vector( 7 downto 0 )
		);
	end component;

	component waifusAreTheBestForLineStatus is
		port (
			clockInput	: in std_logic;
			reset 			: in std_logic;
			lsrInput		: in std_logic_vector( 7 downto 0 );
			lsrOutput		: out std_logic_vector( 7 downto 0 )
		);
	end component;

	-- Saida de dados do UART
	signal serialOutOut : std_logic := '0';

	-- Clocks
	signal clock_pll : std_logic := '0';
	signal clock_brg : std_logic := '0';

	-- Bus Lines
	-- Tem 8 bits, em que o oitavo bit é o load e o resto os dados
	signal lcrBusLine : std_logic_vector( 8 downto 0 ) := (others => '0');
	signal thrBusLine : std_logic_vector( 8 downto 0 ) := (others => '0');

	-- Seleciona qual registrador enviar os dados
	signal busLineSelect : std_logic_vector( 3 downto 0 ) := (others => '0');

	--signal serial_out: std_logic;
	signal ttcRegControl: std_logic_vector(1 downto 0) := (others => '0');
	signal thgRegOutput : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lsrDebugOutput : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lcrDebugOutput : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lcr_i : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lcr_o : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lsr_i : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lsr_o : std_logic_vector( 7 downto 0 ) := (others => '0');

	signal thrOutput : std_logic_vector( 7 downto 0 ) := (others => '0');

	signal divisorLeastBits : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal divisorMostBits : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal divisorBits : std_logic_vector( 15 downto 0 ) := (others => '0');

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
		divisor 	=> divisorBits,
		baudOut_n => clock_brg
	);

	DL_L : waifusAreTheBestForDivisorLatch
	port map (
		clock     => clock_brg,
		data_i    => std_logic_vector(to_unsigned(12,8)),
		data_o     => divisorLeastBits
	);

	DL_M : waifusAreTheBestForDivisorLatch
	port map (
		clock     => clock_brg,
		data_i    => std_logic_vector(to_unsigned(0,8)),
		data_o     => divisorMostBits
	);

	divisorBits <= divisorMostBits & divisorLeastBits;

	transmitter : waifusAreTheBestForTransmitter
	port map (
		clock       => clock_brg,
		reset       => reset,
		thrSend     => thrBusLine(8),
		lcrConfig   => lcr_o( 6 downto 0),
		thrData     => thrOutput,
		serialOut   => serialOutOut,
		lsrStatus   => lsrDebugger(6 downto 5)
	);

	LCR : waifusAreTheBestForLineControl
	port map (
		clockInput => clock_brg,
		reset      => reset,
		lcrInput   => lcrBusLine( 7 downto 0),
		lcrOutput  => lcr_o
	);

	LSR : waifusAreTheBestForLineStatus
	port map (
		clockInput => clock_brg,
		reset      => reset,
		lsrInput   => lsr_i,
		lsrOutput  => lsrDebugger
	);

	THR : waifusAreTheBestForHoldingRegister
	port map (
		clock   => clock_brg,
		reset   => reset,
		load    => thrBusLine( 8 ),
		data_i  => thrBusLine( 7 downto 0 ),
		data_o  => thrOutput
	);

	thrBusLine <= busLine when busSelect(0) = '1' else (others => '0');
	lcrBusLine <= busLine when busSelect(1) = '1' else (others => '0');

	serial_out <= serialOutOut;

end architecture;
