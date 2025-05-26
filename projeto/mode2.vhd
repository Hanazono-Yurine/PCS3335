library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--le o tecla apertada pra selecionar uma operacao
-- realiza a operacao entre os 2 numeros no topo da pilha, remove eles, e armazena o resultado no topo da pilha
-- sempre mostra nos displays o valor do topo da pilha

entity mode2 is
	port (
		clock, reset : in std_logic := '0';

		ascii : in std_logic_vector(6 downto 0); -- ASCII da tecla presionda

        ledsmode2 : out std_logic_vector (7 downto 0);

        memoryDataInMode2 : out std_logic_vector (20 downto 0); -- valor que vou escrever na memoria (4 bits pra cada digito) * 5 + 1 bit pro sinal
        memoryDataOut : in std_logic_vector (20 downto 0); -- valor que to lendo da memoria
        memPosMode2 : out integer := 0;
        wrMode2 : out std_logic := '0';

        -- contador stackSizeCounter conta quando numeros foram armazenados na memoria(pilha)
        stackSizeCounterValue : in std_logic_vector (3 downto 0); -- saida do valor do contador stackSize
        stackSizeCounterClockMode2 : out std_logic := '0'; -- controla o clock do stackSizeCounter quando esse modo eh o ativo
        stackSizeCounterUpMode2 : out std_logic := '1'; -- controla o sentido do stackSizeCounter('1' -> aumenta; '0' -> diminui)r
		
        --valores ASCII de cada display
		display7seg1mode2 : out std_logic_vector (6 downto 0);
        display7seg2mode2 : out std_logic_vector (6 downto 0);
        display7seg3mode2 : out std_logic_vector (6 downto 0);
        display7seg4mode2 : out std_logic_vector (6 downto 0);
        display7seg5mode2 : out std_logic_vector (6 downto 0);
        display7seg6mode2 : out std_logic_vector (6 downto 0)
	);
end entity;

architecture rtl of mode2 is

	-- ========================================= COMPONENTS ================================	
	component shiftregister is
		generic (
				WIDTH : natural := 8 -- Size in bits
		);
		port (
				clock, reset, serial_i : in std_logic;
				loadOrShift : in std_logic_vector( 1 downto 0 );
				data_i : in std_logic_vector( WIDTH-1 downto 0 );
				data_o : out std_logic_vector( WIDTH-1 downto 0 );
				serial_o_r, serial_o_l : out std_logic
		);
	end component;


	-- ============================================= SIGNAL =============================================

	
begin

	-- ============================================= INSTANCES =============================================
	
    

end architecture;
