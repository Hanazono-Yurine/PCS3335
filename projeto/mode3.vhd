library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- mode 3 : permite vizualizar os valores armazenados na pilha

entity mode3 is
	port (
		clock, reset : in std_logic := '0';

		ascii : in std_logic_vector(6 downto 0); -- ASCII da tecla presionda

		ledsmode3 : out std_logic_vector (7 downto 0);

		memoryDataInMode3 : out std_logic_vector (20 downto 0); -- [inutil] valor que vou escrever na memoria (4 bits pra cada digito) * 5 + 1 bit pro sinal
		memoryDataOut : in std_logic_vector (20 downto 0); -- valor que to lendo da memoria
		memPosMode3 : out integer := 0;
		wrMode3 : out std_logic := '0'; -- [inutil]

		-- contador stackSizeCounter conta quando numeros foram armazenados na memoria(pilha)
		stackSizeCounterValue : in std_logic_vector (3 downto 0); -- saida do valor do contador stackSize
		stackSizeCounterClockMode3 : out std_logic := '0'; -- [inutil] controla o clock do stackSizeCounter quando esse modo eh o ativo
		stackSizeCounterUpMode3 : out std_logic := '1'; -- [inutil] controla o sentido do stackSizeCounter('1' -> aumenta; '0' -> diminui)
	
		--valores ASCII de cada display
		display7seg1mode3 : out std_logic_vector (6 downto 0);
		display7seg2mode3 : out std_logic_vector (6 downto 0);
		display7seg3mode3 : out std_logic_vector (6 downto 0);
		display7seg4mode3 : out std_logic_vector (6 downto 0);
		display7seg5mode3 : out std_logic_vector (6 downto 0);
		display7seg6mode3 : out std_logic_vector (6 downto 0)
	);
end entity;

architecture rtl of mode3 is

	-- ========================================= COMPONENTS ================================	
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

	constant maxIndex : integer := 16;

	-- ============================================= SIGNAL =============================================

	signal index : integer := 0;
	signal memAscii1 : std_logic_vector(6 downto 0);
	signal memAscii2 : std_logic_vector(6 downto 0);
	signal memAscii3 : std_logic_vector(6 downto 0);
	signal memAscii4 : std_logic_vector(6 downto 0);
	signal memAscii5 : std_logic_vector(6 downto 0);
	
	-- ============================================= FSM STATES =============================================
	type state_type is (S_idle, S_next, S_prev);
	signal state, next_state: state_type := S_idle;

begin

	-- ============================================= INSTANCES =============================================

	conv1: bcd_asciiConverter
	port map(
			ascii_i => open,
			bcd_i => memoryDataOut(3 downto 0),
			ascii_o => memAscii1,
			bcd_o => open
	);
	conv2: bcd_asciiConverter
	port map(
			ascii_i => open,
			bcd_i => memoryDataOut(7 downto 4),
			ascii_o => memAscii2,
			bcd_o => open
	);
	conv3: bcd_asciiConverter
	port map(
			ascii_i => open,
			bcd_i => memoryDataOut(11 downto 8),
			ascii_o => memAscii3,
			bcd_o => open
	);
	conv4: bcd_asciiConverter
	port map(
			ascii_i => open,
			bcd_i => memoryDataOut(15 downto 12),
			ascii_o => memAscii4,
			bcd_o => open
	);
	conv5: bcd_asciiConverter
	port map(
			ascii_i => open,
			bcd_i => memoryDataOut(19 downto 16),
			ascii_o => memAscii5,
			bcd_o => open
	);

	-- ============================================= FSM PROCESS =============================================
	-- process padrao de proximo estado da fsm
	fsm: process(clock, reset)
	begin
		if reset = '1' then
			state <= S_idle;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process;
    
	next_state <= S_idle when (state = S_next or state = S_prev) else
	              S_next when (ascii = "0111000") else
	              S_prev when (ascii = "0110010") else
		            state;

	process(clock, state)
	begin
		if state = S_next then
			index <= index + 1;
		elsif state = S_prev then
			index <= index - 1;
		end if;

		if index > (maxIndex - 1) then
			index <= 0;
		end if;
	end process:

	memPosMode3 <= index;

	display7seg1mode3 <= memAscii1;
	display7seg2mode3 <= memAscii2;
	display7seg3mode3 <= memAscii3;
	display7seg4mode3 <= memAscii4;
	display7seg5mode3 <= memAscii5;
	display7seg6mode3 <= "1000000" when memoryDataOut(20) = '1' else
											 "1111111";

end architecture;
