library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBestForTransmitter is
	port (
		clock, reset	: in std_logic;
		serialOut			: out std_logic;
		busLine   : in std_logic_vector( 7 downto 0 );
		busSelect : in std_logic_vector( 3 downto 0 );
		lsrDebugger : out std_logic_vector( 7 downto 0 )
	);
end entity;

architecture rtl of waifusAreTheBestForTransmitter is

	component transmitterTimingControl is
		port (
			clock, reset : in std_logic;
			go           : in std_logic;
			txConfig     : in std_logic_vector( 6 downto 0 );
			tsrControl   : out std_logic_vector( 2 downto 0 );
			readyLed     : out std_logic
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

	component waifusAreTheBestForShiftTransmitter is
		port (
			clockInput      : in std_logic;
			reset           : in std_logic;
			tsrDataInput		: in std_logic_vector( 7 downto 0 );
			tsrControl      : in std_logic_vector(2 downto 0);
			tsrOutput       : out std_logic
		);
	end component;

	component waifusAreTheBestForHoldingRegister is
		generic (
			WIDTH : natural := 8
		);
		port (
			clock 	: in std_logic;
			reset           : in std_logic;
			data_i 	: in std_logic_vector( WIDTH-1 downto 0 );
			data_o 	: out std_logic_vector( WIDTH-1 downto 0 )
		);
	end component;

	signal serial: std_logic;
	signal reg_control: std_logic_vector(1 downto 0);

	signal ttcTSRControl : std_logic_vector( 2 downto 0 ) := (others => '0');

	signal thrOutput : std_logic_vector( 7 downto 0 ) := (others => '0');

	signal lcr_i : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lcr_o : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lsr_i : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lsr_o : std_logic_vector( 7 downto 0 ) := (others => '0');

	signal thrBusLine : std_logic_vector( 7 downto 0 ) := (others => '0');
	signal lcrBusLine : std_logic_vector( 7 downto 0 ) := (others => '0');

begin

	TTC: transmitterTimingControl
	port map (
		clock      => clock,
		reset      => reset,
		txConfig   => lcr_o( 6 downto 0 ),
		tsrControl => ttcTSRControl,
		go         => '1'
		--readyLed   => readyLed
	);

	TSR : waifusAreTheBestForShiftTransmitter
	port map (
		clockInput      => clock,
		reset           => reset,
		tsrDataInput    => thrOutput,
		tsrControl      => ttcTSRControl
		--tsrOutput       => readyLed
	);

	THR : waifusAreTheBestForHoldingRegister
	port map (
		clock   => clock,
		reset   => reset,
		data_i  => thrBusLine,
		data_o  => thrOutput
	);

	LCR : waifusAreTheBestForLineControl
	port map (
		clockInput => clock,
		reset      => reset,
		lcrInput   => lcrBusLine,
		lcrOutput  => lcr_o
	);

	LSR : waifusAreTheBestForLineStatus
	port map (
		clockInput => clock,
		reset      => reset,
		lsrInput   => lsr_i
		--lsrOutput  => lsr_o
	);

	lsrDebugger <= lsr_o;

	serialOut <= serial;

end architecture;
