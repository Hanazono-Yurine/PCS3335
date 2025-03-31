library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmissorDebug is
	port (
		clock, reset: in std_logic;
		serialOut: out std_logic;

		--debug
		clk9600Out: out std_logic
	);
end entity;

architecture rtl of transmissorDebug is

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
	signal clock9600: std_logic := '1';

	--fsm
    type state_type is (Sload, Sdesloca);
    signal state, next_state: state_type := Sload;

begin

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
        clock  => clock,
        reset  => reset,
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

	sig_desloca <= '1' when counterDeslocaOut = "10010" else
		'0'; 
	en_desloca <= '0' when counterDeslocaOut = "10010" else
		'1';  

	-- process padrao de procimo estado da fsm
	process(clock9600, reset)
	begin
		if reset = '1' then
		state <= Sload;
		elsif rising_edge(clock9600) then
			state <= next_state;
		end if;
	end process;

	-- logica proximo estado
	next_state <=
		Sdesloca when (state = Sload) else
		Sload when (state = Sdesloca and sig_desloca = '1') else
		state;

		sig_regControl <= "11" when state = Sload else "01";
		reset_desloca <= '0' when state = Sdesloca else '1';

	clock9600 <= counterClkDiv16(3);
	clk9600Out <= clock9600;
	
    serialOut <= sig_serialOut;

end architecture;