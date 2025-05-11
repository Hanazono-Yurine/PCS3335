library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitterTimingControl is
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

		-- LSR
		LSR_bit5THRE, LSR_bit6TEMT : out std_logic := '1';

		--debug
        leds: out std_logic_vector(9 downto 0)
	);
end entity;

architecture rtl of transmitterTimingControl is

	-- ============================================= SIGNAL =============================================

	signal numberBitsToTransmit: std_logic_vector(3 downto 0) := "0000";

	signal numberOfClocksForStopBit: std_logic_vector(4 downto 0) := "00000";

	signal TransmittedAllBits, TransmittedAllStopBits : std_logic := '0';

	signal valueClockCounterIs14 : std_logic := '0';


	-- ============================================= FSM STATES =============================================
    type state_type is (Sreset, Sload, S_idle, SnextBit, SstopBit, Sready);
    signal state, next_state: state_type := Sready;

begin

    
	


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

	-- ============================================= LOGIC NEXT STATE =============================================
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



	-- Sreset, Sload, S_idle, SnextBit, SstopBit, Sready
	leds(0) <= '1' when state = Sready else '0';
	leds(1) <= '1' when state = Sload else '0';
	leds(2) <= '1' when state = S_idle else '0';
	leds(3) <= '1' when state = SnextBit else '0';
	leds(4) <= '1' when state = SstopBit else '0';
	leds(5) <= '1' when state = Sreset else '0';


	-- ============================================= LOGIC COUNTERS CONTROL =============================================
	
	-- logica de controle do contador transmitted_Bit_Counter : counter of transmitted Bit (bits data + bit parity)

	resetTransmBitCounter <= '1' when state = Sload else '0'; -- MUDEI ISSO	

	enTransmBitCounter <= '0' when valueTransmBitCounter = numberBitsToTransmit else '1'; 

	transmittedABit <= '1' when state = SnextBit else '0';

	TransmittedAllBits <= '1' when valueTransmBitCounter = numberBitsToTransmit else '0'; 

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
	
	-- LSR bit 5 THRE: 1 => to carregando o valor do THR pro TSR
	LSR_bit5THRE <= '0' when state = Sload else '1'; 

	--LSR bit 6 TEMT: 1 => nao estou transmitindo
	LSR_bit6TEMT <= '1' when state = Sready else '0'; 

	

	-- logica de controle do contador clock_Counter: counter of clock cycles

	valueClockCounterIs14 <= '1' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enClockCounter <= '0' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '1'; -- trava o contador em 14 

	resetClockCounter <= '0' when state = S_idle else '1';




	-- logica de controle do contador stop_Bit_Counter: counter number of clocks for the stop bit

	TransmittedAllStopBits <= '1' when valueStopBitCounter = numberOfClocksForStopBit else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enStopBitCounter <= '0' when valueStopBitCounter = numberOfClocksForStopBit else '1'; -- trava o contador em 14 

	resetStopBitCounter <= '0' when state = SstopBit else '1';

	numberOfClocksForStopBit <= 
	std_logic_vector(to_unsigned(15,5)) when LCR_out(2) = '0' else -- 1 bit stop
	std_logic_vector(to_unsigned(23,5)) when LCR_out(2) & LCR_out(1 downto 0)  = "100" else -- 1,5 bits stop 
	std_logic_vector(to_unsigned(31,5)); -- 2 bits stop


end architecture;