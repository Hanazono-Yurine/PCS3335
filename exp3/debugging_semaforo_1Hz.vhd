library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_bit.all;
use ieee.numeric_std.all;

entity debugging_semaforo_1Hz is
	port (
        clk, reset_pushBtn : in std_logic;
        vermelho, amarelo, verde : out std_logic;

        --debugging ports
        leds : out std_logic_vector(9 downto 0);
        seg0, seg1, seg2 : out std_logic_vector(6 downto 0)
		);
end entity;



architecture arch_semaforo of debugging_semaforo is

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

    component hex2seg is
		port ( hex : in  std_logic_vector(3 downto 0); -- Entrada binaria
			 seg : out std_logic_vector(6 downto 0)  -- Saída hexadecimal
		);
	end component;

    --debugging signals
    signal sig_leds : std_logic_vector(9 downto 0) := (others => '0');
    signal sig_seg0, sig_seg1, sig_seg2 : std_logic_vector(6 downto 0) := (others => '0');


    signal reset: std_logic := '0';
    signal clk: std_logic := '0';

    signal counterOut_verde, counterOut_amarelo, counterOut_vermelho : std_logic_vector(4 downto 0) := (others => '0');
    signal counterReset_verde, counterReset_amarelo, counterReset_vermelho: std_logic := '1';
    signal sig_verde, sig_amarelo, sig_vermelho, sig_reset: std_logic := '0';
    signal out_verde, out_amarelo, out_vermelho: std_logic := '0';


    --fsm
    type state_type is (Sverde, Samarelo, Svermelho, Sreset);
    signal state, next_state: state_type := Sverde;
	
begin

	counterVerde : counter
	generic map (
		WIDTH => 4
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

    sig_verde <= '1' when counterOut_verde = "0101" else 
                '0';
    

    
    counterAmarelo : counter
	generic map (
		WIDTH => 4
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

    sig_amarelo <= '1' when counterOut_amarelo = "0010" else
                '0';



    counterVermelho : counter
	generic map (
		WIDTH => 4
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

    sig_vermelho <= '1' when counterOut_Vermelho = "0101" else
                    '0';    

    -- process
    process(sig_vermelho, sig_amarelo, sig_verde, sig_reset, reset)
    begin
      if reset = '1' then
        state <= Sreset;
      elsif sig_vermelho = '1' or sig_amarelo = '1' or sig_verde = '1' or sig_reset = '1' then -- so quero ir pro proximo estado quando os sig_ mudar pra 1, e nao pra 0
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
    out_verde <= '1' when state = Sverde else
        '0';
    counterReset_verde <= '0' when state = Sverde else
        '1';

    -- amarelo
    out_amarelo <= '1' when state = Samarelo else
        '0';
    counterReset_amarelo <= '0' when state = Samarelo else
        '1';

    -- vermelho
    out_vermelho <= '1' when state = Svermelho or state = Sreset else -- colocar state = Sreset pra quando estiver apertando o reset ficar vermelho
        '0';
    counterReset_vermelho <= '0' when state = Svermelho else
        '1';

    -- reset
    sig_reset <= '1' when state = Sreset else
        '0';

    verde <= not out_verde;
    amarelo <= not out_amarelo;
    vermelho <= not out_vermelho;

    -- push button tem logica negada
    reset <= not reset_pushBtn; 

    --debugging
    hex2seg0: hex2seg
	port map (
		hex => counterOut_verde(23 downto 20),
		seg => sig_seg0
	);

	hex2seg1: hex2seg
	port map (
		hex => counterOut_amarelo(23 downto 20),
		seg => sig_seg1
	);

	hex2seg2: hex2seg
	port map (
		hex => counterOut_vermelho(23 downto 20),
		seg => sig_seg2
	);

    sig_leds(0) <= sig_verde;
    sig_leds(1) <= sig_amarelo;
    sig_leds(2) <= sig_vermelho;

    sig_leds(3) <= counterReset_verde;
    sig_leds(4) <= counterReset_amarelo;
    sig_leds(5) <= counterReset_vermelho;

    sig_leds(6) <= sig_reset;

    leds <= sig_leds;
    seg0 <= sig_seg0;
    seg1 <= sig_seg1;
    seg2 <= sig_seg2;
     

end architecture;
