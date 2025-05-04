library  IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity waifusAreTheBestForBufferRegister is
	port (
		clock, load, read : in std_logic;
		rsrInput : in std_logic_vector(9 downto 0);
		lido : out std_logic; -- Não pensei em uma palavra em ingles ;P
		rsrOutput : out std_logic_vector(9 downto 0)
	);
end entity;

architecture RBR of waifusAreTheBestForBufferRegister is

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

	signal rbrLoad : std_logic_vector(1 downto 0) := "00";

begin

    RBR: shiftregister --Receiver Buffer Register
    generic map (
      WIDTH => 10
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => '1',
      loadOrShift => rbrLoad,
      data_i      => rsrInput,
      data_o      => rsrOutput,
      serial_o_r  => open,
      serial_o_l  => open
    );

		rbrLoad <= "11" when load = '1' else "00";

		lido <= read;

end architecture;
