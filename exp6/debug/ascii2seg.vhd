library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ascii2seg is
    port (
		off : in std_logic;
		asc : in std_logic_vector(6 downto 0);
		seg : out std_logic_vector(6 downto 0);
		dot : out std_logic
        );
		  
end ascii2seg;

architecture comportamental of ascii2seg is

	signal seg_temp : std_logic_vector(6 downto 0);
	
begin
    seg_temp(6 downto 0) <=
		"0000000" when asc="0100000" else -- space
		"0000110" when asc="0100001" else -- !
		"0100010" when asc="0100010" else -- "
		"1111110" when asc="0100011" else -- #
		"1101101" when asc="0100100" else -- $
		"1010010" when asc="0100101" else -- %
		"1000110" when asc="0100110" else -- &
		"0100000" when asc="0100111" else -- '
		"0101001" when asc="0101000" else -- (
		"0001011" when asc="0101001" else -- )
		"0100001" when asc="0101010" else -- *
		"1110000" when asc="0101011" else -- +
		"0010000" when asc="0101100" else -- ,
		"1000000" when asc="0101101" else -- -
		"0000000" when asc="0101110" else -- .
		"1010010" when asc="0101111" else -- /
		"0111111" when asc="0110000" else -- 0
		"0000110" when asc="0110001" else -- 1
		"1011011" when asc="0110010" else -- 2
		"1001111" when asc="0110011" else -- 3
		"1100110" when asc="0110100" else -- 4
		"1101101" when asc="0110101" else -- 5
		"1111101" when asc="0110110" else -- 6
		"0000111" when asc="0110111" else -- 7
		"1111111" when asc="0111000" else -- 8
		"1101111" when asc="0111001" else -- 9
		"0001001" when asc="0111010" else -- :
		"0001101" when asc="0111011" else -- ;
		"1100001" when asc="0111100" else -- <
		"1001000" when asc="0111101" else -- =
		"1000011" when asc="0111110" else -- >
		"1010011" when asc="0111111" else -- ?
		"1011111" when asc="1000000" else -- @
		"1110111" when asc="1000001" else -- A
		"1111100" when asc="1000010" else -- B
		"0111001" when asc="1000011" else -- C
		"1011110" when asc="1000100" else -- D
		"1111001" when asc="1000101" else -- E
		"1110001" when asc="1000110" else -- F
		"0111101" when asc="1000111" else -- G
		"1110110" when asc="1001000" else -- H
		"0110000" when asc="1001001" else -- I
		"0011110" when asc="1001010" else -- J
		"1110101" when asc="1001011" else -- K
		"0111000" when asc="1001100" else -- L
		"0010101" when asc="1001101" else -- M
		"0110111" when asc="1001110" else -- N
		"0111111" when asc="1001111" else -- O
		"1110011" when asc="1010000" else -- P
		"1101011" when asc="1010001" else -- Q
		"0110011" when asc="1010010" else -- R
		"1101101" when asc="1010011" else -- S
		"1111000" when asc="1010100" else -- T
		"0111110" when asc="1010101" else -- U
		"0111110" when asc="1010110" else -- V
		"0101010" when asc="1010111" else -- W
		"1110110" when asc="1011000" else -- X
		"1101110" when asc="1011001" else -- Y
		"1011011" when asc="1011010" else -- Z
		"0111001" when asc="1011011" else -- [
		"1100100" when asc="1011100" else -- \
		"0001111" when asc="1011101" else -- ]
		"0100011" when asc="1011110" else -- ^
		"0001000" when asc="1011111" else -- _
		"0000010" when asc="1100000" else -- `
		"1011111" when asc="1100001" else -- a
		"1111100" when asc="1100010" else -- b
		"1011000" when asc="1100011" else -- c
		"1011110" when asc="1100100" else -- d
		"1111011" when asc="1100101" else -- e
		"1110001" when asc="1100110" else -- f
		"1101111" when asc="1100111" else -- g
		"1110100" when asc="1101000" else -- h
		"0010000" when asc="1101001" else -- i
		"0001100" when asc="1101010" else -- j
		"1110101" when asc="1101011" else -- k
		"0110000" when asc="1101100" else -- l
		"0010100" when asc="1101101" else -- m
		"1010100" when asc="1101110" else -- n
		"1011100" when asc="1101111" else -- o
		"1110011" when asc="1110000" else -- p
		"1100111" when asc="1110001" else -- q
		"1010000" when asc="1110010" else -- r
		"1101101" when asc="1110011" else -- s
		"1111000" when asc="1110100" else -- t
		"0011100" when asc="1110101" else -- u
		"0011100" when asc="1110110" else -- v
		"0010100" when asc="1110111" else -- w
		"1110110" when asc="1111000" else -- x
		"1101110" when asc="1111001" else -- y
		"1011011" when asc="1111010" else -- z
		"1000110" when asc="1111011" else -- {
		"0110000" when asc="1111100" else -- |
		"1110000" when asc="1111101" else -- }
		"0000001" when asc="1111110" else -- ~
		"0000000" when asc="1111111" else -- del
		"0000000"; 

				
		seg <= not seg_temp when off = '0' else "0000000";
					
end comportamental;