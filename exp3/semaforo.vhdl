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
	signal clk13_reset : std_logic := '0';
	signal clk1800_reset : std_logic := '0';
	signal clk1024_reset : std_logic := '0';
	signal counter1024_o : std_logic_vector( 10 downto 0 );
	signal counter1800_o : std_logic_vector( 10 downto 0 );
	signal counter13_o : std_logic_vector( 3 downto 0 );
	signal leds : std_logic_vector( 2 downto 0 ) := "100";
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

	counter13 : counter
	generic map (
		WIDTH => 4
	)
	port map (
		clock => clk1800,
		reset => clk13_reset,
		enable => '1',
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counter13_o
	);

	process(clk1800, reset)
	begin

		if ( reset = '1' ) then
		end if;

		if ( counter1024_o = "10000000000" ) then
			clk1024 <= not clk1024;
		end if;

		if ( counter1800_o = "11100001000" ) then
			clk1800 <= not clk1800;
		end if;

		if ( counter13_o = "0101" or counter13_o = "0111" or counter13_o = "1101" ) then
			leds <= leds(0) & leds(2 downto 1);
		end if;

	end process;

	clk13_reset <= '1' when counter13_o = "1101" or reset = '1' else '0';
	clk1800_reset <= '1' when clk1800 = '1' or reset = '1' else '0';
	clk1024_reset <= '1' when clk1024 = '1' or reset = '1' else '0';

	vermelho <= leds(0);
	amarelo <= leds(1);
	verde <= leds(2);

end architecture;
