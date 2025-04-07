library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitterTimingControl is
	port (
		clock, reset        : in std_logic;
		thrSend             : in std_logic := '0';
		txConfig            : in std_logic_vector(6 downto 0);
		-- 000 - TSR faz nada
		-- 001 - TSR Envia o Start Bit
		-- 010 - TSR Envia o proximo bit da Mensagem
		-- 011 - TSR Envia o End Bit
		-- 100 - TSR Envia o bit de paridade Par
		-- 101 - TSR Envia o bit de paridade Impar
		-- 111 - TSR Faz load do THR
		tsrControl          : out std_logic_vector(2 downto 0);
		lsrControl          : out std_logic_vector(1 downto 0)
	);
end entity;

architecture rtl of transmitterTimingControl is

	component counter is
	generic (
		WIDTH : natural := 8 -- Size in bits
	);
	port (
		clock, reset, enable, load, up : in std_logic;
		data_i                         : in std_logic_vector( WIDTH-1 downto 0 );
		data_o                         : out std_logic_vector( WIDTH-1 downto 0 )
	);
	end component;

	signal sig_regControl    : std_logic_vector(1 downto 0);
	signal reset_desloca     :  std_logic := '0'; 
	signal counterDeslocaOut : std_logic_vector(4 downto 0);
	signal counter15_out     : std_logic_vector(3 downto 0);


	signal counted_bits, counted_bit, counted_bit_enable : std_logic := '0';

	signal counter15_reset, counter15_en, contou15 : std_logic := '0';

	signal totalBitsTX : std_logic_vector( 4 downto 0 ) := std_logic_vector(to_unsigned( 11, 5 )); -- In binary = 1011

	signal sendParityBit : std_logic := '0';

	signal lsrBits : std_logic_vector( 1 downto 0 ) := (others => '0');

	signal thrHasData : std_logic;

	--fsm
	type state_type is (Sreset, Sload, S_idle, SstartBit, SnextBit, SparityBit, SendBit, Sready);
	signal state, next_state: state_type := Sload;

begin

	counterAllBits: counter
	generic map (
			WIDTH => 5
	)
	port map (
		clock  => counted_bit,
		reset  => reset_desloca,
		enable => counted_bit_enable,
		load   => '0',
		up     => '1',
		data_i => (others => '0'),
		data_o => counterDeslocaOut
	);

	-- Achei melhor usar um mux enorme mesmo
	-- Senao teria fica mais complexo
	-- Se vc tiver outra ideia, sintasse livre pra modificar
	totalBitsTX <= std_logic_vector(to_unsigned( 5, 5 )) when txConfig(0) = '0' and txConfig(1) = '0' else
								 std_logic_vector(to_unsigned( 6, 5 )) when txConfig(0) = '0' and txConfig(1) = '1' else
								 std_logic_vector(to_unsigned( 7, 5 )) when txConfig(0) = '1' and txConfig(1) = '0' else
								 std_logic_vector(to_unsigned( 8, 5 )) when txConfig(0) = '1' and txConfig(1) = '1';

	counted_bit <= '1' when state = SnextBit else '0';
	reset_desloca <= '1' when state = Sload else '0';

	counted_bits <= '1' when counterDeslocaOut = totalBitsTX else 
		'0'; 
	counted_bit_enable <= '0' when counterDeslocaOut = totalBitsTX else
		'1';  

	counter15: counter
	generic map (
		WIDTH => 4
	)
	port map (
		clock  => clock,
		reset  => counter15_reset,
		enable => counter15_en,
		load   => '0',
		up     => '1',
		data_i => (others => '0'),
		data_o => counter15_out
	);

	counter15_reset <= '0' when state = S_idle or state = Sload else '1';

	contou15 <= '1' when counter15_out = STD_LOGIC_VECTOR(to_unsigned(14,4)) else
		'0'; 
	counter15_en <= '0' when counter15_out = STD_LOGIC_VECTOR(to_unsigned(14,4)) else
		'1';  

	process(thrSend, state)
	begin
		if rising_edge(thrSend) then
			thrHasData <= '1';
		elsif state = Sload then
			thrHasData <= '0';
		end if;
	end process;

	-- process padrao de procimo estado da fsm
	process(clock, reset)
	begin
		if reset = '1' then
			state <= Sreset;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process;

	-- logica proximo estado
	next_state <= Sready when (state = Sreset) else
								SstartBit when (state = Sready and thrHasData = '1') else
								Sload when (state = SstartBit) else
								S_idle when (state = Sload) else
								S_idle when (state = S_idle and contou15 = '0') else
								SnextBit when (state = S_idle and contou15 = '1' and counted_bits = '0') else
								SparityBit when (state = S_idle and contou15 = '1' and counted_bits = '1' and txConfig(3) = '1') else
								SparityBit when (state = SparityBit and contou15 = '0') else
								SendBit when (state = S_idle and contou15 = '1' and counted_bits = '1' and txConfig(3) = '0') else
								SendBit when (state = SparityBit and contou15 = '1') else
								SendBit when (state = SendBit and contou15 = '0') else
								Sready when (state = SendBit and contou15 = '1') else
								S_idle when (state = SnextBit) else
								state;

	tsrControl <= "001" when state = SstartBit else
								"010" when state = SnextBit else
								"011" when state = SendBit else
								"100" when state = SparityBit and txConfig(4) = '1' else
								"101" when state = SparityBit and txConfig(4) = '0' else
								"000";

	lsrBits(1) <= thrHasData;
	lsrBits(0) <= '1' when state = Sready and thrHasData = '0' else '0';

	lsrControl <= lsrBits;
	
end architecture;
