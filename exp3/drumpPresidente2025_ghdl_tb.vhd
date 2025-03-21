library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity drumpPresidente2025_ghdl_tb is end;

architecture deportation_tb of drumpPresidente2025_ghdl_tb is
	component drumpPresidente2025_ghdl is
		port (
			clk1, reset1 : in std_logic;
			vermelho1, amarelo1, verde1 : out std_logic
		);
	end component;

	constant period : time := 542.5347222222 ns;
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';

	signal vrm : std_logic := '0';
	signal arm : std_logic := '0';
	signal vrd : std_logic := '0';

begin

	clk <= not clk after period/2;

	canada51state : drumpPresidente2025_ghdl
	port map (
		clk1 => clk,
		reset1 => reset,
		vermelho1 => vrm,
		amarelo1 => arm,
		verde1 => vrd
	);

	tb : process is
			variable vrd_lock : bit := '1';
			variable arm_lock : bit := '1';
			variable vrm_lock : bit := '1';
		begin

			if ( vrd = '0' and vrd_lock = '1' ) then
				report "Verde";
				vrd_lock := '0';
				arm_lock := '1';
			end if;

			if ( arm = '0' and arm_lock = '1' ) then
				report "Amarelo";
				arm_lock := '0';
				vrm_lock := '1';
			end if;

			if ( vrm = '0' and vrm_lock = '1' ) then
				report "Vermelho";
				vrd_lock := '1';
				vrm_lock := '0';
			end if;

			wait for 1 ms;
		end process;
end architecture;
