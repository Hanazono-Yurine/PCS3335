library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmissorDebug is
	port (
		clock50M, reset: in std_logic;
		serialOut: out std_logic;

		--debug
		clk9600Out: out std_logic
	);
end entity;

architecture rtl of transmissorDebug is

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
	signal clock9600, clock1_8MHz, clock153600: std_logic := '1';

	--fsm
    type state_type is (Sload, Sdesloca, Sreset);
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
	  reset     => reset,
	  divisor   => "0000000000001100",
	  baudOut_n => clock153600
	);

	reg: shiftregister
    generic map (
      WIDTH => 11
    )
    port map (
      clock       => clock9600,
      reset       => reset,
      serial_i    => '1',
      loadOrShift => sig_regControl,
      data_i      => "10010000100",
      --data_o      => sig_reg_data_o,
      serial_o_r  => sig_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	clockDiv16: counter
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => clock153600,
        reset  => '0',
        enable => '1',
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => counterClkDiv16
    );

	counterDesloca: counter
    generic map (
        WIDTH => 5
    )
    port map (
        clock  => clock9600,
        reset  => reset_desloca,
        enable => en_desloca,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => counterDeslocaOut
    );

	sig_desloca <= '1' when counterDeslocaOut = "11010" else -- 11010 = 11+15; 11 de enviar 11 bits; 15 de tempo de espera
		'0'; 
	en_desloca <= '0' when counterDeslocaOut = "11010" else
		'1';  

	-- process padrao de procimo estado da fsm
	process(clock9600, reset)
	begin
		if reset = '1' then
			state <= Sreset;
		elsif rising_edge(clock9600) then
			state <= next_state;
		end if;
	end process;

	-- logica proximo estado
	next_state <=
		Sload when (state = Sreset) else
		Sdesloca when (state = Sload) else
		Sdesloca when (state = Sdesloca and sig_desloca = '0') else
		Sload when (state = Sdesloca and sig_desloca = '1') else
		state;

	-- oq fazer em cada estado
		sig_regControl <= "11" when state = Sload else 
						"01" when state = Sdesloca else
						"00" when state = Sreset;

		reset_desloca <= '0' when state = Sdesloca else '1';

	clock9600 <= counterClkDiv16(3);
	clk9600Out <= clock9600;
	
    serialOut <= sig_serialOut;

end architecture;