library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity waifusAreTheBestForTransmitter is
	port (
		clock, reset	: in std_logic;
		thrSend       : in std_logic;
		lcrConfig     : in std_logic_vector( 6 downto 0 );
		thrData       : in std_logic_vector( 7 downto 0 );
		serialOut			: out std_logic;
		lsrStatus     : out std_logic_vector( 1 downto 0 )
	);
end entity;

architecture rtl of waifusAreTheBestForTransmitter is

	component transmitterTimingControl is
		port (
			clock, reset : in std_logic;
			thrSend      : in std_logic;
			txConfig     : in std_logic_vector( 6 downto 0 );
			tsrControl   : out std_logic_vector( 2 downto 0 );
			lsrControl   : out std_logic_vector(1 downto 0)
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

	signal serial: std_logic;
	signal reg_control: std_logic_vector(1 downto 0);

	signal ttcTSRControl : std_logic_vector( 2 downto 0 ) := (others => '0');

begin

	TTC: transmitterTimingControl
	port map (
		clock      => clock,
		reset      => reset,
		thrSend    => '1',
		txConfig   => lcrConfig,
		tsrControl => ttcTSRControl,
		lsrControl => lsrStatus
	);

	TSR : waifusAreTheBestForShiftTransmitter
	port map (
		clockInput      => clock,
		reset           => reset,
		tsrDataInput    => thrData,
		tsrControl      => ttcTSRControl
		--tsrOutput       => readyLed
	);

	serialOut <= serial;

end architecture;
