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
	
	-- ============================================= FSM STATES =============================================
	type state_type is (S_idle, S_next, S_prev);
	signal state, next_state: state_type := S_idle;

begin

	-- ============================================= INSTANCES =============================================
	
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

	display7seg1mode3 <= memoryDataOut(3 downto 0);
	display7seg2mode3 <= memoryDataOut(7 downto 4);
	display7seg3mode3 <= memoryDataOut(11 downto 8);
	display7seg4mode3 <= memoryDataOut(15 downto 12);
	display7seg5mode3 <= memoryDataOut(19 downto 16);
	display7seg6mode3 <= "1000000" when memoryDataOut(20) = '1' else
											 "1111111";

end architecture;
