library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard4x4 is
	port (
		clock, reset: in std_logic := '0';
		c : out std_logic_vector(3 downto 0);
		l : in std_logic_vector(3 downto 0);
		ascii : out std_logic_vector(6 downto 0); -- ASCII da tecla presionda
		isPressed : out std_logic := '0' -- acho que nao precisa disso, depois tiro
	);
end entity;

architecture rtl of keyboard4x4 is

	-- ========================================= COMPONENTS ================================

	component shiftregisterKeyboard is
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

	signal reg_left_output: std_logic := '0';
	signal reg_c : std_logic_vector(3 downto 0);

	signal ascii_input : std_logic_vector(6 downto 0) := (others => '1');
	--signal leds_debug : std_logic_vector(7 downto 0);

begin

	-- ============================================= INSTANCES =============================================


	--clock <= clock1_8MHz;

	loop_reg: shiftregisterKeyboard
    generic map (
      WIDTH => 4
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => reg_left_output,
      loadOrShift => "01",
      data_i      => (others => '0'),
      data_o      => reg_c,
      serial_o_r  => reg_left_output,
      serial_o_l  => open
    );

	c <= reg_c;

	ascii <=  "0110111" when reg_c(0) = '0' and l(0) = '0' else -- 7
			            "0111000" when reg_c(1) = '0' and l(0) = '0' else -- 8
			            "0111001" when reg_c(2) = '0' and l(0) = '0' else -- 9
			            "1000001" when reg_c(3) = '0' and l(0) = '0' else -- A (OP 1)
			            "0110100" when reg_c(0) = '0' and l(1) = '0' else -- 4
			            "0110101" when reg_c(1) = '0' and l(1) = '0' else -- 5
			            "0110110" when reg_c(2) = '0' and l(1) = '0' else -- 6
			            "1000010" when reg_c(3) = '0' and l(1) = '0' else -- B (OP 2)
			            "0110001" when reg_c(0) = '0' and l(2) = '0' else -- 1
			            "0110010" when reg_c(1) = '0' and l(2) = '0' else -- 2
			            "1001111" when reg_c(2) = '0' and l(2) = '0' else -- 3
			            "1000100" when reg_c(3) = '0' and l(2) = '0' else -- D (OP 3)
			            "1000011" when reg_c(0) = '0' and l(3) = '0' else -- C 
			            "0110000" when reg_c(1) = '0' and l(3) = '0' else -- 0
			            "1000101" when reg_c(2) = '0' and l(3) = '0' else -- E
			            "1001000" when reg_c(3) = '0' and l(3) = '0' else -- H (OP 4)
			            "1111111"; -- nada ta sendo apertado


	--leds_debug <= reg_c & l;

end architecture;
