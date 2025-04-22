library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver is
	port (
		clock, reset: in std_logic := '0';
        LCR_out: in std_logic_vector(7 downto 0); 
        serialIn: in std_logic;

        --display7seg : out std_logic_vector(6 downto 0)
		RSR_data : out std_logic_vector(9 downto 0); -- valor completo armazenado no RSR
		RSR_data8Bits : out std_logic_vector(7 downto 0); -- apenas os bit data recebidos com 0 nos mais sig
		LSR_bit2PE : out std_logic := '0';
		leds: out std_logic_vector(9 downto 0)
	);
end entity;

architecture rtl of receiver is

	-- ========================================= COMPONENTS ================================	

	component counter is
		generic (
				WIDTH : natural := 8 -- Size in bits
		);
		port (
				clock, reset, enable, load, up : in std_logic;
				data_i : in std_logic_vector( WIDTH-1 downto 0 );
				data_o : out std_logic_vector( WIDTH-1 downto 0 )
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

    component receiverTimingControl is
		port (
			clock, reset: in std_logic := '0';
			receivedStartBit: in std_logic := '0';
			LCR_out: in std_logic_vector(7 downto 0); 
	
			valueReceiverBitCounter : in std_logic_vector(3 downto 0); -- valor do contador de bits recebidos
			valueClockCounter : in std_logic_vector(3 downto 0);  -- valor do contador de clock de cada Data Bit (quantos clocks o S_idle fica nele mesmo)
			valueStopBitCounter : in std_logic_vector(4 downto 0); -- valor do contador de clock de cada Stop Bit (quantos clocks o SstopBit fica nele mesmo)
	
			-- controle do receiver_Bit_Counter
			receivedABit, resetReceiverBitCounter, enReceiverBitCounter : out std_logic := '0';
			-- controle clock_Counter
			resetClockCounter, enClockCounter : out std_logic := '0';
			-- controle stop_Bit_Counter
			resetStopBitCounter, enStopBitCounter : out std_logic := '0';
	
			RSR_L_or_S : out std_logic_vector(1 downto 0) := "00";
			leds: out std_logic_vector(9 downto 0)
		);
	end component;
	-- ============================================= SIGNAL =============================================

    signal RSR_out : std_logic_vector(9 downto 0) := (others => '1');

    signal RSR_L_or_S: std_logic_vector(1 downto 0) := "00";

    signal receivedStartBit, receivedParityBit : std_logic := '0';

	-- counters values
	signal valueReceiverBitCounter, valueClockCounter : std_logic_vector(3 downto 0) := "0000";
	-- counters reset
	signal resetReceiverBitCounter, resetClockCounter, resetStopBitCounter: std_logic := '0';
	-- counters enable
	signal enReceiverBitCounter, enClockCounter, enStopBitCounter : std_logic := '0';

	signal valueStopBitCounter: std_logic_vector(4 downto 0) := "00000";

	signal receivedABit : std_logic := '0';

	-- parity
	signal parityBit, parityBitEven: std_logic := '1';

	--debug

	--signal sig_leds: std_logic_vector(9 downto 0);

begin

	-- ============================================= INSTANCES =============================================

	-- ************************************* REGISTERS

    RSR: shiftregister --Receiver Shift Register
    generic map (
      WIDTH => 10
    )
    port map (
      clock       => clock,
      reset       => reset,
      serial_i    => serialIn,
      loadOrShift => RSR_L_or_S,
      data_i      => (others => '0'),
      data_o      => RSR_out,
      serial_o_r  => open,
      serial_o_l  => open
    );

	-- ************************************* COUNTERS

	receiver_Bit_Counter: counter -- counter of received Bit (bits data + 0 or 1 bit paraty)
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => receivedABit,
        reset  => resetReceiverBitCounter,
        enable => enReceiverBitCounter,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => valueReceiverBitCounter
    );



	clock_Counter: counter -- counter of clock cycles
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => clock,
        reset  => resetClockCounter,
        enable => enClockCounter,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => valueClockCounter
    );



	stop_Bit_Counter: counter -- counter number of clocks for the stop bit
    generic map (
        WIDTH => 5
    )
    port map (
        clock  => clock,
        reset  => resetStopBitCounter,
        enable => enStopBitCounter,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => valueStopBitCounter
    );



	
	-- ============================================= FSM =============================================
    receivertimingcontrol_inst: receiverTimingControl
	port map (
	  clock                   => clock,
	  reset                   => reset,
	  receivedStartBit        => receivedStartBit,
	  LCR_out                 => LCR_out,
	  valueReceiverBitCounter => valueReceiverBitCounter,
	  valueClockCounter       => valueClockCounter,
	  valueStopBitCounter     => valueStopBitCounter,
	  receivedABit            => receivedABit,
	  resetReceiverBitCounter => resetReceiverBitCounter,
	  enReceiverBitCounter    => enReceiverBitCounter,
	  resetClockCounter       => resetClockCounter,
	  enClockCounter          => enClockCounter,
	  resetStopBitCounter     => resetStopBitCounter,
	  enStopBitCounter        => enStopBitCounter,
	  RSR_L_or_S              => RSR_L_or_S,
	  leds                    => leds
	);

	-- ============================================= LOGIC =============================================

    

	parityBitEven <= 
		RSR_out(5) xor RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1) 												 when LCR_out(1 downto 0) = "00" else 
		RSR_out(6) xor RSR_out(5) xor RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1) 								 when LCR_out(1 downto 0) = "01" else
		RSR_out(7) xor RSR_out(6) xor RSR_out(5) xor RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1)                 when LCR_out(1 downto 0) = "10" else
		RSR_out(8) xor RSR_out(7) xor RSR_out(6) xor RSR_out(5) xor RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1)  when LCR_out(1 downto 0) = "11";

	parityBit <= '1' when LCR_out(3) = '0' else
				not parityBitEven when LCR_out(5 downto 3) = "001" else
				parityBitEven     when LCR_out(5 downto 3) = "011" else
				'1'               when LCR_out(5 downto 3) = "101" else
				'0'            	  when LCR_out(5 downto 3) = "111";

	-- RSR : 1 parity bit + 8 a 5 bits data + 1 bit start
	RSR_data8Bits <= 
		"000" & RSR_out(5 downto 1) when LCR_out(1 downto 0) = "00" else  
		"00"  & RSR_out(6 downto 1) when LCR_out(1 downto 0) = "01" else
		"0"   & RSR_out(7 downto 1) when LCR_out(1 downto 0) = "10" else
				RSR_out(8 downto 1) when LCR_out(1 downto 0) = "11";
	
	RSR_data <= RSR_out;

	receivedParityBit <= 
			RSR_out(6) when LCR_out(1 downto 0) = "00" else 
			RSR_out(7) when LCR_out(1 downto 0) = "01" else
			RSR_out(8) when LCR_out(1 downto 0) = "10" else
			RSR_out(9) when LCR_out(1 downto 0) = "11";

	LSR_bit2PE <= '1' when receivedParityBit /= parityBit else '0';

	--leds <= sig_leds;

	receivedStartBit <= '1' when serialIn = '0' else '0'; -- AQUI EH serialIn
						


    
end architecture;