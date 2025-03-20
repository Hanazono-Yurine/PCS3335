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

	signal clk13_reset : std_logic := '0';
	signal counter13_o : std_logic_vector( 3 downto 0 ) := (others => '0');
	signal leds : std_logic_vector( 2 downto 0 ) := "100";
begin
	counter13 : counter
	generic map (
		WIDTH => 4
	)
	port map (
		clock => clk,
		reset => clk13_reset,
		enable => '1',
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counter13_o
	);

	process(clk)
	begin

		-- Desloca leds pra direita, uma vez só, se counter13_o = 5, 8, 13
		if ( counter13_o = "0101" and leds(2) = '1' ) then
			leds <= leds(0) & leds(2 downto 1);
		elsif ( counter13_o = "1000" and leds(1) = '1' ) then
			leds <= leds(0) & leds(2 downto 1);
		elsif ( counter13_o = "0000" and leds(0) = '1' ) then
			leds <= leds(0) & leds(2 downto 1);
		end if;

	end process;

	clk13_reset <= '1' when counter13_o = "1100" or reset = '1' else '0';

	vermelho <= leds(0);
	amarelo <= leds(1);
	verde <= leds(2);

end architecture;
