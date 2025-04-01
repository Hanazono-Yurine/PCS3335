library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitter is
	port (
		clock, reset: in std_logic;
		serialOut: out std_logic
	);
end entity;
