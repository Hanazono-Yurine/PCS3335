library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calculator is
	port (
		clock50M, reset: in std_logic := '0';

		c : out std_logic_vector(3 downto 0);
        l : in std_logic_vector(3 downto 0);
		
		up, down : in std_logic := '0';

        leds : out std_logic_vector (9 downto 0);

		goToMenu : in std_logic := '0';

		pinDebug : out std_logic := '0';
		
		display7seg1 : out std_logic_vector (6 downto 0);
        display7seg2 : out std_logic_vector (6 downto 0);
        display7seg3 : out std_logic_vector (6 downto 0);
        display7seg4 : out std_logic_vector (6 downto 0);
        display7seg5 : out std_logic_vector (6 downto 0);
        display7seg6 : out std_logic_vector (6 downto 0)
	);
end entity;

architecture rtl of calculator is

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

	component ascii2seg is
		port (
			off : in std_logic;
			asc : in std_logic_vector(6 downto 0);
			seg : out std_logic_vector(6 downto 0);
			dot : out std_logic
			);
			  
	end component;

    component keyboard4x4 is
		port (
			clock, reset: in std_logic := '0';
			c : out std_logic_vector(3 downto 0);
			l : in std_logic_vector(3 downto 0);
			ascii : out std_logic_vector(6 downto 0);
			isPressed : out std_logic := '0'
		);
    end component;

	component memory is
		generic(
			size : natural := 16;     -- armazena 16 numeros
			wordSize : natural := 21  -- (4 bits pra cada digito) * 5 + 1 bit pro sinal
		);
		port(
			clk, wr : in  std_logic;
			pos : in integer;
			data_i : in  std_logic_vector(wordSize-1 downto 0);
			data_o : out std_logic_vector(wordSize-1 downto 0)
		);
	end component;

	component mode1 is
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
	end component;


	component mode2 is
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
	end component;

	component mode3 is
		port (
			clock, reset : in std_logic := '0';

			ascii : in std_logic_vector(6 downto 0); -- ASCII da tecla presionda

			ledsmode3 : out std_logic_vector (9 downto 0);

			memoryDataInMode3 : out std_logic_vector (20 downto 0); -- valor que vou escrever na memoria (4 bits pra cada digito) * 5 + 1 bit pro sinal
			memoryDataOut : in std_logic_vector (20 downto 0); -- valor que to lendo da memoria
			memPosMode3 : out integer := 0;
			wrMode3 : out std_logic := '0';

			-- contador stackSizeCounter conta quando numeros foram armazenados na memoria(pilha)
			stackSizeCounterValue : in std_logic_vector (3 downto 0); -- saida do valor do contador stackSize
			stackSizeCounterClockMode3 : out std_logic := '0'; -- controla o clock do stackSizeCounter quando esse modo eh o ativo
			stackSizeCounterUpMode3 : out std_logic := '1'; -- controla o sentido do stackSizeCounter('1' -> aumenta; '0' -> diminui)
			
			--valores ASCII de cada display
			display7seg1mode3 : out std_logic_vector (6 downto 0);
			display7seg2mode3 : out std_logic_vector (6 downto 0);
			display7seg3mode3 : out std_logic_vector (6 downto 0);
			display7seg4mode3 : out std_logic_vector (6 downto 0);
			display7seg5mode3 : out std_logic_vector (6 downto 0);
			display7seg6mode3 : out std_logic_vector (6 downto 0)
		);
	end component;

	-- ============================================= SIGNAL =============================================

	--clock divisor
	constant CLOCK_DIVISOR_VALUE : integer := 12;
	signal clockDivisorValue: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(CLOCK_DIVISOR_VALUE,16));

	-- clocks
	signal clock1_8MHz, clock, clockKeyboard: std_logic := '1';

	--signal leds_debug : std_logic_vector(7 downto 0);

    -- keyboard 4x4
    signal ascii, asciiMode1, asciiMode2, asciiMode3, ascii_temp : std_logic_vector(6 downto 0);
	signal isPressed : std_logic := '0';

	--memory
	signal pos : integer := 0;
	signal data_i, memoryDataOut : std_logic_vector(20 downto 0) := (others => '0') ;
	signal wr : std_logic := '0'; 

	-- stackSizeCounter
	signal stackSizeCounterClock, stackSizeCounterUp : std_logic := '0';
	signal stackSizeCounterValue : std_logic_vector(3 downto 0) := (others => '0') ; 

	--mode1
	signal mode1Selected, mode1Exit : std_logic := '0';
	signal ledsMode1 : std_logic_vector (9 downto 0);
	signal memoryDataInMode1 : std_logic_vector(20 downto 0) := (others => '0') ;
	signal memPosMode1 : integer := 0;
	signal wrMode1 : std_logic := '0'; 
	signal stackSizeCounterClockMode1, stackSizeCounterUpMode1 : std_logic := '0'; 
	signal display7seg1Mode1, display7seg2Mode1, display7seg3Mode1, display7seg4Mode1, display7seg5Mode1, display7seg6Mode1 : std_logic_vector (6 downto 0);

	--mode2
	signal mode2Selected, mode2Exit : std_logic := '0';
	signal ledsMode2 : std_logic_vector (9 downto 0);
	signal memoryDataInMode2 : std_logic_vector(20 downto 0) := (others => '0') ;
	signal memPosMode2 : integer := 0;
	signal wrMode2 : std_logic := '0'; 
	signal stackSizeCounterClockMode2, stackSizeCounterUpMode2 : std_logic := '0'; 
	signal display7seg1Mode2, display7seg2Mode2, display7seg3Mode2, display7seg4Mode2, display7seg5Mode2, display7seg6Mode2 : std_logic_vector (6 downto 0);

	--mode3
	signal mode3Selected, mode3Exit : std_logic := '0';
	signal ledsMode3 : std_logic_vector (9 downto 0);
	signal memoryDataInMode3 : std_logic_vector(20 downto 0) := (others => '0') ;
	signal memPosMode3 : integer := 0;
	signal wrMode3 : std_logic := '0'; 
	signal stackSizeCounterClockMode3, stackSizeCounterUpMode3 : std_logic := '0'; 
	signal display7seg1Mode3, display7seg2Mode3, display7seg3Mode3, display7seg4Mode3, display7seg5Mode3, display7seg6Mode3 : std_logic_vector (6 downto 0);

	-- displays 7 seg
	signal ascii_input1, ascii_input2, ascii_input3, ascii_input4, ascii_input5, ascii_input6 : std_logic_vector (6 downto 0);


	-- ============================================= FSM STATES =============================================
    type state_type is (S_menu, Smode1, Smode2, Smode3);
    signal state, next_state: state_type := S_menu;


begin

	-- ============================================= INSTANCES =============================================
	--ip_pll
    ip_pll: ip_pll_50MHz
    port map (
        refclk   => clock50M,
        rst      => '0',
        outclk_0 => clock1_8MHz,
		locked => open
    );

	--Low clock just for debugging
	baudrategenerator_inst: baudRateGenerator
	port map (
        clock     => clock1_8MHz,
        reset     => '0',
        --divisor   => std_logic_vector(to_unsigned(1,16)),
        divisor   => (others => '1'), -- 1.8Mhz / 2^16 = 28Hz
        baudOut_n => clock
	);

	baudrategenerator_inst1: baudRateGenerator
	port map (
        clock     => clock,
        reset     => '0',
        divisor   => std_logic_vector(to_unsigned(8,16)),
        --divisor   => (others => '1'),
        baudOut_n => clockKeyboard
	);

	--clock <= clockKeyboard;

    keyboard4x4_inst: keyboard4x4
    port map(
        clock => clock,
        reset => reset,
        c => c,
        l => l,
        ascii => ascii,
        isPressed => isPressed
    );

	stackSize: counter 
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => stackSizeCounterClock,
        reset  => reset,
        enable => '1',
        load   => '0',
        up     => stackSizeCounterUp,
        data_i => (others => '0'),
        data_o => stackSizeCounterValue
    );

	memory_inst: memory
	generic map(
		size => 16,
		wordSize => 21
	)
	 port map(
		clk => clock,
		wr => wr,
		pos => pos,
		data_i => data_i,
		data_o => memoryDataOut
	);

	mode1_inst: entity work.mode1
	 port map(
		clock => clock,
		reset => reset,
		ascii => asciiMode1,
		ledsMode1 => ledsMode1,
		memoryDataInMode1 => memoryDataInMode1,
		memoryDataOut => memoryDataOut,
		memPosMode1 => memPosMode1,
		wrMode1 => wrMode1,
		stackSizeCounterValue => stackSizeCounterValue,
		stackSizeCounterClockMode1 => stackSizeCounterClockMode1,
		stackSizeCounterUpMode1 => stackSizeCounterUpMode1,
		display7seg1Mode1 => display7seg1Mode1,
		display7seg2Mode1 => display7seg2Mode1,
		display7seg3Mode1 => display7seg3Mode1,
		display7seg4Mode1 => display7seg4Mode1,
		display7seg5Mode1 => display7seg5Mode1,
		display7seg6Mode1 => display7seg6Mode1
	);

	mode2_inst: entity work.mode2
	 port map(
		clock => clock,
		reset => reset,
		ascii => asciiMode2,
		ledsmode2 => ledsmode2,
		memoryDataInMode2 => memoryDataInMode2,
		memoryDataOut => memoryDataOut,
		memPosMode2 => memPosMode2,
		wrMode2 => wrMode2,
		stackSizeCounterValue => stackSizeCounterValue,
		stackSizeCounterClockMode2 => stackSizeCounterClockMode2,
		stackSizeCounterUpMode2 => stackSizeCounterUpMode2,
		display7seg1mode2 => display7seg1mode2,
		display7seg2mode2 => display7seg2mode2,
		display7seg3mode2 => display7seg3mode2,
		display7seg4mode2 => display7seg4mode2,
		display7seg5mode2 => display7seg5mode2,
		display7seg6mode2 => display7seg6mode2
	);

	mode3_inst: entity work.mode3
	 port map(
		clock => clock,
		reset => reset,
		up => up,
		down => down,
		ascii => asciiMode3,
		ledsmode3 => ledsmode3,
		memoryDataInMode3 => memoryDataInMode3,
		memoryDataOut => memoryDataOut,
		memPosMode3 => memPosMode3,
		wrMode3 => wrMode3,
		stackSizeCounterValue => stackSizeCounterValue,
		stackSizeCounterClockMode3 => stackSizeCounterClockMode3,
		stackSizeCounterUpMode3 => stackSizeCounterUpMode3,
		display7seg1mode3 => display7seg1mode3,
		display7seg2mode3 => display7seg2mode3,
		display7seg3mode3 => display7seg3mode3,
		display7seg4mode3 => display7seg4mode3,
		display7seg5mode3 => display7seg5mode3,
		display7seg6mode3 => display7seg6mode3
	);

	ascii2seg_inst1: ascii2seg
	port map(
		off => '0',
		asc => ascii_input1, 
		seg => display7seg1,
		dot => open
	);

    ascii2seg_inst2: ascii2seg
	port map(
		off => '0',
		asc => ascii_input2, 
		seg => display7seg2,
		dot => open
	);

    ascii2seg_inst3: ascii2seg
	port map(
		off => '0',
		asc => ascii_input3, 
		seg => display7seg3,
		dot => open
	);

    ascii2seg_inst4: ascii2seg
	port map(
		off => '0',
		asc => ascii_input4, 
		seg => display7seg4,
		dot => open
	);

    ascii2seg_inst5: ascii2seg
	port map(
		off => '0',
		asc => ascii_input5, 
		seg => display7seg5,
		dot => open
	);

    ascii2seg_inst6: ascii2seg
	port map(
		off => '0',
		--asc => ascii_input6, 
		asc => ascii,
		seg => display7seg6,
		dot => open
	);

	-- ============================================= FSM PROCESS =============================================
	-- process padrao de proximo estado da fsm
	fsm: process(clock, reset)
	begin
		if reset = '1' then
			state <= S_menu;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process;
    
	next_state <=
		S_menu   when (state = S_menu and ascii_temp = "1111111") else -- nada ta sendo apertado 
		Smode1   when (state = S_menu and ascii_temp = "0110001") else -- apertou botao 1 
		Smode2   when (state = S_menu and ascii_temp = "0110010") else -- apertou botao 2
		Smode3   when (state = S_menu and ascii_temp = "0110011") else -- apertou botao 3
		Smode1   when (state = Smode1 and goToMenu = '0')   else
		S_menu   when (state = Smode1 and goToMenu = '1')   else	
		Smode2   when (state = Smode2 and goToMenu = '0')   else
		S_menu   when (state = Smode2 and goToMenu = '1')   else
		Smode3   when (state = Smode3 and goToMenu = '0')   else
		S_menu   when (state = Smode3 and goToMenu = '1')   else
		state;

	-- ============================================= LOGIC =============================================
	
	ascii_temp <= ascii when state = S_menu else "1111111";

	--pressed1 <= '1' when ascii = "0110001" else '0';

	--memoria
	wr <= wrMode1 when state = Smode1 else
			wrMode2 when state = Smode2 else
			wrMode3 when state = Smode3 else
			'0';

	pos <= memPosMode1 when state = Smode1 else
			memPosMode2 when state = Smode2 else
			memPosMode3 when state = Smode3 else
			0;
	
	data_i <= memoryDataInMode1 when state = Smode1 else
			memoryDataInMode2 when state = Smode2 else
			memoryDataInMode3 when state = Smode3 else
			(others => '0') ;

	--stackSize Counter
	stackSizeCounterClock <= stackSizeCounterClockMode1 when state  = Smode1 else
							stackSizeCounterClockMode2 when state  = Smode2 else
							stackSizeCounterClockMode3 when state  = Smode3 else
							'0';

	stackSizeCounterUp <= stackSizeCounterUpMode1 when state  = Smode1 else
							stackSizeCounterUpMode2 when state  = Smode2 else
							stackSizeCounterUpMode3 when state  = Smode3 else
							'0';


	-- ascii do keyboard4x4

	asciiMode1 <= ascii when state = Smode1 else "1111111";

	asciiMode2 <= ascii when state = Smode2 else "1111111";

	asciiMode3 <= ascii when state = Smode3 else "1111111";
	
	-- leds
	leds(0) <= '1' when state = S_menu else '0';
	leds(1) <= '1' when state = Smode1 else '0';
	leds(2) <= '1' when state = Smode2 else '0';
	leds(3) <= '1' when state = Smode3 else '0';
	leds(9 downto 4) <= ledsMode1(9 downto 4) when state = Smode1 else
						ledsMode2(9 downto 4) when state = Smode2 else
						ledsMode3(9 downto 4) when state = Smode3 else
						"000000";

	-- displays 7 seg
	ascii_input1 <= display7seg1Mode1 when state = Smode1 else
					display7seg1Mode2 when state = Smode2 else
					display7seg1Mode3 when state = Smode3 else
					"1010100" ; -- S 1010100

	ascii_input2 <= display7seg2Mode1 when state = Smode1 else
					display7seg2Mode2 when state = Smode2 else
					display7seg2Mode3 when state = Smode3 else
					"1000011" ; -- E 1000011
					
	ascii_input3 <= display7seg3Mode1 when state = Smode1 else
					display7seg3Mode2 when state = Smode2 else
					display7seg3Mode3 when state = Smode3 else
					"1000101" ; -- L 1000101

	ascii_input4 <= display7seg4Mode1 when state = Smode1 else
					display7seg4Mode2 when state = Smode2 else
					display7seg4Mode3 when state = Smode3 else
					"1001100" ; -- E 1001100

	ascii_input5 <= display7seg5Mode1 when state = Smode1 else
					display7seg5Mode2 when state = Smode2 else
					display7seg5Mode3 when state = Smode3 else
					"1000101" ; -- C 1000101

	ascii_input6 <= display7seg6Mode1 when state = Smode1 else
					display7seg6Mode2 when state = Smode2 else
					display7seg6Mode3 when state = Smode3 else
					"1010011" ; -- T 1010011
	


	pinDebug <= goToMenu;		

end architecture;
