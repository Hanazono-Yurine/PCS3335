library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitterTimingControl is
	port (
		clock, reset	: in std_logic;
		go                  : in std_logic := '0';
		txConfig            : in std_logic_vector(6 downto 0);
		reg_loadOrShift     : out std_logic_vector(1 downto 0);
		readyLed            : out std_logic
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

	--fsm
	type state_type is (Sreset, Sload, S_idle, SnextBit, Sready);
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
	totalBitsTX <= std_logic_vector(to_unsigned(  7, 5 )) when txConfig(0) = '0' and txConfig(1) = '0' and txConfig(3) = '0' else
								 std_logic_vector(to_unsigned(  8, 5 )) when txConfig(0) = '0' and txConfig(1) = '1' and txConfig(3) = '0' else
								 std_logic_vector(to_unsigned(  9, 5 )) when txConfig(0) = '1' and txConfig(1) = '0' and txConfig(3) = '0' else
								 std_logic_vector(to_unsigned( 10, 5 )) when txConfig(0) = '1' and txConfig(1) = '1' and txConfig(3) = '0' else
								 std_logic_vector(to_unsigned(  8, 5 )) when txConfig(0) = '0' and txConfig(1) = '0' and txConfig(3) = '1' else
								 std_logic_vector(to_unsigned(  9, 5 )) when txConfig(0) = '0' and txConfig(1) = '1' and txConfig(3) = '1' else
								 std_logic_vector(to_unsigned( 10, 5 )) when txConfig(0) = '1' and txConfig(1) = '0' and txConfig(3) = '1' else
								 std_logic_vector(to_unsigned( 11, 5 )) when txConfig(0) = '1' and txConfig(1) = '1' and txConfig(3) = '1';

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

	contou15 <= '1' when counter15_out = STD_LOGIC_VECTOR(to_unsigned(14,4)) else
		'0'; 
	counter15_en <= '0' when counter15_out = STD_LOGIC_VECTOR(to_unsigned(14,4)) else
		'1';  

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
	next_state <= Sload when (state = Sreset) else
								S_idle when (state = Sload and go = '1') else
								S_idle when (state = S_idle and contou15 = '0') else
								SnextBit when (state = S_idle and contou15 = '1' and counted_bits = '0') else
								Sready when (state = S_idle and contou15 = '1' and counted_bits = '1') else
								Sready when (state = Sready and go = '1') else
								Sload when (state = Sready and go = '0') else
								S_idle when (state = SnextBit) else
								state;

	-- oq fazer em cada estado
	sig_regControl <= "11" when state = Sload and go = '1' else 
										"00" when state = S_idle else
										"01" when state = SnextBit else
										"00";

	counter15_reset <= '0' when state = S_idle else '1';

	readyLed <= '1' when state = Sready else '0';
	
	reg_loadOrShift <= sig_regControl;

end architecture;
