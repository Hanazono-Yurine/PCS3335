library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_bit.rising_edge;
use std.textio.all;

entity lulaPresidente2028_tb is end;

architecture test of lulaPresidente2028_tb is

	component lulaPresidente2028 is
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
	end component;

	constant period : time := 20 us;
	signal clk : std_logic := '0';
	constant counter_period : time := 1000 ms;
	signal counter_clk : std_logic := '0';

	signal tb_reset, tb_counter_enable, tb_counter_load, tb_serial_i, tb_counter_up : std_logic;
	signal tb_loadOrShift : std_logic_vector( 1 downto 0 );
	signal tb_data_o, tb_data_counter_o : std_logic_vector( 8-1 downto 0 );
	signal tb_serial_o_r, tb_serial_o_l : std_logic;

begin
	clk <= not clk after period/2;
	counter_clk <= not counter_clk after counter_period/2;

	petismo : lulaPresidente2028 port map (
							counter_clock => counter_clk,
							clock => clk,
							reset => tb_reset,
							counter_enable => tb_counter_enable,
							counter_load => tb_counter_load,
							serial_i => tb_serial_i,
							counter_up => tb_counter_up,
							loadOrShift => tb_loadOrShift,
							data_o => tb_data_o,
							data_counter_o => tb_data_counter_o,
							serial_o_r => tb_serial_o_r,
							serial_o_l => tb_serial_o_l
					);

	tb : process is
		variable basic_test : bit := '0';
	begin
		--! lulaPresidente2028 testbench start
		assert false report "lulaPresidente2028" severity note;

		tb_counter_enable <= '1';
		tb_counter_up <= '1';
		tb_counter_load <= '0';
		tb_reset <= '0';

		wait for 1 ns;

		report "";
		report "=== Counter(+)/Register Test ===";

		for i in 0 to 15 loop
			if ( i = 10 ) then
				tb_loadOrShift <= "11";
				wait for 50 us;
				tb_loadOrShift <= "00";
			end if;

			-- See if this test fails
			if ( unsigned(tb_data_counter_o) /= i ) then
				basic_test := '1';
			end if;

			if ( unsigned(tb_data_counter_o) < 10 and unsigned(tb_data_o) /= 0 ) then
				basic_test := '1';
			elsif ( unsigned(tb_data_counter_o) >= 10 and unsigned(tb_data_o) /= 10 ) then
				basic_test := '1';
			end if;

			if ( basic_test = '1' ) then
				assert false report "[ERROR] - Counter = " & integer'image(to_integer(unsigned(tb_data_counter_o))) & 
				" | Register = " & integer'image(to_integer(unsigned(tb_data_o)));
			else
				report "[OK] - Counter = " & integer'image(to_integer(unsigned(tb_data_counter_o))) & 
				" | Register = " & integer'image(to_integer(unsigned(tb_data_o)));
			end if;

			wait for 1000 ms;
		end loop;

		-- Just making Output more pretty
		if ( basic_test = '1' ) then
			assert false report "=== FAIL ===";
		else
			report "=== PASS ===";
		end if;

		basic_test := '0';

		wait for 5000 ms;

		report "";
		report "=== Counter Load Test ===";

		report "Counter = " & integer'image(to_integer(unsigned(tb_data_counter_o))) & 
		" | Register = " & integer'image(to_integer(unsigned(tb_data_o)));
		report "Loading number from register";
		
		tb_counter_load <= '1';
		wait for 1000 ms;
		tb_counter_load <= '0';

		assert tb_data_counter_o = tb_data_o report "[ERROR] Counter = " & integer'image(to_integer(unsigned(tb_data_counter_o))) & 
		" | Register = " & integer'image(to_integer(unsigned(tb_data_o)));

		if ( tb_data_counter_o /= tb_data_o ) then
			basic_test := '1';
			assert false report "[ERROR]-  Counter = " & integer'image(to_integer(unsigned(tb_data_counter_o))) & 
			" | Register = " & integer'image(to_integer(unsigned(tb_data_o)));
		else
			report "[OK] - Counter = " & integer'image(to_integer(unsigned(tb_data_counter_o))) & 
			" | Register = " & integer'image(to_integer(unsigned(tb_data_o)));
		end if;

		-- Just making Output more pretty
		if ( basic_test = '1' ) then
			assert false report "=== FAIL ===";
		else
			report "=== PASS ===";
		end if;
		basic_test := '0';

		wait;
	end process;

end architecture;
