library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiverTimingControl is
	port (
		clock, reset: in std_logic := '0';
        receivedStartBit: in std_logic := '0';
        receivedAllBits, receivedAllStopBits, valueClockCounterIs14 : in std_logic := '0';

        RSR_L_or_S : out std_logic_vector(1 downto 0) := "00";
        stateIs_idle, stateIs_nextBit, stateIs_stopBit, stateIs_start : out std_logic := '0';
		leds: out std_logic_vector(9 downto 0)
	);
end entity;

architecture rtl of receiverTimingControl is

	
	-- ============================================= SIGNAL =============================================


    signal sig_RSR_L_or_S: std_logic_vector(1 downto 0) := "00";

	-- ============================================= FSM STATES =============================================
    type state_type is (Sreset, Sstart, S_idle, SnextBit, SstopBit, Sready);
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
		Sstart    when (state = Sready   and receivedStartBit = '1') else
		S_idle   when (state = Sstart)                   else
		S_idle   when (state = S_idle   and valueClockCounterIs14 = '0')                              else
		SnextBit when (state = S_idle   and valueClockCounterIs14 = '1' and receivedAllBits = '0') else
		S_idle   when (state = SnextBit)                                                              else  
		SstopBit when (state = S_idle   and valueClockCounterIs14 = '1' and receivedAllBits = '1') else
		SstopBit when (state = SstopBit and receivedAllStopBits = '0')                             else
		Sready   when (state = SstopBit and receivedAllStopBits = '1')                             else
		state;

	RSR_L_or_S <= "00" when state = S_idle else
                "01" when state = SnextBit else
                "00";

    --RSR_L_or_S <= sig_RSR_L_or_S;

    stateIs_idle <= '1' when state = S_idle else '0';

    stateIs_nextBit <= '1' when state = SnextBit else '0';
    
	stateIs_stopBit <= '1' when state = SstopBit else '0';

	stateIs_start <= '1' when state = Sstart else '0';

	leds(0) <= '1' when state = Sready else '0';
	leds(1) <= '1' when state = Sstart else '0';
	leds(2) <= '1' when state = S_idle else '0';
	leds(3) <= '1' when state = SnextBit else '0';
	leds(4) <= '1' when state = SstopBit else '0';
	leds(5) <= '1' when state = Sreset else '0';
	leds(6) <= '1' when receivedStartBit = '1' else '0';

end architecture;