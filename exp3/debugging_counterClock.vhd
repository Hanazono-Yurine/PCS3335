library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_bit.all;
use ieee.numeric_std.all;

entity debugging_counterClock is
	port (
        clk50MHz, reset_pushBtn : in std_logic;
        leds : out std_logic_vector(9 downto 0);
        seg0, seg1, seg2, seg3, seg4, seg5 : out std_logic_vector(6 downto 0)
		);
end entity;



architecture arch_semaforo of debugging_counterClock is

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
    signal sig_seg0, sig_seg1, sig_seg2, sig_seg3, sig_seg4, sig_seg5 : std_logic_vector(6 downto 0) := (others => '0');


    signal reset: std_logic := '0';
    signal clk: std_logic := '0';

    signal counterOut: std_logic_vector(23 downto 0) := (others => '0');
    signal counterReset: std_logic := '1';
    signal clockMeioHz: std_logic := '0';
	
begin

    --ip_pll
    baka: ip_pll_50MHz
    port map (
        refclk   => clk50MHz,
        rst      => '0',
        outclk_0 => clk
    );


	oniichna : counter
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

    counterReset <= '1' when counterOut= "0001 1100 0010 0000 0000 0001" or reset = '1' else -- 1seg + 1 clock
                '0';
    
    process(counterOut)
    begin
        if counterOut= "000111000010000000000000" then -- 1seg
            clockMeioHz <= not clockMeioHz;
        end if;
    end process;
    
    

    -- push button tem logica negada
    reset <= not reset_pushBtn; 

    --debugging
    hex2seg0: hex2seg
	port map (
		hex => counterOut(23 downto 20),
		seg => sig_seg0
	);

    hex2seg1: hex2seg
	port map (
		hex => counterOut(19 downto 16),
		seg => sig_seg1
	);

    hex2seg2: hex2seg
	port map (
		hex => counterOut(15 downto 12),
		seg => sig_seg2
	);

    hex2seg3: hex2seg
	port map (
		hex => counterOut(11 downto 8),
		seg => sig_seg3
	);

    hex2seg4: hex2seg
	port map (
		hex => counterOut(7 downto 4),
		seg => sig_seg4
	);

    hex2seg5: hex2seg
	port map (
		hex => counterOut(3 downto 0),
		seg => sig_seg5
	);

    sig_leds(0) <= clockMeioHz;


    leds <= sig_leds;
    seg0 <= sig_seg0;
    seg1 <= sig_seg1;
    seg2 <= sig_seg2;
    seg3 <= sig_seg3;
    seg4 <= sig_seg4;
    seg5 <= sig_seg5;
     

end architecture;
