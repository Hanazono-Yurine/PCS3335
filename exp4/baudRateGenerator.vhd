library  IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity baudRateGenerator is
	port(
		clock     : in  std_logic;
		reset     : in  std_logic;
		divisor		: in  std_logic_vector(15 downto 0);
		baudOut_n : out std_logic
	);
end entity baudRateGenerator;

architecture brg_arch of baudRateGenerator is
	signal counter	: unsigned( 15 downto 0 ) := (others => '0');
	signal clk_out 	: std_logic := '0';
begin

	process(clock, reset)
	begin
		if reset = '1' then
			counter <= (others => '0');
			clk_out <= '1';
		elsif rising_edge(clock) then
			if counter = shift_left(unsigned(divisor), 2) - 1 then
				counter <= (others => '0');
				clk_out <= not clk_out;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;

	baudOut_n <= clk_out;
end brg_arch;
