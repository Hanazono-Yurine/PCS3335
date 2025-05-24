library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    generic(
        size : natural := 16;     -- armazena 16 numeros
        wordSize : natural := 21  -- (4 bits pra cada digito) * 5 + 1 bit pro sinal
    );
    port(
        clk, wr : in  std_logic;
        pos : in integer;
        data_i : in  std_logic_vector(wordSize-1 downto 0);
        data_o : out std_logic_vector(wordSize-1 downto 0)
    );
end entity;

architecture rtl of memory is

    type ram is array (0 to size-1) of std_logic_vector(wordSize-1 downto 0) ;

    signal memoria_ram: ram ;

begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if (wr='1') then
                memoria_ram(pos) <= data_i;
            end if;
        end if;
    end process;

    data_o <= memoria_ram(pos);
end architecture;