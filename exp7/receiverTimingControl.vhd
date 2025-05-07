library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiverTimingControl is
	port (
		clock, reset: in std_logic := '0';
		receivedStartBit: in std_logic := '0';
		LCR_out: in std_logic_vector(7 downto 0); 

		LSR0_out: out std_logic;
		LSR1_out: out std_logic;
		LSR3_out: out std_logic;

		LSR0_in: out std_logic;
		LSR1_in: out std_logic;
		LSR3_in: out std_logic;

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
		leds: out std_logic_vector(9 downto 0);

		-- === RBR ===
		rbrFoiLido : in std_logic;
		rbrLoad : out std_logic;
		-- ===========

		stateIsStopBit : out std_logic;
		stateIsfinish : out std_logic;
		stateIsErroStopBit : out std_logic;

		serialIn : in std_logic;

		receivedAllStopBits_out : out std_logic

	);
end entity;

architecture rtl of receiverTimingControl is

	
	-- ============================================= SIGNAL =============================================


	signal numberBitsToReceive: std_logic_vector(3 downto 0) := "0000";

	signal receivedAllBits, receivedAllStopBits : std_logic := '0';

	signal valueClockCounterIs14 : std_logic := '0';

	signal numberOfClocksForStopBit: std_logic_vector(4 downto 0) := "00000";

	signal LSR0_out_sig : std_logic := '0';

	-- ============================================= FSM STATES =============================================
    type state_type is (Sreset, Sstart, S_idle, SnextBit, SstopBit, Sfinish, S_erroStopBit, Sready);
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

	-- ============================================= LOGIC =============================================
	-- logica proximo estado
	next_state <=
		Sready   when (state = Sreset)                  else
		Sready   when (state = Sready   and receivedStartBit = '0') else
		Sstart   when (state = Sready   and receivedStartBit = '1') else
		S_idle   when (state = Sstart)                   else
		S_idle   when (state = S_idle   and valueClockCounterIs14 = '0')                              else
		SnextBit when (state = S_idle   and valueClockCounterIs14 = '1' and receivedAllBits = '0') else
		S_idle   when (state = SnextBit)                                                              else  
		SstopBit when (state = S_idle   and valueClockCounterIs14 = '1' and receivedAllBits = '1') else
		SstopBit when (state = SstopBit and receivedAllStopBits = '0' and serialIn = '1' )                             else
		Sfinish  when (state = SstopBit and receivedAllStopBits = '1' and serialIn = '1'  )   else
		S_erroStopBit  when (state = SstopBit and serialIn = '0' ) else
		Sfinish  when (state = S_erroStopBit)   else
		Sready   when (state = Sfinish) else
		state;

	
	-- logica de controle do RSR
	RSR_L_or_S <= "00" when state = S_idle else
                "01" when state = SnextBit else
                "00";

	leds(0) <= '1' when state = Sready else '0';
	leds(1) <= '1' when state = Sstart else '0';
	leds(2) <= '1' when state = S_idle else '0';
	leds(3) <= '1' when state = SnextBit else '0';
	leds(4) <= '1' when state = SstopBit else '0';
	leds(5) <= '1' when state = Sreset else '0';
	leds(6) <= '1' when receivedStartBit = '1' else '0';

	
	-- ============================================= LOGIC COUNTERS CONTROL =============================================
	
	-- logica de controle do contador receiver_Bit_Counter : counter of received Bit (bits data + 0 or 1 bit paraty)

	resetReceiverBitCounter <= '1' when state = Sstart else '0'; --******************************************

	receivedABit <= '1' when state = SnextBit else '0';

	enReceiverBitCounter <= '0' when valueReceiverBitCounter = numberBitsToReceive else '1'; 

	receivedAllBits <= '1' when valueReceiverBitCounter = numberBitsToReceive else '0'; 

	numberBitsToReceive <= 
		std_logic_vector(to_unsigned(1+5+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "000" else
		std_logic_vector(to_unsigned(1+6+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "001" else
		std_logic_vector(to_unsigned(1+7+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "010" else
		std_logic_vector(to_unsigned(1+8+0-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "011" else
		std_logic_vector(to_unsigned(1+5+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "100" else
		std_logic_vector(to_unsigned(1+6+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "101" else
		std_logic_vector(to_unsigned(1+7+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "110" else
		std_logic_vector(to_unsigned(1+8+1-1,4)) when LCR_out(3) & LCR_out(1 downto 0) = "111";
		-- 1 bit start + 5 a 8 bit data + 0 ou 1 parity bit - 1 pq o ele nao vai pro estado NEXT_BIT quando termina de enviar o ultimo bit



	-- logica de controle do contador clock_Counter: counter of clock cycles

	valueClockCounterIs14 <= '1' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enClockCounter <= '0' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '1'; -- trava o contador em 14 

	resetClockCounter <= '0' when state = S_idle else '1';



	-- logica de controle do contador stop_Bit_Counter: counter number of clocks for the stop bit

	receivedAllStopBits <= '1' when valueStopBitCounter = numberOfClocksForStopBit else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enStopBitCounter <= '0' when valueStopBitCounter = numberOfClocksForStopBit or state = Sfinish else '1'; -- trava o contador

	resetStopBitCounter <= '0' when state = SstopBit or state = Sfinish or state = Sready else '1';

	numberOfClocksForStopBit <= 
	std_logic_vector(to_unsigned(15,5)) when LCR_out(2) = '0' else -- 1 bit stop
	std_logic_vector(to_unsigned(23,5)) when LCR_out(2) & LCR_out(1 downto 0)  = "100" else -- 1,5 bits stop 
	std_logic_vector(to_unsigned(31,5)); -- 2 bits stop

	stateIsfinish <= '1' when state = Sfinish else '0';

	------- EXP 7

	-- Faz load do RSR para o RBR quando estiver no Sready
	rbrLoad <= '1' when state = Sfinish else '0';

	stateIsStopBit <= '1' when state = SstopBit else '0';

	stateIsErroStopBit  <= '1' when state = S_erroStopBit else '0';

	--LSR_Bit3 <= '1' when state = Sfinish and receivedAllBits = '0' else elemesmo(3);

		receivedAllStopBits_out <= receivedAllStopBits;

	


end architecture;
