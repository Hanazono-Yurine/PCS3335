library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart5Debug is
	port (
		clock50M, reset: in std_logic := '0';
		-- load: in std_logic := '0';
		-- THR_data : in std_logic_vector(7 downto 0);
		serialOut: out std_logic;

		--debug
		clock1_8MHzDebug, clockDebug: out std_logic;
        switches: in std_logic_vector(9 downto 0);
        leds: out std_logic_vector(9 downto 0)
	);
end entity;

architecture rtl of uart5Debug is

	-- ========================================= COMPONENTS ================================	
	component ip_pll_50MHz is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         --  locked.export
        );
    end component;

	component baudRateGenerator is
		port(
			clock       : in  std_logic;
			reset       : in  std_logic;
			divisor       : in  std_logic_vector(15 downto 0);
			baudOut_n : out std_logic
		);
	end component baudRateGenerator;

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

	-- ============================================= SIGNAL =============================================

	--lacth divisor
	signal LD_MS_out: std_logic_vector(7 downto 0);
	signal LD_LS_out: std_logic_vector(7 downto 0);
	constant CLOCK_DIVISOR_VALUE : integer := 12;
	signal clockDivisorValue: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(CLOCK_DIVISOR_VALUE,16));

	-- clocks
	signal clock1_8MHz, clock: std_logic := '1';

	-- Registers parallel input and output
	signal THR_out, LCR_in, LCR_out, LSR_in, LSR_out: std_logic_vector(7 downto 0);
	signal TSR_in, TSR_out: std_logic_vector(8 downto 0) := (others => '1');
	-- Registers load or shit
	signal THR_load, TSR_L_or_S: std_logic_vector(1 downto 0) := "00";
	-- Registers serial input and output
	signal TSR_serialOut: std_logic := '1';

	-- counters values
	signal valueTransmBitCounter, valueClockCounter : std_logic_vector(3 downto 0) := "0000";
	-- counters reset
	signal resetTransmBitCounter, resetClockCounter, resetStopBitCounter: std_logic := '0';
	-- counters enable
	signal enTransmBitCounter, enClockCounter, enStopBitCounter : std_logic := '0';

	signal numberBitsToTransmit: std_logic_vector(3 downto 0) := "0000";

	signal numberOfClocksForStopBit, valueStopBitCounter: std_logic_vector(4 downto 0) := "00000";

	signal TransmittedAllBits, transmittedABit, TransmittedAllStopBits : std_logic := '0';

	signal valueClockCounterIs14 : std_logic := '0';

	-- parity
	signal parityBit, parityBitEven: std_logic := '1';

    --DEBUG
    signal THR_data: std_logic_vector(7 downto 0);
	signal load: std_logic := '0';



	-- ============================================= FSM STATES =============================================
    type state_type is (Sreset, Sload, S_idle, SnextBit, SstopBit, Sready);
    signal state, next_state: state_type := Sload;

begin

	-- ============================================= INSTANCES =============================================
	--ip_pll
    ip_pll: ip_pll_50MHz
    port map (
        refclk   => clock50M,
        rst      => '0',
        outclk_0 => clock1_8MHz
    );

	-- ************************************* REGISTERS
	latchDivisor_MS: shiftregister
	generic map (
	  WIDTH => 8
	)
	port map (
	  clock       => clock1_8MHz,
	  reset       => reset,
	  serial_i    => '0',
	  loadOrShift => "11",
	  data_i      => clockDivisorValue(15 downto 8),
	  data_o      => LD_MS_out
	  --serial_o_r  => serial_o_r,
	  --serial_o_l  => serial_o_l
	);

	latchDivisor_LS: shiftregister
	generic map (
	  WIDTH => 8
	)
	port map (
	  clock       => clock1_8MHz,
	  reset       => reset,
	  serial_i    => '0',
	  loadOrShift => "11",
	  data_i      => clockDivisorValue(7 downto 0),
	  data_o      => LD_LS_out
	  --serial_o_r  => serial_o_r,
	  --serial_o_l  => serial_o_l
	);

	baudrategenerator_inst: baudRateGenerator
	port map (
	  clock     => clock1_8MHz,
	  reset     => '0',
	  --divisor   => std_logic_vector(to_unsigned(12,16)),
	  divisor   => LD_MS_out & LD_LS_out,
	  baudOut_n => clock
	);

	THR: shiftregister --Transmitter Holding Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => reset,
      serial_i    => '0',
      loadOrShift => THR_load,
      data_i      => THR_data,
      data_o      => THR_out
      --serial_o_r  => sig_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	THR_load <= "11" when load = '1' else "00";

	TSR: shiftregister --Transmitter Shift Register
    generic map (
      WIDTH => 9
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

	LCR: shiftregister -- Line Control Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => '1',
      loadOrShift => "11",
      data_i      => "0" & "0" & "011" & "0" & "11", -- Divisor Latch Access & Break & Parity & BitStop & Character Length
      data_o      => LCR_out
      --serial_o_r  => sig_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	LSR: shiftregister -- Line Status Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => '1',
      loadOrShift => "11",
      data_i      => "00000000",
      data_o      => LSR_out
      --serial_o_r  => 
      --serial_o_l  => sig_reg_serial_o_l
    );

	-- ************************************* COUNTERS

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

	resetTransmBitCounter <= '0' when state = SnextBit or state = S_idle else '1';

	enTransmBitCounter <= '0' when valueTransmBitCounter = numberBitsToTransmit else '1'; 

	transmittedABit <= '1' when state = SnextBit else '0';

	TransmittedAllBits <= '1' when valueTransmBitCounter = numberBitsToTransmit else '0'; 

	numberBitsToTransmit <= 
		std_logic_vector(to_unsigned(5+0,4)) when LCR_out(3) & LCR_out(1 downto 0) = "000" else
		std_logic_vector(to_unsigned(6+0,4)) when LCR_out(3) & LCR_out(1 downto 0) = "001" else
		std_logic_vector(to_unsigned(7+0,4)) when LCR_out(3) & LCR_out(1 downto 0) = "010" else
		std_logic_vector(to_unsigned(8+0,4)) when LCR_out(3) & LCR_out(1 downto 0) = "011" else
		std_logic_vector(to_unsigned(5+1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "100" else
		std_logic_vector(to_unsigned(6+1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "101" else
		std_logic_vector(to_unsigned(7+1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "110" else
		std_logic_vector(to_unsigned(8+1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "111";
	 

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

	resetClockCounter <= '0' when state = S_idle else '1';

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

	TransmittedAllStopBits <= '1' when valueStopBitCounter = numberOfClocksForStopBit else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enStopBitCounter <= '0' when valueStopBitCounter = numberOfClocksForStopBit else '1'; -- trava o contador em 14 

	resetStopBitCounter <= '0' when state = SstopBit else '1';

	numberOfClocksForStopBit <= 
		std_logic_vector(to_unsigned(15,5)) when LCR_out(2) = '0' else -- 1 bit stop
		std_logic_vector(to_unsigned(23,5)) when LCR_out(2) & LCR_out(1 downto 0)  = "100" else -- 1,5 bits stop 
		std_logic_vector(to_unsigned(31,5)); -- 2 bits stop

	
	-- ============================================= FSM PROCESS =============================================
	-- process padrao de proximo estado da fsm
	fsm: process(clock, reset)
	begin
		if reset = '1' then
			state <= Sreset;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process;

	-- ============================================= LOGIC =============================================
	-- logica proximo estado
	next_state <=
		Sready   when (state = Sreset)                  else
		Sready   when (state = Sready   and load = '0') else
		Sload    when (state = Sready   and load = '1') else
		S_idle   when (state = Sload)                   else
		S_idle   when (state = S_idle   and valueClockCounterIs14 = '0')                              else
		SnextBit when (state = S_idle   and valueClockCounterIs14 = '1' and TransmittedAllBits = '0') else
		S_idle   when (state = SnextBit)                                                              else  
		SstopBit when (state = S_idle   and valueClockCounterIs14 = '1' and TransmittedAllBits = '1') else
		SstopBit when (state = SstopBit and TransmittedAllStopBits = '0')                             else
		Sready   when (state = SstopBit and TransmittedAllStopBits = '1')                             else
		state;

	TSR_L_or_S <= "11" when state = Sload else 
				"00" when state = S_idle else
				"01" when state = SnextBit or state = SstopBit else
				"00";

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
		"111" & parityBit & THR_out(4 downto 0) when LCR_out(1 downto 0) = "00" else 
		"11"  & parityBit & THR_out(5 downto 0) when LCR_out(1 downto 0) = "01" else
		"1"   & parityBit & THR_out(6 downto 0) when LCR_out(1 downto 0) = "10" else
		        parityBit & THR_out(7 downto 0) when LCR_out(1 downto 0) = "11";

	serialOut <= TSR_serialOut when LCR_out(6) = '0' else '1';


	------------------------------------------ DEBUG

	THR_data <= switches(7 downto 0);
	load <= switches(9);


end architecture;