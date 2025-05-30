library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- modo 1 :le o tecla apertada, mostra no display o valor do numero que esta sendo digitado,
-- numero de 5 digitos + 1 sinal
-- quando aperta E armazena o valor digitado no topo da pilha
-- quando aperta C deleta o ultimo digito do numero que esta sendo digitado

entity mode1 is
	port (
		clock, reset : in std_logic := '0';

		ascii : in std_logic_vector(6 downto 0); -- ASCII da tecla presionda

        ledsMode1 : out std_logic_vector (9 downto 0);

        memoryDataInMode1 : out std_logic_vector (20 downto 0); -- valor que vou escrever na memoria (4 bits pra cada digito) * 5 + 1 bit pro sinal
        memoryDataOut : in std_logic_vector (20 downto 0); -- valor que to lendo da memoria
        memPosMode1 : out integer := 0;
        wrMode1 : out std_logic := '0';

        -- contador stackSizeCounter conta quando numeros foram armazenados na memoria(pilha)
        stackSizeCounterValue : in std_logic_vector (3 downto 0); -- saida do valor do contador stackSize
        stackSizeCounterClockMode1 : out std_logic := '0'; -- controla o clock do stackSizeCounter quando esse modo eh o ativo
        stackSizeCounterUpMode1 : out std_logic := '1'; -- controla o sentido do stackSizeCounter('1' -> aumenta; '0' -> diminui)
		
        --valores ASCII de cada display
		display7seg1Mode1 : out std_logic_vector (6 downto 0);
        display7seg2Mode1 : out std_logic_vector (6 downto 0);
        display7seg3Mode1 : out std_logic_vector (6 downto 0);
        display7seg4Mode1 : out std_logic_vector (6 downto 0);
        display7seg5Mode1 : out std_logic_vector (6 downto 0);
        display7seg6Mode1 : out std_logic_vector (6 downto 0)
	);
end entity;

architecture rtl of mode1 is

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

    component bcd_asciiConverter is
        port (
            ascii_i : in std_logic_vector(6 downto 0); 
            bcd_i : in std_logic_vector(3 downto 0); 

            ascii_o : out std_logic_vector(6 downto 0); 
            bcd_o : out std_logic_vector(3 downto 0) 
        );
    end component;

	-- ============================================= SIGNAL =============================================

    signal resetFreezeCounter, enFreezeCounter, AchievedWantedValueFreezeCounter : std_logic := '0';

    signal valueFreezeCounter, wantedValueFreezeCounter : std_logic_vector (4 downto 0);

    signal keyNumberPressed : std_logic := '0';

    -- dataTempCounter
    signal dataTempCounterClock, dataTempCounterUp : std_logic := '0';
	signal dataTempCounterValue : std_logic_vector(2 downto 0) := (others => '0') ;
    signal dataTempCounterReset : std_logic := '0'; 

    -- dataTemp reg
    signal dataTempIn, dataTempOut : std_logic_vector (20 downto 0);
    signal dataTempReset : std_logic := '0'; 
    signal shiftDataTemp : integer := 0;

    -- bcd_asciiConverter
    signal bcd_o : std_logic_vector (3 downto 0);
    signal ascii_o0, ascii_o1, ascii_o2, ascii_o3, ascii_o4, ascii_o5 : std_logic_vector (6 downto 0);
    

    -- ============================================= FSM STATES =============================================
    type state_type is (S_ready, S_storeTemp, S_update1, S_deleteTemp, S_update2, S_storeMemory, S_update3, S_freeze2);
    signal state, next_state: state_type := S_ready;

	
begin

	-- ============================================= INSTANCES =============================================
	
    -- ============================================= FSM PROCESS =============================================
	-- process padrao de proximo estado da fsm
	fsm: process(clock, reset)
	begin
		if reset = '1' then
			state <= S_ready;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process;
    
	next_state <=
		S_ready   when (state = S_ready and ascii = "1111111") else -- ta apertando nada
		S_storeTemp   when (state = S_ready and keyNumberPressed = '1')   else	-- apertou algum digito
		S_deleteTemp  when (state = S_ready and ascii = "1000011")   else -- apertou C
		S_storeMemory when (state = S_ready and ascii = "1000101")   else -- apertou E
		S_update1   when (state = S_storeTemp)   else
        S_freeze2   when (state = S_update1)   else
        S_update2   when (state = S_deleteTemp)  else
        S_freeze2   when (state = S_update2)   else
        S_update3   when (state = S_storeMemory) else
        S_freeze2   when (state = S_update3)   else
		S_freeze2   when (state = S_freeze2 and AchievedWantedValueFreezeCounter = '0' ) else 
		S_ready     when (state = S_freeze2 and AchievedWantedValueFreezeCounter = '1') else
		state;

    -- S_update1 faz dataTempCounter++
    -- S_update1 faz dataTempCounter--

    ledsMode1(4) <= '1' when state = S_ready else '0';
    ledsMode1(5) <= '1' when state = S_storeTemp else '0';
    ledsMode1(6) <= '1' when state = S_deleteTemp else '0';


    -- ============================================= LOGIC =============================================

    freeze_counter: counter 
    generic map (
        WIDTH => 5
    )
    port map (
        clock  => clock,
        reset  => resetFreezeCounter,
        enable => enFreezeCounter,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => valueFreezeCounter
    );

    wantedValueFreezeCounter <= (others => '1') ;

    enFreezeCounter <= '0' when valueFreezeCounter = wantedValueFreezeCounter else '1'; -- trava o contador quando chega no valor maximo

    resetFreezeCounter <= '0' when state = S_freeze2 else '1'; --faz comecar a contar no estados freeze

    AchievedWantedValueFreezeCounter <= '1' when valueFreezeCounter = wantedValueFreezeCounter else '0';


    keyNumberPressed <= '1' when ascii = "0110000" or 
                                ascii = "0110001" or 
                                ascii = "0110010" or 
                                ascii = "0110011" or 
                                ascii = "0110100" or 
                                ascii = "0110101" or 
                                ascii = "0110110" or 
                                ascii = "0110111" or 
                                ascii = "0111000" or 
                                ascii = "0111001" else '0';



	data_temp: shiftregister -- armazena temporariamente os digitos antes de colocar na memoria
    generic map (
      WIDTH => 21
    )
    port map (
      clock       => clock,
      reset       => dataTempReset,
      serial_i    => '0',
      loadOrShift => "11",
      data_i      => dataTempIn,
      data_o      => dataTempOut,
      serial_o_r  => open,
      serial_o_l  => open
    );   

    bcd_asciiConverter_inst: bcd_asciiConverter
    port map(
        ascii_i => ascii,
        bcd_i => "0000",
        ascii_o => open,
        bcd_o => bcd_o
    );
    
    dataTempIn(3 downto 0) <=   bcd_o when state = S_storeTemp and dataTempCounterValue = "000" else 
                                "0000" when state = S_deleteTemp and dataTempCounterValue = "000" else 
                                dataTempOut(3 downto 0);

    dataTempIn(7 downto 4) <=   bcd_o when state = S_storeTemp and dataTempCounterValue = "001" else 
                                "0000" when state = S_deleteTemp and dataTempCounterValue = "001" else 
                                    dataTempOut(7 downto 4);

    dataTempIn(11 downto 8) <=  bcd_o when state = S_storeTemp and dataTempCounterValue = "010" else 
                                "0000" when state = S_deleteTemp and dataTempCounterValue = "010" else 
                                dataTempOut(11 downto 8);

    dataTempIn(15 downto 12) <= bcd_o when state = S_storeTemp and dataTempCounterValue = "011" else 
                                "0000" when state = S_deleteTemp and dataTempCounterValue = "011" else 
                                dataTempOut(15 downto 12);

    dataTempIn(19 downto 16) <= bcd_o when state = S_storeTemp and dataTempCounterValue = "100" else 
                                "0000" when state = S_deleteTemp and dataTempCounterValue = "100" else 
                                dataTempOut(19 downto 16);  

    --shiftDataTemp <= 4*to_integer(unsigned(dataTempCounterValue));                                                               
    --dataTempIn(3 + shiftDataTemp downto 0 + shiftDataTemp) <= bcd_o when state = S_storeTemp else dataTempOut(3 + shiftDataTemp downto 0 + shiftDataTemp); -- nao gosto disso
    
    data_temp_size: counter -- conta quantos digitos estao armazenados no reg reg data_temp
    generic map (
        WIDTH => 3
    )
    port map (
        clock  => dataTempCounterClock,
        reset  => dataTempCounterReset,
        enable => '1',
        load   => '0',
        up     => dataTempCounterUp,
        data_i => (others => '0'),
        data_o => dataTempCounterValue
    );

    dataTempCounterClock <= '1' when state = S_update1 or state = S_update2 else '0'; -- da um pulso de clock quando ta nos estados update

    dataTempCounterUp <= '1' when state = S_update1 else
                        '0' when state = S_update2 or state = S_deleteTemp else
                        '1'; 
    
    ledsMode1(7) <= dataTempCounterValue(0);
    ledsMode1(8) <= dataTempCounterValue(1);
    ledsMode1(9) <= dataTempCounterValue(2);

    -- armazanar na memoria
    memoryDataInMode1 <= dataTempOut;

    memPosMode1 <= to_integer(unsigned(stackSizeCounterValue));  

    wrMode1 <= '1' when state = S_storeMemory else '0';

    stackSizeCounterClockMode1 <= '1' when state = S_update3 else '0'; -- da um pulso de clock
    stackSizeCounterUpMode1 <= '1';

    dataTempReset <= '1' when reset = '1' or state = S_update3 else '0';

    dataTempCounterReset <= '1' when reset = '1' or state = S_update3 else '0';


    -- exibir conteudo do data_temp nos displays
    bcd_asciiConverter_inst0: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => dataTempOut(3 downto 0),
        ascii_o => ascii_o0,
        bcd_o => open
    );

    bcd_asciiConverter_inst1: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => dataTempOut(7 downto 4),
        ascii_o => ascii_o1,
        bcd_o => open
    );

    bcd_asciiConverter_inst2: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => dataTempOut(11 downto 8),
        ascii_o => ascii_o2,
        bcd_o => open
    );

    bcd_asciiConverter_inst3: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => dataTempOut(15 downto 12),
        ascii_o => ascii_o3,
        bcd_o => open
    );

    bcd_asciiConverter_inst4: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => dataTempOut(19 downto 16),
        ascii_o => ascii_o4,
        bcd_o => open
    );

    bcd_asciiConverter_inst5: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => "0000",
        ascii_o => ascii_o5,
        bcd_o => open
    );

    display7seg1Mode1 <= ascii_o0;
    display7seg2Mode1 <= ascii_o1;
    display7seg3Mode1 <= ascii_o2;
    display7seg4Mode1 <= ascii_o3;
    display7seg5Mode1 <= ascii_o4;
    display7seg6Mode1 <= ascii_o5;

end architecture;
