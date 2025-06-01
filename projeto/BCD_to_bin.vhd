library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- converter BCD de 5 digitos COM sinal (1 bit de sinal + 5 * 4bits de cada digito BCD) para binario SIGNED(complemeto de 2) de 18bits
-- +99.999 -> 01 1000 0110 1001 1111
-- -99.999 -> 10 0111 1001 0110 0001
entity BCD_to_bin is
	port (
        bcd_in : in  std_logic_vector(20 downto 0);
        bin_out : out  std_logic_vector(17 downto 0) := (others => '0')
	);
end entity;

architecture rtl of BCD_to_bin is

	-- ========================================= COMPONENTS ================================	

    component BCD_to_bin_UNSIGNED is
        Port ( 
            bcd_in : in  std_logic_vector (19 downto 0);
            bin_out : out  std_logic_vector (16 downto 0) := (others => '0')
            );
    end component;


	-- ============================================= SIGNAL =============================================

    signal bin_out_UNSIGNED : std_logic_vector(16 downto 0) := (others => '0');
    signal binWithSignalBit: std_logic_vector(17 downto 0) := (others => '0');
    signal minusBin : signed(35 downto 0) := (others => '0');
    signal MINUS_ONE, binSigned : signed(17 downto 0) := (others => '0');
    
	
begin

	-- ============================================= LOGIC =============================================

    -- converte o BCD sem sinal pra binario sem sinal
    bcd_2_bin_UNSIGNED_inst: entity work.BCD_to_bin_UNSIGNED
     port map(
        bcd_in => bcd_in(19 downto 0), -- bcd sem o sinal
        bin_out => bin_out_UNSIGNED
    );

	
    -- converte binario sem sinal pra com sinal(complemeto de 2)
    binWithSignalBit <= "0" & bin_out_UNSIGNED;

    MINUS_ONE <= (others => '1');

    minusBin <= signed(binWithSignalBit) * MINUS_ONE;
    binSigned <= signed(binWithSignalBit) when (bcd_in(20) = '0') else
                 minusBin(17 downto 0); -- os restante dos bits (33 downto 18) eh tudo 1 pq o numero eh negativo em complemento de 2, entao posso ignorar

    bin_out <= std_logic_vector(binSigned);
	

end architecture;
