library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_bit.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity semaforoRaf is
	port (
				clk, reset : in std_logic;
				vermelho, amarelo, verde : out std_logic
		 );
end entity;

architecture arch_semaforoRaf of semaforoRaf is
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

    signal counterOut_verde, counterOut_amarelo, counterOut_vermelho : std_logic_vector(23 downto 0) := (others => '0');
    signal counterReset_verde, counterReset_amarelo, counterReset_vermelho: std_logic := '1';
    signal sig_verde, sig_amarelo, sig_vermelho, sig_reset: std_logic := '0';


    type state_type is (Sverde, Samarelo, Svermelho, Sreset);
    signal state, next_state: state_type := Sverde;

    signal temp: std_logic_vector(1 downto 0) := (others => '0');
	
begin
	counterVerde : counter
	generic map (
		WIDTH => 24
	)
	port map (
		clock => clk,
		reset => counterReset_verde,
		enable => '1',
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut_verde
	);

    sig_verde <= '1' when counterOut_verde = "100011001010000000000000" else
                '0';
    

    
    counterAmarelo : counter
	generic map (
		WIDTH => 24
	)
	port map (
		clock => clk,
		reset => counterReset_amarelo,
		enable => '1',
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut_amarelo
	);

    sig_amarelo <= '1' when counterOut_amarelo = "001110000100000000000000" else
                '0';



    counterVermelho : counter
	generic map (
		WIDTH => 24
	)
	port map (
		clock => clk,
		reset => counterReset_vermelho,
		enable => '1',
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut_vermelho
	);

    sig_vermelho <= '1' when counterOut_Vermelho = "100011001010000000000000" else
                    '0';    

    -- process
    process(sig_vermelho, sig_amarelo, sig_verde, sig_reset, reset)
    begin
      if reset = '1' then
        state <= Sreset;
      elsif sig_vermelho = '1' or sig_amarelo = '1' or sig_verde = '1' or sig_reset = '1' then
        --report "deu sinal" ;
        --temp(0) <= sig_amarelo;
        --report "amarelo = " & integer'image(to_integer(unsigned(temp))) ;
        --temp(0) <= sig_verde;
        --report "verde = " & integer'image(to_integer(unsigned(temp)));
        --temp(0) <= sig_vermelho;
        --report "vermelho = " & integer'image(to_integer(unsigned(temp)));
          state <= next_state;
      end if;
    end process;



    -- Lógica de próximo estado (async combinatorio)
    next_state <=
        Sverde when (state = Svermelho) else
        Samarelo when (state = Sverde) else
        Svermelho when (state = Samarelo or state = Sreset);

    -- oq acontece quando to num estado especifico
    -- verde
    verde <= '1' when state = Sverde else
        '0';
    counterReset_verde <= '0' when state = Sverde else
        '1';

    -- amarelo
    amarelo <= '1' when state = Samarelo else
        '0';
    counterReset_amarelo <= '0' when state = Samarelo else
        '1';

    -- vermelho
    vermelho <= '1' when state = Svermelho else
        '0';
    counterReset_vermelho <= '0' when state = Svermelho else
        '1';

    -- reset
    sig_reset <= '1' when state = Sreset else
        '0';
     

end architecture;
