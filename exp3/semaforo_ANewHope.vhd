library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_bit.all;
use ieee.numeric_std.all;

entity semaforo is
	port (
        clk50MHz, reset: in std_logic;
        vermelho, amarelo, verde : out std_logic;

        --debugging ports
        leds : out std_logic_vector(9 downto 0);
        seg0, seg1, seg2: out std_logic_vector(6 downto 0);
        clock1Hz_out, clk1_8MHz_out: out std_logic := '0'
		);
end entity;

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

    component hex2seg is
		port ( hex : in  std_logic_vector(3 downto 0); -- Entrada binaria
			 seg : out std_logic_vector(6 downto 0)  -- Saída hexadecimal
		);
	end component;
		
    component ip_pll_50MHz is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         --  locked.export
        );
    end component;

    --debugging signals
    signal sig_leds : std_logic_vector(9 downto 0) := (others => '0');
    signal sig_seg0, sig_seg1, sig_seg2, sig_seg3 : std_logic_vector(6 downto 0) := (others => '0');

    signal clk1_8MHz: std_logic := '0';
    signal clock1Hz: std_logic := '0';

    signal counterOut_verde, counterOut_amarelo, counterOut_vermelho : std_logic_vector(2 downto 0) := (others => '0');
    signal counterOut_1Hz : std_logic_vector(23 downto 0) := (others => '0');
    signal counterReset_verde, counterReset_amarelo, counterReset_vermelho, counterReset_1Hz: std_logic := '1';
    signal sig_verde, sig_amarelo, sig_vermelho, sig_reset, sig_clock1Hz: std_logic := '0';
    signal out_verde, out_amarelo, out_vermelho: std_logic := '0';
    signal en_verde, en_amarelo, en_vermelho: std_logic := '1';
    

    --fsm
    type state_type is (Sverde, Samarelo, Svermelho, Sreset);
    signal state, next_state: state_type := Sverde;
	
begin

    --ip_pll
    baka: ip_pll_50MHz
    port map (
        refclk   => clk50MHz,
        rst      => '0',
        outclk_0 => clk1_8MHz
    );

    counter1Hz : counter
	generic map (
		WIDTH => 24
	)
	port map (
		clock => clk1_8MHz,
		reset => counterReset_1Hz,
		enable => '1',
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut_1Hz
	);
    
        --000111000010000000000000 1s
        --000011100001000000000000 0.5s
    counterReset_1Hz <= '1' when counterOut_1Hz = "000011100001000000000001" else -- contar ate 000111000010000000000000 num clock de 1843200 Hz significa passar 1s
        '0';

    sig_clock1Hz <= '1' when counterOut_1Hz = "000011100001000000000000" else '0';

    process(sig_clock1Hz)
    begin
        if rising_edge(sig_clock1Hz) then
            clock1Hz <= not clock1Hz;
        end if;
    end process;


	counterVerde : counter
	generic map (
		WIDTH => 3
	)
	port map (
		clock => clock1Hz,
		reset => counterReset_verde,
		enable => en_verde,
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut_verde
	);

    sig_verde <= '1' when counterOut_verde = "101" else -- contar ate 100011001010000000000000 num clock de 1843200 Hz significa passar 5s
                '0';
    en_verde <= '0' when counterOut_verde = "101" else
        '1';

    
    counterAmarelo : counter
	generic map (
		WIDTH => 3
	)
	port map (
		clock => clock1Hz,
		reset => counterReset_amarelo,
		enable => en_amarelo,
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut_amarelo
	);

    sig_amarelo <= '1' when counterOut_amarelo = "010" else
                '0';
    en_amarelo <= '0' when counterOut_amarelo = "010" else
        '1';


    counterVermelho : counter
	generic map (
		WIDTH => 3
	)
	port map (
		clock => clock1Hz,
		reset => counterReset_vermelho,
		enable => en_vermelho,
		load => '0',
		up => '1',
		data_i => ( others => '0' ),
		data_o => counterOut_vermelho
	);

    sig_vermelho <= '1' when counterOut_Vermelho = "101" else
                    '0'; 
    en_vermelho <= '0' when counterOut_vermelho = "101" else
        '1';   

    -- process padrao de procimo estado da fsm
    process(clock1Hz, reset)
    begin
      if reset = '1' then
        state <= Sreset;
      elsif rising_edge(clock1Hz) then
          state <= next_state;
      end if;
    end process;

    -- Lógica de próximo estado (async combinatorio)
    next_state <=
        Samarelo when (state = Sverde and sig_verde = '1') else
        Svermelho when ((state = Samarelo and sig_amarelo = '1') or state = Sreset) else
        Sverde when ( (state = Svermelho and sig_vermelho = '1')) else
        state;

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

    --debugging
    hex2seg0: hex2seg
	port map (
		hex => "0" & counterOut_verde,
		seg => sig_seg0
	);

	hex2seg1: hex2seg
	port map (
		hex => "0" & counterOut_amarelo,
		seg => sig_seg1
	);

	hex2seg2: hex2seg
	port map (
		hex => "0" & counterOut_vermelho,
		seg => sig_seg2
	);

    sig_leds(0) <= sig_verde;
    sig_leds(1) <= sig_amarelo;
    sig_leds(2) <= sig_vermelho;

    sig_leds(3) <= counterReset_verde;
    sig_leds(4) <= counterReset_amarelo;
    sig_leds(5) <= counterReset_vermelho;

    sig_leds(6) <= sig_reset;

    sig_leds(9) <= clock1Hz;

    leds <= sig_leds;
    seg0 <= sig_seg0;
    seg1 <= sig_seg1;
    seg2 <= sig_seg2;
     
    clock1Hz_out <= clock1Hz;
    clk1_8MHz_out <=  clk1_8MHz;
end architecture;
