library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitterTimingControl is
	port (
		clock9600, reset: in std_logic;
		reg_loadOrShift: out std_logic
	);
end entity;

architecture rtl of transmitterTimingControl is

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

    --fsm
    type state_type is (Sload, Sdesloca, Sreset);
    signal state, next_state: state_type := Sload;

    signal sig_desloca, en_desloca, reset_desloca: std_logic := '0';
    signal counterDeslocaOut: std_logic_vector(4 downto 0);
    signal sig_regControl: std_logic_vector(1 downto 0);

begin

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

        reg_loadOrShift <= sig_regControl;
    
end architecture;