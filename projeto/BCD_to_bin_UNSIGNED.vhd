-- codigo base original de:
-- https://vhdlguru.blogspot.com/2015/04/vhdl-code-for-bcd-to-binary-conversion.html
-- modificado por https://github.com/RafaelHipolit

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- converter BCD de 5 digitos SEM sinal (5 * 4bits de cada digito BCD) para binario UNSIGNED
-- 99.999 -> 1 1000 0110 1001 1111
entity BCD_to_bin_UNSIGNED is
    Port ( 
        bcd_in : in  STD_LOGIC_VECTOR (19 downto 0);
        bin_out : out  STD_LOGIC_VECTOR (16 downto 0) := (others => '0')
        );
end BCD_to_bin_UNSIGNED;

architecture Behavioral of BCD_to_bin_UNSIGNED is

    signal bcd_in_0 :     STD_LOGIC_VECTOR (3 downto 0);
    signal bcd_in_10 :    STD_LOGIC_VECTOR (3 downto 0);
    signal bcd_in_100 :   STD_LOGIC_VECTOR (3 downto 0);
    signal bcd_in_1000 :  STD_LOGIC_VECTOR (3 downto 0);
    signal bcd_in_10000 : STD_LOGIC_VECTOR (3 downto 0);

    signal bin_temp : STD_LOGIC_VECTOR (17 downto 0);

begin

    bcd_in_0 <= bcd_in(3 downto 0);
    bcd_in_10 <= bcd_in(7 downto 4);
    bcd_in_100 <= bcd_in(11 downto 8);
    bcd_in_1000 <= bcd_in(15 downto 12);
    bcd_in_10000 <= bcd_in(19 downto 16);

    
    bin_temp <= (bcd_in_0 * "01")  --multiply by 1
                    + (bcd_in_10 * "1010") --multiply by 10
                    + (bcd_in_100 * "1100100") --multiply by 100
                    + (bcd_in_1000 * "1111101000") --multiply by 1000
                    + (bcd_in_10000 * "10011100010000"); --multiply by 10000

    -- valor maximo que essa operacao poderia alcancar:
    -- 1111*1 + 1111*1010 + 1111*1100100 + 1111*1111101000 + 1111*10011100010000 = 10 1000 1011 0000 1001(18bits) = 166.665
    -- valor maximo que essa operacao realmente alcancar:
    -- 1001*1 + 1001*1010 + 1001*1100100 + 1001*1111101000 + 1001*10011100010000 =  1 1000 0110 1001 1111(17bits) = 99.999

    bin_out <= bin_temp(16 downto 0); -- so ignora o ultimo bit

end Behavioral;