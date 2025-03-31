library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity baudRateGenerator is
	port (
		clock, reset 	: in std_logic;
		divisor 			: in std_logic_vector( 15 downto 0 );
		baudOut_n 		: out std_logic
	);
end baudRateGenerator;

architecture arch_baud of baudRateGenerator is
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

	signal primaryCounter : std_logic_vector( 21 downto 0 );
	signal primaryCounter_o : std_logic_vector( 21 downto 0 );
	signal divisor_full_bit : std_logic_vector( 21 downto 0 ) := (others => '0');
	signal primaryClk : std_logic := '0';
	signal primaryCounter_reset : std_logic := '0';
	signal primaryCounter_up : std_logic := '1';
	signal primaryCounter_out : std_logic := '0';
	constant clockInBits : std_logic_vector( 21 downto 0 ) := "0111000010000000000000";
begin
	primCounter : counter
	generic map (
		WIDTH => 22
	)
	port map (
		clock => clock,
		reset => primaryCounter_reset,
		enable => '1',
		load => '0',
		up => primaryCounter_up,
		data_i => ( others => '0' ),
		data_o => primaryCounter_o
	);

	process(primaryCounter_o, reset)
		-- Verifica se e o primeiro ciclo
		variable firstRun : bit := '1';
	begin
		
		-- Se reset for apertado
		-- Coloca primaryCounter_up como 1, já que o contador resetado fica como 0000...
		-- E set fisrtRun como 1 para que o clock nao flipe na instantaneamente
		if ( reset = '1' ) then
			primaryClk <= '0';
			primaryCounter_reset <= '1';
			primaryCounter_up <= '1';
			firstRun := '1';
		elsif ( primaryCounter_o = primaryCounter ) then
			-- Basicamente fica alternando entre contar de 0 até primaryCounter
			-- e depois de primaryCounter até 0
			-- Se chegar a primaryCounter ou 0, (excluindo o primeiro ciclo), flipa o clock
			primaryClk <= not primaryClk;
			primaryCounter_up <= '0';
			firstRun := '0';
		elsif ( primaryCounter_o = "00000000000" and firstRun = '0' ) then
			primaryClk <= not primaryClk;
			primaryCounter_up <= '1';
		else
			primaryCounter_reset <= '0';
		end if;

	end process;

	process(divisor)
	begin
		primaryCounter <= std_logic_vector(to_unsigned(to_integer(unsigned(clockInBits) / unsigned(divisor_full_bit)),22));
	end process;

	divisor_full_bit( 15 downto 0) <= divisor;

	-- Provavelmente ta errado
	--primaryCounter <= to_unsigned(1843200, 22) / unsigned( divisor_unsig );
	--primaryCounter <= std_logic_vector(to_unsigned(to_integer(unsigned(clockInBits) / unsigned(divisor_full_bit)),22));

	baudOut_n <= primaryClk;

end architecture;
