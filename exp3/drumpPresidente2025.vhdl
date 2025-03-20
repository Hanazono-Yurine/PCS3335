library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity drumpPresidente2025 is
	port (
		clk, reset : in std_logic;
		-- Na ordem, vermelho, amarelo, verde
		canada, mexico, greenland : out std_logic
	);
end drumpPresidente2025;

architecture tariff of drumpPresidente2025 is
	component semaforo is
		port (
			clk, reset : in std_logic;
			vermelho, amarelo, verde : out std_logic
		);
	end component;

	-- Na ordem, vermelho, amarelo, verde
	signal canada51stState, fentanyl, eggs : std_logic;
begin
	canada51state : semaforo
	port map (
		clk => clk,
		reset => reset,
		vermelho => canada51stState,
		amarelo => fentanyl,
		verde => eggs
	);
end architecture;
