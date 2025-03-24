library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_bit.all;
use ieee.numeric_std.all;

entity semaforoRaf_1counter is
	port (
				clk, reset : in std_logic;
				vermelho, amarelo, verde : out std_logic
		 );
end entity;

architecture arch_semaforoRaf_1counter of semaforoRaf_1counter is
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

    signal counterOut : std_logic_vector(23 downto 0) := (others => '0');
    signal counterReset: std_logic := '1';
    signal sig_verde, sig_amarelo, sig_vermelho, sig_reset, sig_pre: std_logic := '0';
    signal out_verde, out_amarelo, out_vermelho: std_logic := '0';

    type state_type is (SpreVerde, Sverde, SpreAmarelo, Samarelo, SpreVermelho, Svermelho, Sreset);
    signal state, next_state: state_type := Sverde;
	
begin
	c : counter
	generic map (
		WIDTH => 24
	)
	port map (
		clock => clk,
		reset => counterReset,
		enable => '1',
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut
	);

    sig_verde <= '1' when counterOut = "000000000000111001100011" else -- contar ate 000000000000111001100011 num clock de 1843200 Hz significa passar 2ms
                '0';
    

    sig_amarelo <= '1' when counterOut = "000000000000111001100011" else
                '0';


    sig_vermelho <= '1' when counterOut = "000000000000111001100011" else
                    '0';    

    -- process
    process(sig_vermelho, sig_amarelo, sig_verde, sig_reset, reset)
    begin
        if reset = '1' then
            state <= Sreset;
        elsif (sig_vermelho = '1' and state = Svermelho) or (sig_amarelo = '1' and state = Samarelo) or (sig_verde = '1' and state = Sverde) 
        or sig_reset = '1' or sig_pre = '1' then -- so quero ir pro proximo estado so quando os sig_ mudar pra 1, e nao pra 0
            state <= next_state;
        end if;
    end process;



    -- Lógica de próximo estado (async combinatorio)
    next_state <=
        SpreAmarelo when (state = Sverde) else
        Samarelo when (state = SpreAmarelo) else
        SpreVermelho when (state = Samarelo) else
        Svermelho when (state = SpreVermelho or state = Sreset) else
        SpreVerde when (state = Svermelho) else
        SVerde when (state = SpreVerde);

    -- oq acontece quando to num estado especifico
    -- verde
    out_verde <= '1' when state = Sverde else
        '0';
    
    -- amarelo
    out_amarelo <= '1' when state = Samarelo else
        '0';

    -- vermelho
    out_vermelho <= '1' when state = Svermelho or state = Sreset else -- colocar state = Sreset pra quando estiver apertando o reset ficar vermelho
        '0';

    -- reinia contador
    counterReset <= '0' when state = Sverde or state = Svermelho or state = Samarelo else
                    '1'; -- quando estou num estado Spre ou Sreset

    -- reset
    sig_reset <= '1' when state = Sreset else
        '0';

    -- sig_pre : ativa quanto to num estado Spre pra fazer eu sair dele
    sig_pre <= '1' when state = SpreVerde or state = SpreAmarelo or state = SpreVermelho else
                '0';

    verde <= out_verde;
    amarelo <= out_amarelo;
    vermelho <= out_vermelho;
     

end architecture;
