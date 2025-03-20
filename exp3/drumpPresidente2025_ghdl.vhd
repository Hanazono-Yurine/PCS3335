library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity drumpPresidente2025_ghdl is
	port (
		clk1, reset1 : in std_logic;
		vermelho1, amarelo1, verde1 : out std_logic
	);
end drumpPresidente2025_ghdl;

architecture deportation of drumpPresidente2025_ghdl is
	component semaforo is
		port (
			clk, reset : in std_logic;
			vermelho, amarelo, verde : out std_logic
		);
	end component;
begin
	canada51state : semaforo
	port map (
		clk => clk1,
		reset => reset1,
		vermelho => vermelho1,
		amarelo => amarelo1,
		verde => verde1
	);
end architecture;
