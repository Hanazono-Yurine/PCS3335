library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmissorDebug3 is
	port (
		clock50M, reset, go : in std_logic := '0';
		serialOut, readyLed : out std_logic;

		--debug
		clk9600Out, clockDebug: out std_logic
	);
end entity;

architecture rtl3 of transmissorDebug3 is

	component ip_pll_50MHz is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         --  locked.export
        );
    end component;

	component baudRateGenerator is
		port(
			clock       : in  std_logic;
			reset       : in  std_logic;
			divisor       : in  std_logic_vector(15 downto 0);
			baudOut_n : out std_logic
		);
	end component baudRateGenerator;

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

	component shiftregister is
		generic (
				WIDTH : natural := 8 -- Size in bits
		);
		port (
				clock, reset, serial_i : in std_logic;
				loadOrShift : in std_logic_vector( 1 downto 0 );
				data_i : in std_logic_vector( WIDTH-1 downto 0 );
				data_o : out std_logic_vector( WIDTH-1 downto 0 );
				serial_o_r, serial_o_l : out std_logic
		);
	end component;

	signal sig_serialOut: std_logic := '1';
	signal sig_regControl: std_logic_vector(1 downto 0);
	signal sig_desloca, en_desloca, reset_desloca: std_logic := '0';
	signal counterClkDiv16: std_logic_vector(3 downto 0); 
	signal counterDeslocaOut: std_logic_vector(4 downto 0);
	signal counter15_out: std_logic_vector(3 downto 0);
	signal clock9600, clock1_8MHz, clock153600: std_logic := '1';
	
	signal clocks_rising : std_logic := '0';
	signal clocks_reset : std_logic := '0';

	signal counted_bits, counted_bit, counted_bit_enable : std_logic := '0';

	signal counter15_reset, counter15_en, contou15 : std_logic := '0';

	--fsm
    type state_type is (Sreset, Sload, S_idle, SnextBit, Sready);
    signal state, next_state: state_type := Sload;

begin

	--ip_pll
    baka: ip_pll_50MHz
    port map (
        refclk   => clock50M,
        rst      => '0',
        outclk_0 => clock1_8MHz
    );

	baudrategenerator_inst: baudRateGenerator
	port map (
	  clock     => clock1_8MHz,
	  reset     => '0',
	  divisor   => STD_LOGIC_VECTOR(to_unsigned(12,16)),
	  baudOut_n => clock153600
	);

	reg: shiftregister
    generic map (
      WIDTH => 11
    )
    port map (
      clock       => clock153600,
      reset       => '0',
      serial_i    => '1',
      loadOrShift => sig_regControl,
	  -- 100010101010111111111100011101110111111111100010101010111111111100010111110
      data_i      => "10010000100", --01000010 = A; 01010101 = U 01110111=w 01011111=_ 1111111111=//??
      --data_o      => sig_reg_data_o,
      serial_o_r  => sig_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	counterBits: counter
    generic map (
        WIDTH => 5
    )
    port map (
        clock  => counted_bit,
        reset  => reset_desloca,
        enable => counted_bit_enable,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => counterDeslocaOut
    );

	counted_bit <= '1' when state = SnextBit else '0';
	reset_desloca <= '1' when state = Sload else '0';

	counted_bits <= '1' when counterDeslocaOut = STD_LOGIC_VECTOR(to_unsigned(11,5)) else -- 11010 = 11+15; 11 de enviar 11 bits; 15 de tempo de espera
		'0'; 
	counted_bit_enable <= '0' when counterDeslocaOut = STD_LOGIC_VECTOR(to_unsigned(11,5)) else
		'1';  

	counter15: counter
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => clock153600,
        reset  => counter15_reset,
        enable => counter15_en,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => counter15_out
    );

	contou15 <= '1' when counter15_out = STD_LOGIC_VECTOR(to_unsigned(14,4)) else -- 11010 = 11+15; 11 de enviar 11 bits; 15 de tempo de espera
		'0'; 
	counter15_en <= '0' when counter15_out = STD_LOGIC_VECTOR(to_unsigned(14,4)) else
		'1';  

	-- process padrao de procimo estado da fsm
	process(clock153600, reset)
	begin
		if reset = '1' then
			state <= Sreset;
		elsif rising_edge(clock153600) then
			state <= next_state;
		end if;
	end process;

	-- logica proximo estado
	next_state <=
		Sload when (state = Sreset) else
		S_idle when (state = Sload and go = '1') else
		S_idle when (state = S_idle and contou15 = '0') else
		SnextBit when (state = S_idle and contou15 = '1' and counted_bits = '0') else
		Sready when (state = S_idle and contou15 = '1' and counted_bits = '1') else
		Sready when (state = Sready and go = '1') else
		Sload when (state = Sready and go = '0') else
		S_idle when (state = SnextBit) else
		state;

	-- oq fazer em cada estado
	sig_regControl <= "11" when state = Sload and go = '1' else 
					  "00" when state = S_idle else
					  "01" when state = SnextBit else
					  "00";

	counter15_reset <= '0' when state = S_idle else '1';

	readyLed <= '1' when state = Sready else '0';
	
    serialOut <= sig_serialOut;

end architecture;