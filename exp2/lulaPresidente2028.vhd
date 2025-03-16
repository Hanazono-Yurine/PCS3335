library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;
use ieee.numeric_bit.rising_edge;

entity lulaPresidente2028 is
	generic (
			WIDTH : natural := 8 -- Size in bits
	);
	port (
			counter_clock, clock, reset, counter_enable, counter_load, serial_i, counter_up : in std_logic;
			loadOrShift : in std_logic_vector( 1 downto 0 );
			-- data_i : in std_logic_vector( WIDTH-1 downto 0 );
			data_o, data_counter_o : out std_logic_vector( WIDTH-1 downto 0 );
			serial_o_r, serial_o_l : out std_logic
	);
end lulaPresidente2028;

architecture calanguinho of lulaPresidente2028 is

	component counter is
		generic (
				WIDTH : natural := 8 -- Size in bits
		);
		port (
				clock, reset, enable, load, up : in std_logic;
				data_i : in std_logic_vector( WIDTH-1 downto 0 );
				data_o : out std_logic_vector( WIDTH-1 downto 0 )
		);
	end component;

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

	signal data_counter_o_temp : std_logic_vector( WIDTH-1 downto 0 );
	signal data_register_o_temp : std_logic_vector( WIDTH-1 downto 0 );
begin

	triplex : counter port map(
							clock => counter_clock,
							reset => reset,
							enable => counter_enable,
							load => counter_load,
							up => counter_up,
							data_i => data_register_o_temp,
							data_o => data_counter_o_temp
					);

	mensalao : shiftregister port map(
							clock => clock,
							reset => reset,
							serial_i => serial_i,
							loadOrShift => loadOrShift,
							data_i => data_counter_o_temp,
							data_o => data_register_o_temp,
							serial_o_l => serial_o_l,
							serial_o_r => serial_o_r
					);

	data_counter_o <= data_counter_o_temp;
	data_o <= data_register_o_temp;

end architecture;
