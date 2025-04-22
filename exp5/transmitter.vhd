library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitter is
	port (
		clock, reset: in std_logic := '0';
        -- load : load no THR e comeca a transmissao
        load : in std_logic := '0';
        LCR_out : in std_logic_vector(7 downto 0); 
        THR_in : in std_logic_vector(7 downto 0);

        serialOut: out std_logic;
		--debug
	    scope: out std_logic;
        leds: out std_logic_vector(9 downto 0)
	);
end entity;

architecture rtl of transmitter is

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

    component transmitterTimingControl is
        port (
            clock, reset : in std_logic := '0';
            LCR_out: in std_logic_vector(7 downto 0); 
    
            load : in std_logic := '0';
    
            valueTransmBitCounter : in std_logic_vector(3 downto 0); -- valor do contador de bits transmitidos
            valueClockCounter : in std_logic_vector(3 downto 0);  -- valor do contador de clock de cada Data Bit (quantos clocks o S_idle fica nele mesmo)
            valueStopBitCounter : in std_logic_vector(4 downto 0); -- valor do contador de clock de cada Stop Bit (quantos clocks o SstopBit fica nele mesmo)
    
            -- controle do transmitted_Bit_Counter
            transmittedABit, resetTransmBitCounter, enTransmBitCounter : out std_logic := '0';
            -- controle clock_Counter
            resetClockCounter, enClockCounter : out std_logic := '0';
            -- controle stop_Bit_Counter
            resetStopBitCounter, enStopBitCounter : out std_logic := '0';
    
            -- controle do TSR
            TSR_L_or_S : out std_logic_vector(1 downto 0); 
    
            --debug
            leds: out std_logic_vector(9 downto 0)
        );
    end component;

	-- ============================================= SIGNAL =============================================

	-- Registers parallel input and output
	signal THR_out: std_logic_vector(7 downto 0); 
	signal TSR_in, TSR_out: std_logic_vector(9 downto 0) := (others => '1');
	-- Registers load or shit
	signal THR_load, TSR_L_or_S: std_logic_vector(1 downto 0) := "00";
	-- Registers serial input and output
	signal TSR_serialOut: std_logic := '1';

    -- sinais de controle dos contadore que vem da FSM
	-- counters values
	signal valueTransmBitCounter, valueClockCounter : std_logic_vector(3 downto 0) := "0000";
	-- counters reset
	signal resetTransmBitCounter, resetClockCounter, resetStopBitCounter: std_logic := '0';
	-- counters enable
	signal enTransmBitCounter, enClockCounter, enStopBitCounter : std_logic := '0';

	signal valueStopBitCounter: std_logic_vector(4 downto 0) := "00000";

	signal  transmittedABit : std_logic := '0';

	-- parity
	signal parityBit, parityBitEven: std_logic := '1';

    --DEBUG
    --signal THR_data: std_logic_vector(7 downto 0);
    signal sig_leds: std_logic_vector(9 downto 0);

begin

	THR: shiftregister --Transmitter Holding Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => reset,
      serial_i    => '0',
      loadOrShift => THR_load,
      data_i      => THR_in,
      data_o      => THR_out
      --serial_o_r  => sig_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	TSR: shiftregister --Transmitter Shift Register
    generic map (
      WIDTH => 10
    )
    port map (
      clock       => clock,
      reset       => reset,
      serial_i    => '1',
      loadOrShift => TSR_L_or_S,
      data_i      => TSR_in,
      data_o      => TSR_out,
      serial_o_r  => TSR_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	-- ************************************* COUNTERS *************************************

	transmitted_Bit_Counter: counter -- counter of transmitted Bit (bits data + 0 or 1 bit paraty)
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => transmittedABit,
        reset  => resetTransmBitCounter,
        enable => enTransmBitCounter,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => valueTransmBitCounter
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

    -- ************************************* FSM *************************************

    TCC: transmitterTimingControl
    port map (
      clock                 => clock,
      reset                 => reset,
      LCR_out               => LCR_out,
      load                  => load,
      valueTransmBitCounter => valueTransmBitCounter,
      valueClockCounter     => valueClockCounter,
      valueStopBitCounter   => valueStopBitCounter,
      transmittedABit       => transmittedABit,
      resetTransmBitCounter => resetTransmBitCounter,
      enTransmBitCounter    => enTransmBitCounter,
      resetClockCounter     => resetClockCounter,
      enClockCounter        => enClockCounter,
      resetStopBitCounter   => resetStopBitCounter,
      enStopBitCounter      => enStopBitCounter,
      TSR_L_or_S            => TSR_L_or_S,
      leds                  => sig_leds
    );

    -- ============================================= LOGIC =============================================

	parityBitEven <= 
		THR_out(4) xor THR_out(3) xor THR_out(2) xor THR_out(1) xor THR_out(0) 												 when LCR_out(1 downto 0) = "00" else 
		THR_out(5) xor THR_out(4) xor THR_out(3) xor THR_out(2) xor THR_out(1) xor THR_out(0) 								 when LCR_out(1 downto 0) = "01" else
		THR_out(6) xor THR_out(5) xor THR_out(4) xor THR_out(3) xor THR_out(2) xor THR_out(1) xor THR_out(0)                 when LCR_out(1 downto 0) = "10" else
		THR_out(7) xor THR_out(6) xor THR_out(5) xor THR_out(4) xor THR_out(3) xor THR_out(2) xor THR_out(1) xor THR_out(0)  when LCR_out(1 downto 0) = "11";

	parityBit <= '1' when LCR_out(3) = '0' else
				not parityBitEven when LCR_out(5 downto 3) = "001" else
				parityBitEven     when LCR_out(5 downto 3) = "011" else
				'1'               when LCR_out(5 downto 3) = "101" else
				'0'            	  when LCR_out(5 downto 3) = "111";

	TSR_in <= 
		"111" & parityBit & THR_out(4 downto 0) & '0' when LCR_out(1 downto 0) = "00" else 
		"11"  & parityBit & THR_out(5 downto 0) & '0' when LCR_out(1 downto 0) = "01" else
		"1"   & parityBit & THR_out(6 downto 0) & '0' when LCR_out(1 downto 0) = "10" else
		        parityBit & THR_out(7 downto 0) & '0' when LCR_out(1 downto 0) = "11";

	serialOut <= TSR_serialOut when LCR_out(6) = '0' else '0'; --mudei aqui******************************


	THR_load <= "11" when load = '1' else "00";

	------------------------------------------ DEBUG

	scope <= TSR_serialOut;

    leds <= sig_leds;


end architecture;