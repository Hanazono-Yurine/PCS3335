library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- converter binario SIGNED(complemeto de 2) de 18bits para BCD de 5 digitos COM sinal (1 bit de sinal + 5 * 4bits de cada digito BCD)
-- +99.999 <- 01 1000 0110 1001 1111
-- -99.999 <- 10 0111 1001 0110 0001
entity bin_to_BCD is
	port (
        i_Clock  : in std_logic;
        i_Start  : in std_logic;
        bin_in  : in std_logic_vector(17 downto 0) := (others => '0'); -- binario SIGNED(complemento de 2)

        bcd_out : out std_logic_vector(20 downto 0);
        o_DV  : out std_logic -- ta pronto
	);
end entity;

architecture rtl of bin_to_BCD is

	-- ========================================= COMPONENTS ================================	

    component bin_to_BCD_UNSIGNED is
        port (
            i_Clock  : in std_logic;
            i_Start  : in std_logic;
            i_Binary : in std_logic_vector(16 downto 0); -- binario UNSIGNED

            
            o_BCD : out std_logic_vector(4*5-1 downto 0);
            o_DV  : out std_logic
        );
    end component;


	-- ============================================= SIGNAL ============================================

    signal bcd_out_UNSIGNED : std_logic_vector(19 downto 0) := (others => '0');
    signal binWithSignalBit: std_logic_vector(17 downto 0) := (others => '0');
    signal minusBin : signed(35 downto 0) := (others => '0');
    signal MINUS_ONE, binUnsigned : signed(17 downto 0) := (others => '0');
    
	
begin
	-- ============================================= LOGIC =============================================

    -- converte o binario com sinal pra sem sinal
    MINUS_ONE <= (others => '1');

    minusBin <= signed(bin_in) * MINUS_ONE;
    binUnsigned <= signed(bin_in) when (bin_in(17) = '0') else
                 minusBin(17 downto 0); -- os restante dos bits (33 downto 18) eh tudo 1 pq o numero eh negativo em complemento de 2, entao posso ignorar


    -- converte o binario sem sinal pra BCD sem sinal
    bin_to_BCD_UNSIGNED_inst: entity work.bin_to_BCD_UNSIGNED
     port map(
        i_Clock => i_Clock,
        i_Start => i_Start,
        i_Binary => std_logic_vector(binUnsigned(16 downto 0)),
        o_BCD => bcd_out_UNSIGNED,
        o_DV => o_DV
    );
	
    -- Faz a saida ser um BCD com sinal de acordo com o sinal do binario da entrada
    bcd_out <= "0" & bcd_out_UNSIGNED when (bin_in(17) = '0') else
               "1" & bcd_out_UNSIGNED;

end architecture;
