library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity semaforoRaf_1Hz_tb is
end entity;

architecture tb_1Hz of semaforoRaf_1Hz_tb is
  
  -- Componente a ser testado (Device Under Test -- DUT)
    component semaforoRaf_1Hz is
        port (
                    clk, reset : in std_logic;
                    vermelho, amarelo, verde : out std_logic
             );
    end component;

  -- Declaração de sinais para conectar a componente
  signal clk_in: std_logic := '0';
  signal dut_verde, dut_amarelo, dut_vermelho, dut_reset: std_logic := '0';

  -- Configurações do clock
  signal keep_simulating : std_logic := '0'; -- delimita o tempo de geração do clock
  constant clockPeriod : time := 1 sec;
  
begin

  clk_in <= (not clk_in) and keep_simulating after clockPeriod/2;
  

  dut: semaforoRaf_1Hz port map(
    clk => clk_in,
    reset => dut_reset,
    verde => dut_verde,
    amarelo => dut_amarelo,
    vermelho => dut_vermelho
  );

  ---- Gera sinais de estimulo
  stimulus: process is


  begin

    --======================== process comeca aqui

    assert false report "simulation start" severity note;
    keep_simulating <= '1';

    wait for 15.3 sec;

    
    dut_reset <= '1';
    wait for 100 ns;
    dut_reset <= '0';

    wait for 12 sec;

    
    dut_reset <= '1';
    wait for 100 ns;
    dut_reset <= '0';
          
    
    wait for 6 sec;
    
    -- final do testbench
    assert false report "simulation end" severity note;
    keep_simulating <= '0';
    
    wait; -- fim da simulação: aguarda indefinidamente
  end process;


end architecture;

-- ghdl -a *.vhd
-- ghdl -e onescounter_tb
-- ghdl -r onescounter_tb

