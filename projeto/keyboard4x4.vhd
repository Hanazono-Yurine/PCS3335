library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard4x4 is
	port (
		clock, reset: in std_logic := '0';
		c : out std_logic_vector(3 downto 0);
		l : in std_logic_vector(3 downto 0);
		ascii : out std_logic_vector(6 downto 0); -- ASCII da tecla presionda
		isPressed : out std_logic := '0' -- acho que nao precisa disso, depois tiro
	);
end entity;

architecture rtl of keyboard4x4 is

	-- ========================================= COMPONENTS ================================

	component shiftregisterKeyboard is
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

	-- ============================================= SIGNAL =============================================

	signal reg_left_output: std_logic := '0';
	signal reg_c : std_logic_vector(3 downto 0);

	signal asciiAsync : std_logic_vector(6 downto 0) := (others => '1');

	signal resetFreezeCounter, enFreezeCounter, AchievedWantedValueFreezeCounter : std_logic := '0';

    signal valueFreezeCounter, wantedValueFreezeCounter : std_logic_vector (4 downto 0);

	-- ============================================= FSM STATES =============================================
    type state_type is (S_idle, S_pressed, S_freeze);
    signal state, next_state: state_type := S_idle;

begin

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
    
	next_state <=
		S_idle    when (state = S_idle and asciiAsync = "1111111") else -- 
		S_pressed when (state = S_idle  and asciiAsync /= "1111111")   else	-- 
		S_freeze  when (state = S_pressed)   else -- 
		S_freeze  when (state = S_freeze and AchievedWantedValueFreezeCounter = '0' )   else -- 
		S_idle    when (state = S_freeze and AchievedWantedValueFreezeCounter = '1')   else
		state;

	-- ============================================= INSTANCES =============================================

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

    resetFreezeCounter <= '0' when state = S_freeze else '1'; --faz comecar a contar no estados freeze

    AchievedWantedValueFreezeCounter <= '1' when valueFreezeCounter = wantedValueFreezeCounter else '0';



	--clock <= clock1_8MHz;

	loop_reg: shiftregisterKeyboard
    generic map (
      WIDTH => 4
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => reg_left_output,
      loadOrShift => "01",
      data_i      => (others => '0'),
      data_o      => reg_c,
      serial_o_r  => reg_left_output,
      serial_o_l  => open
    );

	c <= reg_c;

	-- ascii obtido pelo varedura
	asciiAsync <=  "0110111" when reg_c(0) = '0' and l(0) = '0' else -- 7
			            "0111000" when reg_c(1) = '0' and l(0) = '0' else -- 8
			            "0111001" when reg_c(2) = '0' and l(0) = '0' else -- 9
			            "1000001" when reg_c(3) = '0' and l(0) = '0' else -- A (OP 1)
			            "0110100" when reg_c(0) = '0' and l(1) = '0' else -- 4
			            "0110101" when reg_c(1) = '0' and l(1) = '0' else -- 5
			            "0110110" when reg_c(2) = '0' and l(1) = '0' else -- 6
			            "1000010" when reg_c(3) = '0' and l(1) = '0' else -- B (OP 2)
			            "0110001" when reg_c(0) = '0' and l(2) = '0' else -- 1
			            "0110010" when reg_c(1) = '0' and l(2) = '0' else -- 2
			            "0110011" when reg_c(2) = '0' and l(2) = '0' else -- 3
			            "1000100" when reg_c(3) = '0' and l(2) = '0' else -- D (OP 3)
			            "1000011" when reg_c(0) = '0' and l(3) = '0' else -- C 
			            "0110000" when reg_c(1) = '0' and l(3) = '0' else -- 0
			            "1000101" when reg_c(2) = '0' and l(3) = '0' else -- E
			            "1001000" when reg_c(3) = '0' and l(3) = '0' else -- H (OP 4)
			            "1111111"; -- nada ta sendo apertado

	ascii <= asciiAsync when state = S_pressed else "1111111";
	-- ascii <= asciiAsync;


	--leds_debug <= reg_c & l;

end architecture;
