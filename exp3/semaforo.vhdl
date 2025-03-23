library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity semaforo is
	port (
				clk, reset : in std_logic;
				vermelho, amarelo, verde : out std_logic
		 );
end semaforo;

architecture arch_semaforo of semaforo is
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

	signal clk1024 : std_logic := '0';
	signal clk1024_up : std_logic := '1';
	signal clk1800_up : std_logic := '1';
	signal clk1800 : std_logic := '0';
	signal clk1800_reset : std_logic := '0';
	signal clk1024_reset : std_logic := '0';
	signal counter1024_o : std_logic_vector( 10 downto 0 ) := (others => '0');
	signal counter1800_o : std_logic_vector( 10 downto 0 ) := (others => '0');
	signal state : std_logic_vector( 11 downto 0 ) := "100000000000";
begin
	counter1024 : counter
	generic map (
		WIDTH => 11
	)
	port map (
		clock => clk,
		reset => clk1024_reset,
		enable => '1',
		load => '0',
		up => clk1024_up,
		data_i => ( others => '0' ),
		data_o => counter1024_o
	);

	counter1800 : counter
	generic map (
		WIDTH => 11
	)
	port map (
		clock => clk1024,
		reset => clk1800_reset,
		enable => '1',
		load => '0',
		up => clk1800_up,
		data_i => ( others => '0' ),
		data_o => counter1800_o
	);

	process(clk, reset)
		-- Verifica se e o primeiro ciclo
		variable firstRun : bit := '1';
	begin
		
		-- Se reset for apertado
		-- Coloca clk1024_up como 1, já que o contador resetado fica como 0000...
		-- E set fisrtRun como 1 para que o clock nao flipe na instantaneamente
		if ( reset = '1' ) then
			clk1024 <= '0';
			clk1024_reset <= '1';
			clk1024_up <= '1';
			firstRun := '1';
		elsif ( counter1024_o(10) = '1' ) then
			-- Basicamente fica alternando entre contar de 0 até 1024
			-- e depois de 1024 até 0
			-- Se chegar a 1024 ou 0 (excluindo o primeiro ciclo) flipa o clock
			clk1024 <= not clk1024;
			clk1024_up <= '0';
			firstRun := '0';
		elsif ( counter1024_o = "00000000000" and firstRun = '0' ) then
			clk1024 <= not clk1024;
			clk1024_up <= '1';
		else
			clk1024_reset <= '0';
		end if;

	end process;

	process(clk1024, reset)
		variable firstRun : bit := '1';
	begin
		
		if ( reset = '1' ) then
			clk1800 <= '0';
			clk1800_reset <= '1';
			clk1800_up <= '1';
			firstRun := '1';
		elsif ( counter1800_o = "11100001000" ) then
			clk1800 <= not clk1800;
			clk1800_up <= '0';
			firstRun := '0';
		elsif ( counter1800_o = "00000000000" and firstRun = '0' ) then
			clk1800 <= not clk1800;
			clk1800_up <= '1';
		else
			clk1800_reset <= '0';
		end if;

	end process;

	process(clk1800, reset)
	begin

		if ( reset = '1' ) then
			state <= "000000010000";
		elsif ( rising_edge(clk1800) ) then
			state <= state(0) & state(11 downto 1);
		end if;

	end process;


	verde <= not (state(11) or state(10) or state(9) or state(8) or state(7));
	amarelo <= not (state(6) or state(5));
	vermelho <= not (state(4) or state(3) or state(2) or state(1) or state(0));

end architecture;
