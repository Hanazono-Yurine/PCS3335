library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver is
	port (
		clock, reset: in std_logic := '0';
        LCR_out, LSR_out: in std_logic_vector(7 downto 0); 
        serialIn: in std_logic;

        --display7seg : out std_logic_vector(6 downto 0)
		RSR_data: out std_logic_vector(9 downto 0);
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
            receivedAllBits, receivedAllStopBits, valueClockCounterIs14 : in std_logic := '0';
    
            RSR_L_or_S : out std_logic_vector(1 downto 0) := "00";
            stateIs_idle, stateIs_nextBit, stateIs_stopBit, stateIs_start : out std_logic := '0';
			leds: out std_logic_vector(9 downto 0)
        );
    end component;

	-- ============================================= SIGNAL =============================================

    signal RSR_out : std_logic_vector(9 downto 0) := (others => '1');

    signal RSR_L_or_S: std_logic_vector(1 downto 0) := "00";

    signal receivedStartBit, stateIs_idle, stateIs_nextBit, stateIs_stopBit, stateIs_start : std_logic := '0';

	-- counters values
	signal valueReceiverBitCounter, valueClockCounter : std_logic_vector(3 downto 0) := "0000";
	-- counters reset
	signal resetReceiverBitCounter, resetClockCounter, resetStopBitCounter: std_logic := '0';
	-- counters enable
	signal enReceiverBitCounter, enClockCounter, enStopBitCounter : std_logic := '0';

	signal numberBitsToTransmit: std_logic_vector(3 downto 0) := "0000";

	signal numberOfClocksForStopBit, valueStopBitCounter: std_logic_vector(4 downto 0) := "00000";

	signal receivedAllBits, receivedABit, receivedAllStopBits : std_logic := '0';

	signal valueClockCounterIs14 : std_logic := '0';

	-- parity
	signal parityBit, parityBitEven: std_logic := '1';

	--debug

	signal sig_leds: std_logic_vector(9 downto 0);

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
      data_o      => RSR_out
      --serial_o_r  => TSR_serialOut
      --serial_o_l  => sig_reg_serial_o_l
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

	resetReceiverBitCounter <= '1' when stateIs_start = '1' else '0'; --******************************************

	enReceiverBitCounter <= '0' when valueReceiverBitCounter = numberBitsToTransmit else '1'; 

	receivedABit <= '1' when stateIs_nextBit = '1' else '0';

	receivedAllBits <= '1' when valueReceiverBitCounter = numberBitsToTransmit else '0'; 

	numberBitsToTransmit <= 
		std_logic_vector(to_unsigned(1+5+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "000" else
		std_logic_vector(to_unsigned(1+6+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "001" else
		std_logic_vector(to_unsigned(1+7+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "010" else
		std_logic_vector(to_unsigned(1+8+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "011" else
		std_logic_vector(to_unsigned(1+5+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "100" else
		std_logic_vector(to_unsigned(1+6+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "101" else
		std_logic_vector(to_unsigned(1+7+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "110" else
		std_logic_vector(to_unsigned(1+8+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "111";
	    -- 1 bit start + 5 a 8 bit data + 0 ou 1 parity bit - 1 pq o ele nao vai pro estado NEXT_BIT quando termina de enviar o ultimo bit

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

	valueClockCounterIs14 <= '1' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enClockCounter <= '0' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '1'; -- trava o contador em 14 

	resetClockCounter <= '0' when stateIs_idle = '1' else '1';

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

	receivedAllStopBits <= '1' when valueStopBitCounter = numberOfClocksForStopBit else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enStopBitCounter <= '0' when valueStopBitCounter = numberOfClocksForStopBit else '1'; -- trava o contador em 14 

	resetStopBitCounter <= '0' when stateIs_stopBit = '1' else '1';

	numberOfClocksForStopBit <= 
		std_logic_vector(to_unsigned(15,5)) when LCR_out(2) = '0' else -- 1 bit stop
		std_logic_vector(to_unsigned(23,5)) when LCR_out(2) & LCR_out(1 downto 0)  = "100" else -- 1,5 bits stop 
		std_logic_vector(to_unsigned(31,5)); -- 2 bits stop

	
	-- ============================================= FSM =============================================
    RTC: receiverTimingControl
    port map (
      clock                 => clock,
      reset                 => reset,
      receivedStartBit      => receivedStartBit,
      receivedAllBits       => receivedAllBits,
      receivedAllStopBits   => receivedAllStopBits,
      valueClockCounterIs14 => valueClockCounterIs14,
      RSR_L_or_S            => RSR_L_or_S,
      stateIs_idle          => stateIs_idle,
      stateIs_nextBit       => stateIs_nextBit,
      stateIs_stopBit       => stateIs_stopBit,
	  stateIs_start         => stateIs_start,
	  leds => sig_leds
    );

	-- ============================================= LOGIC =============================================

    

	parityBitEven <= 
		RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1) xor RSR_out(0) 												 when LCR_out(1 downto 0) = "00" else 
		RSR_out(5) xor RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1) xor RSR_out(0) 								 when LCR_out(1 downto 0) = "01" else
		RSR_out(6) xor RSR_out(5) xor RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1) xor RSR_out(0)                 when LCR_out(1 downto 0) = "10" else
		RSR_out(7) xor RSR_out(6) xor RSR_out(5) xor RSR_out(4) xor RSR_out(3) xor RSR_out(2) xor RSR_out(1) xor RSR_out(0)  when LCR_out(1 downto 0) = "11";

	parityBit <= '1' when LCR_out(3) = '0' else
				not parityBitEven when LCR_out(5 downto 3) = "001" else
				parityBitEven     when LCR_out(5 downto 3) = "011" else
				'1'               when LCR_out(5 downto 3) = "101" else
				'0'            	  when LCR_out(5 downto 3) = "111";


	RSR_data <= RSR_out;

	leds <= sig_leds;

	receivedStartBit <= '1' when serialIn = '0' else '0'; -- AQUI EH serialIn
						


    
end architecture;