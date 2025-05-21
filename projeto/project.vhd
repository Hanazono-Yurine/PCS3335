library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project is
	port (
		clock50M, reset: in std_logic := '0';
		c : out std_logic_vector(3 downto 0);
		sig_display7seg : out std_logic_vector (6 downto 0);
		leds_debug : out std_logic_vector (7 downto 0);
		l : in std_logic_vector(3 downto 0)
	);
end entity;

architecture rtl of project is

	-- ========================================= COMPONENTS ================================	
	component ip_pll_50MHz is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component;

	component baudRateGenerator is
		port(
			clock       : in  std_logic;
			reset       : in  std_logic;
			divisor       : in  std_logic_vector(15 downto 0);
			baudOut_n : out std_logic
		);
	end component baudRateGenerator;

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

	component ascii2seg is
		port (
			off : in std_logic;
			asc : in std_logic_vector(6 downto 0);
			seg : out std_logic_vector(6 downto 0);
			dot : out std_logic
			);
			  
	end component;

	-- ============================================= SIGNAL =============================================

	--lacth divisor
	signal LD_MS_out: std_logic_vector(7 downto 0);
	signal LD_LS_out: std_logic_vector(7 downto 0);
	constant CLOCK_DIVISOR_VALUE : integer := 12;
	signal clockDivisorValue: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(CLOCK_DIVISOR_VALUE,16));

	-- clocks
	signal clock1_8MHz, clock: std_logic := '1';

	signal reg_left_output: std_logic := '0';
	signal reg_c : std_logic_vector(3 downto 0);

	signal ascii_input : std_logic_vector(6 downto 0) := (others => '1');
	--signal leds_debug : std_logic_vector(7 downto 0);

begin

	-- ============================================= INSTANCES =============================================
	--ip_pll
    ip_pll: ip_pll_50MHz
    port map (
        refclk   => clock50M,
        rst      => '0',
        outclk_0 => clock1_8MHz,
		locked => open
    );

	--Low clock just for debugging
	baudrategenerator_inst: baudRateGenerator
	port map (
	  clock     => clock1_8MHz,
	  reset     => '0',
	  --divisor   => std_logic_vector(to_unsigned(12,16)),
	  divisor   => (others => '1'),
	  baudOut_n => clock
	);

	--clock <= clock1_8MHz;

	loop_reg: shiftregister
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

	ascii_input <=  "0110111" when reg_c(0) = '0' and l(0) = '0' else -- 7
			            "0111000" when reg_c(1) = '0' and l(0) = '0' else -- 8
			            "0111001" when reg_c(2) = '0' and l(0) = '0' else -- 9
			            "1000001" when reg_c(3) = '0' and l(0) = '0' else -- A
			            "0110100" when reg_c(0) = '0' and l(1) = '0' else -- 4
			            "0110101" when reg_c(1) = '0' and l(1) = '0' else -- 5
			            "0110110" when reg_c(2) = '0' and l(1) = '0' else -- 6
			            "1000010" when reg_c(3) = '0' and l(1) = '0' else -- B
			            "0110001" when reg_c(0) = '0' and l(2) = '0' else -- 1
			            "0110010" when reg_c(1) = '0' and l(2) = '0' else -- 2
			            "1001111" when reg_c(2) = '0' and l(2) = '0' else -- 3
			            "1000100" when reg_c(3) = '0' and l(2) = '0' else -- D
			            "1000011" when reg_c(0) = '0' and l(3) = '0' else -- C
			            "0110000" when reg_c(1) = '0' and l(3) = '0' else -- 0
			            "1000101" when reg_c(2) = '0' and l(3) = '0' else -- E
			            "1001000" when reg_c(3) = '0' and l(3) = '0' else -- H
			            "1111111"	;

	ascii2seg_inst: ascii2seg
	port map(
		off => '0',
		asc => ascii_input, 
		seg => sig_display7seg,
		dot => open
	);

	leds_debug <= reg_c & l;

end architecture;
