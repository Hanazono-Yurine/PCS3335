library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- mode 3 : permite vizualizar os valores armazenados na pilha

entity mode3 is
	port (
		clock, reset : in std_logic := '0';

        mode3Selected : in std_logic := '0'; -- pra saber se esse modo tem que ta funcionando (ta selecionado)
        mode3Exit : out std_logic := '0'; -- pra entidade calculator saber quando tem que sair desse modo

		ascii : in std_logic_vector(6 downto 0); -- ASCII da tecla presionda

        ledsmode3 : out std_logic_vector (7 downto 0);

        memoryDataInMode3 : out std_logic_vector (20 downto 0); -- valor que vou escrever na memoria (4 bits pra cada digito) * 5 + 1 bit pro sinal
        memoryDataOut : in std_logic_vector (20 downto 0); -- valor que to lendo da memoria
        memPosMode3 : out integer := 0;
        wrMode3 : out std_logic := '0';

        stackSizeOut : in std_logic_vector (3 downto 0); -- saida do valor do registrador stackSize; registrador stackSize armazena a quantidade numeros na memoria
        stackSizeInMode3 : out std_logic_vector (3 downto 0);
        stackSizeLoadMode3 : out std_logic := '0'; -- faz o load do valor de stackSizeInMode1 no registrador
		
        --valores ASCII de cada display
		display7seg1mode3 : out std_logic_vector (6 downto 0);
        display7seg2mode3 : out std_logic_vector (6 downto 0);
        display7seg3mode3 : out std_logic_vector (6 downto 0);
        display7seg4mode3 : out std_logic_vector (6 downto 0);
        display7seg5mode3 : out std_logic_vector (6 downto 0);
        display7seg6mode3 : out std_logic_vector (6 downto 0)
	);
end entity;

architecture rtl of mode3 is

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
