library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity hex2seg is
	port ( hex : in  std_logic_vector(3 downto 0); -- Entrada binaria
		seg : out std_logic_vector(6 downto 0)  -- Saída hexadecimal
		-- A saída corresponde aos segmentos gfedcba nesta ordem. Cobre 
		-- todos valores possíveis de entrada.
	);
end hex2seg;

architecture comportamental of hex2seg is
begin
	seg(6 downto 0) <=
		"1000000" when HEX="0000" else --0
		"1001111" when HEX="0001" else --1
		"0100100" when HEX="0010" else --2
		"0110000" when HEX="0011" else --3
		"0011001" when HEX="0100" else --4
		"0010010" when HEX="0101" else --5
		"0000010" when HEX="0110" else --6
		"1111000" when HEX="0111" else --7
		"0000000" when HEX="1000" else --8
		"0010000" when HEX="1001" else --9
		"0001000" when HEX="1010" else --A
		"0000011" when HEX="1011" else --b
		"1000110" when HEX="1100" else --C
		"0100001" when HEX="1101" else --d
		"0000110" when HEX="1110" else --E
		"0001110" when HEX="1111" else --F
		"0000000";       
end comportamental;
