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
		up => '1',
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
		up => '1',
		data_i => ( others => '0' ),
		data_o => counter1800_o
	);

	process(clk)
	begin

		--if ( counter1024_o(10) = '1' ) then
		if ( counter1024_o = "01111111111" ) then
			clk1024 <= not clk1024;
		end if;

	end process;

	process(clk1024)
	begin
		--if ( counter1800_o = "11100001000" ) then
		if ( counter1800_o = "11100000111" ) then
			clk1800 <= not clk1800;
		end if;

	end process;

	process(clk1800, reset)
	begin

		if ( reset = '1' ) then
			state <= "100000000000";
		elsif ( rising_edge(clk1800) ) then
			state <= state(0) & state(11 downto 1);
		end if;

	end process;

	clk1800_reset <= '1' when clk1800 = '1' or reset = '1' else '0';
	clk1024_reset <= '1' when clk1024 = '1' or reset = '1' else '0';

	vermelho <= not (state(11) or state(10) or state(9) or state(8) or state(7));
	amarelo <= not (state(6) or state(5));
	verde <= not (state(4) or state(3) or state(2) or state(1) or state(0));

end architecture;
