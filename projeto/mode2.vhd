library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--le o tecla apertada pra selecionar uma operacao
-- realiza a operacao entre os 2 numeros no topo da pilha, remove eles, e armazena o resultado no topo da pilha
-- sempre mostra nos displays o valor do topo da pilha

entity mode2 is
	port (
		clock, reset : in std_logic := '0';

		ascii : in std_logic_vector(6 downto 0); -- ASCII da tecla presionda

        ledsmode2 : out std_logic_vector (9 downto 0);

        memoryDataInMode2 : out std_logic_vector (20 downto 0); -- valor que vou escrever na memoria (4 bits pra cada digito) * 5 + 1 bit pro sinal
        memoryDataOut : in std_logic_vector (20 downto 0); -- valor que to lendo da memoria
        memPosMode2 : out integer := 0;
        wrMode2 : out std_logic := '0';

        -- contador stackSizeCounter conta quando numeros foram armazenados na memoria(pilha)
        stackSizeCounterValue : in std_logic_vector (3 downto 0); -- saida do valor do contador stackSize
        stackSizeCounterClockMode2 : out std_logic := '0'; -- controla o clock do stackSizeCounter quando esse modo eh o ativo
        stackSizeCounterUpMode2 : out std_logic := '1'; -- controla o sentido do stackSizeCounter('1' -> aumenta; '0' -> diminui)r
		
        --valores ASCII de cada display
		display7seg1mode2 : out std_logic_vector (6 downto 0);
        display7seg2mode2 : out std_logic_vector (6 downto 0);
        display7seg3mode2 : out std_logic_vector (6 downto 0);
        display7seg4mode2 : out std_logic_vector (6 downto 0);
        display7seg5mode2 : out std_logic_vector (6 downto 0);
        display7seg6mode2 : out std_logic_vector (6 downto 0)
	);
end entity;

architecture rtl of mode2 is

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

    component bcd_asciiConverter is
        port (
            ascii_i : in std_logic_vector(6 downto 0); 
            bcd_i : in std_logic_vector(3 downto 0); 

            ascii_o : out std_logic_vector(6 downto 0); 
            bcd_o : out std_logic_vector(3 downto 0) 
        );
    end component;

	component BCD_to_bin is
        port (
            bcd_in : in  std_logic_vector(20 downto 0);
            bin_out : out  std_logic_vector(17 downto 0) := (others => '0')
        );
    end component;

	component bin_to_BCD is
        port (
            i_Clock  : in std_logic;
            i_Start  : in std_logic;
            bin_in  : in std_logic_vector(17 downto 0) := (others => '0'); -- binario SIGNED(complemento de 2)

            bcd_out : out std_logic_vector(20 downto 0);
            o_DV  : out std_logic -- ta pronto
        );
    end component;


	-- ============================================= SIGNAL =============================================

	-- bcd_asciiConverter
    signal bcd_o : std_logic_vector (3 downto 0);
    signal ascii_o0, ascii_o1, ascii_o2, ascii_o3, ascii_o4, ascii_o5 : std_logic_vector (6 downto 0);

	-- fsm
	signal start, done, keyOpPressed, stackValidSize: std_logic := '0';
	
	-- ascii op temp reg
	signal asciiOpIn, asciiOpValue : std_logic_vector (6 downto 0);

	-- reg num 1 e 2
	signal num1In, num1Value, num2In, num2Value : std_logic_vector (20 downto 0);
	

	-- 
	signal bin1, bin2, binResultAdd, binResultSub, binResultDiv, binResultSelected : std_logic_vector(17 downto 0) := (others => '0') ;
	signal binResultMult : std_logic_vector(35 downto 0) := (others => '0') ;
	signal BCDResult : std_logic_vector(20 downto 0) := (others => '0') ;

	

	-- ============================================= FSM STATES =============================================
    type state_type is (S_ready, S_store_op, S_storeNum1, S_storeNum2, S_startBinToBCD, S_wait, S_storeResult, S_popMem, S_updateStackSize, S_freeze);
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
		S_ready         when (state = S_ready and (keyOpPressed = '0' or stackValidSize = '0')) else
		S_store_op      when (state = S_ready and keyOpPressed = '1' and stackValidSize = '1') else  
		S_storeNum1     when (state = S_store_op) else
		S_storeNum2     when (state = S_storeNum1) else  
		S_startBinToBCD when (state = S_storeNum2) else 
		S_wait  		when (state = S_startBinToBCD) else  
		S_wait   		when (state = S_wait and done = '0')   else
		S_storeResult   when (state = S_wait and done = '1')   else
		S_popMem  		when (state = S_storeResult) else 
		S_updateStackSize when (state = S_popMem) else
		S_ready  		when (state = S_updateStackSize) else
		state;


	keyOpPressed <= '1' when ascii = "1000001" or -- F1 - soma
							 ascii = "1000010" or -- F2 - subtracao
							 ascii = "1000100" or -- F3 - multiplicacao
							 ascii = "1001000" else -- F4 - divisao
							 '0';

	stackValidSize <= '0' when stackSizeCounterValue = "0000" or stackSizeCounterValue = "0001" else '1';

	-- ============================================= LOGIC =============================================

	op_temp: shiftregister -- armazena o ascii da operacao selecionada
    generic map (
        WIDTH => 7
    )
    port map (
        clock       => clock,
        reset       => '0',
        serial_i    => '0',
        loadOrShift => "11",
        data_i      => asciiOpIn,
        data_o      => asciiOpValue,
        serial_o_r  => open,
        serial_o_l  => open
    );

	asciiOpIn <= ascii when state = S_store_op else asciiOpValue;

	Number1_BCD: shiftregister -- armazena o 1 operando
    generic map (
        WIDTH => 21
    )
    port map (
        clock       => clock,
        reset       => '0',
        serial_i    => '0',
        loadOrShift => "11",
        data_i      => num1In,
        data_o      => num1Value,
        serial_o_r  => open,
        serial_o_l  => open
    );

	num1In <= memoryDataOut when state = S_storeNum1 else num1Value;

	Number2_BCD: shiftregister -- armazena o 2 operando
    generic map (
        WIDTH => 21
    )
    port map (
        clock       => clock,
        reset       => '0',
        serial_i    => '0',
        loadOrShift => "11",
        data_i      => num2In,
        data_o      => num2Value,
        serial_o_r  => open,
        serial_o_l  => open
    );

	num2In <= memoryDataOut when state = S_storeNum2 else num2Value;

	BCD_to_bin_inst0: entity work.BCD_to_bin
     port map(
        bcd_in => num1Value,
        bin_out => bin1
    );

    BCD_to_bin_inst1: entity work.BCD_to_bin
     port map(
        bcd_in => num2Value,
        bin_out => bin2
    );

    --num2 eh o numero no topo da pilha
    --num1 eh o numero antes do topo da pilha

	binResultAdd <= std_logic_vector( unsigned(bin1) + unsigned(bin2) );

	binResultSub <= std_logic_vector( unsigned(bin1) - unsigned(bin2) );

	binResultDiv <= std_logic_vector( unsigned(bin1) / unsigned(bin2) );

	binResultmult <= std_logic_vector( unsigned(bin1) * unsigned(bin2) );

	-- por quanto vou ignorar os casos de overflow

	binResultSelected <= binResultAdd when asciiOpValue = "1000001" else -- F1 - soma
						binResultSub when asciiOpValue = "1000010" else -- F2 - subtracao
						binResultDiv when asciiOpValue = "1000100" else -- F3 - multiplicacao 
						binResultmult(17 downto 0) ; -- F4 - divisao


	bin_to_BCD_inst: entity work.bin_to_BCD
     port map(
        i_Clock => clock,
        i_Start => start,
        bin_in => binResultSelected,
        bcd_out => BCDResult,
        o_DV => done
    );

	start <= '1' when state = S_startBinToBCD else '0';

	-- set memPosMode2
	memPosMode2 <= to_integer(unsigned(stackSizeCounterValue)) - 2 when state = S_storeNum1 or state = S_storeResult else -- elemento antes do topo
				   to_integer(unsigned(stackSizeCounterValue)) - 1; -- elemento no topo da pilha


	-- armazanar resultado na memoria e apaga(armazena valor zero) elemento no do topo da pilha
    memoryDataInMode2 <= BCDResult when state = S_storeResult else
						(others => '0') when state = S_popMem else
						memoryDataOut; -- nao precisava disso, mas coloquei pra visualizar melhor

    wrMode2 <= '1' when state = S_storeResult or state = S_popMem else '0'; -- no estado S_storeResult, memPosMode2 ta setado pra apontar pro elemento antes do topo

	-- atualiza stackSize reg
    stackSizeCounterClockMode2 <= '1' when state = S_updateStackSize else '0'; -- da um pulso de clock
	stackSizeCounterUpMode2 <= '0'; -- ta setado pra diminuir o valor

    -- leds

	ledsmode2(3 downto 0) <= stackSizeCounterValue;

	
    -- exibir nos displays o ultimo elemento da pilha
	--memPosMode2 <= to_integer(unsigned(stackSizeCounterValue)) - 1;

    bcd_asciiConverter_inst0: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => memoryDataOut(3 downto 0),
        ascii_o => ascii_o0,
        bcd_o => open
    );

    bcd_asciiConverter_inst1: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => memoryDataOut(7 downto 4),
        ascii_o => ascii_o1,
        bcd_o => open
    );

    bcd_asciiConverter_inst2: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => memoryDataOut(11 downto 8),
        ascii_o => ascii_o2,
        bcd_o => open
    );

    bcd_asciiConverter_inst3: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => memoryDataOut(15 downto 12),
        ascii_o => ascii_o3,
        bcd_o => open
    );

    bcd_asciiConverter_inst4: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => memoryDataOut(19 downto 16),
        ascii_o => ascii_o4,
        bcd_o => open
    );

    ascii_o5 <= "0101101" when memoryDataOut(20) = '1' else "1111111";

    display7seg1Mode2 <= ascii_o0;
    display7seg2Mode2 <= ascii_o1;
    display7seg3Mode2 <= ascii_o2;
    display7seg4Mode2 <= ascii_o3;
    display7seg5Mode2 <= ascii_o4;
    display7seg6Mode2 <= ascii_o5;

end architecture;
