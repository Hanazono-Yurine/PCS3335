library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- modo 1 :le o tecla apertada, mostra no display o valor do numero que esta sendo digitado,
-- numero de 5 digitos + 1 sinal
-- quando aperta E armazena o valor digitado no topo da pilha
-- quando aperta C deleta o ultimo digito do numero que esta sendo digitado

entity bcd_asciiConverter is
	port (
		ascii_i : in std_logic_vector(6 downto 0); 
        bcd_i : in std_logic_vector(3 downto 0); 

        ascii_o : out std_logic_vector(6 downto 0); 
        bcd_o : out std_logic_vector(3 downto 0) 
	);
end entity;

architecture rtl of bcd_asciiConverter is

	-- ========================================= COMPONENTS ================================	


	-- ============================================= SIGNAL =============================================

	
begin

	-- ============================================= INSTANCES =============================================
	
    ascii_o <= "0110000" when bcd_i = "0000" else -- 0
        "0110001" when bcd_i = "0001" else -- 1
        "0110010" when bcd_i = "0010" else -- 2
        "0110011" when bcd_i = "0011" else -- 3
        "0110100" when bcd_i = "0100" else -- 4
        "0110101" when bcd_i = "0101" else -- 5
        "0110110" when bcd_i = "0110" else -- 6
        "0110111" when bcd_i = "0111" else -- 7
        "0111000" when bcd_i = "1000" else -- 8
        "0111001" when bcd_i = "1001" else -- 9
        "0000000";

    bcd_o <= "0000" when ascii_i = "0110000" else 
        "0001" when ascii_i = "0110001" else 
        "0010" when ascii_i = "0110010" else 
        "0011" when ascii_i = "0110011" else 
        "0100" when ascii_i = "0110100" else 
        "0101" when ascii_i = "0110101" else 
        "0110" when ascii_i = "0110110" else 
        "0111" when ascii_i = "0110111" else 
        "1000" when ascii_i = "0111000" else 
        "1001" when ascii_i = "0111001" else 
        "0000";

end architecture;
