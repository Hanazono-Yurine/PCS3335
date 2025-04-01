library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitter is
	port (
		clock153600, reset: in std_logic;
		serialOut: out std_logic
	);
end entity;

architecture rtl of transmitter is

    component transmitterTimingControl is
        port (
            clock9600, reset: in std_logic;
            reg_loadOrShift: out std_logic
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

    component baudRateGenerator is
        port(
            clock     : in  std_logic;
            reset     : in  std_logic;
            divisor		: in  std_logic_vector(15 downto 0);
            baudOut_n : out std_logic
        );
    end component;

    signal clock9600, serial: std_logic;
    signal reg_control: std_logic_vector(1 downto 0);

begin

    divClock16: baudRateGenerator
    port map (
      clock     => clock153600,
      reset     => reset,
      divisor   => std_logic_vector(to_unsigned(16,16)),
      baudOut_n => clock9600
    );

    TTC: transmitterTimingControl
    port map (
      clock9600       => clock9600,
      reset           => reset,
      reg_loadOrShift => reg_control
    );

    TSR: shiftregister
    generic map (
      WIDTH => 11
    )
    port map (
      clock       => clock9600,
      reset       => reset,
      serial_i    => '1',
      loadOrShift => reg_control,
      data_i      => "10010000100",
      --data_o      => data_o,
      serial_o_r  => serial
      --serial_o_l  => serial_o_l
    );

    serialOut <= serial;

end architecture;
