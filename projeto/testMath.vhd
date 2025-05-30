library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testMath is
	port (
		clock50M, reset: in std_logic := '0';

		c : out std_logic_vector(3 downto 0);
        l : in std_logic_vector(3 downto 0);

        leds : out std_logic_vector (9 downto 0);

		goToMenu : in std_logic := '0';
		
		display7seg1 : out std_logic_vector (6 downto 0);
        display7seg2 : out std_logic_vector (6 downto 0);
        display7seg3 : out std_logic_vector (6 downto 0);
        display7seg4 : out std_logic_vector (6 downto 0);
        display7seg5 : out std_logic_vector (6 downto 0);
        display7seg6 : out std_logic_vector (6 downto 0)
	);
end entity;

architecture rtl of testMath is

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

	component ascii2seg is
		port (
			off : in std_logic;
			asc : in std_logic_vector(6 downto 0);
			seg : out std_logic_vector(6 downto 0);
			dot : out std_logic
			);
			  
	end component;

    component keyboard4x4 is
		port (
			clock, reset: in std_logic := '0';
			c : out std_logic_vector(3 downto 0);
			l : in std_logic_vector(3 downto 0);
			ascii : out std_logic_vector(6 downto 0);
			isPressed : out std_logic := '0'
		);
    end component;

	component bcd_2_bin is
		Port ( bcd_in_0 : in  STD_LOGIC_VECTOR (3 downto 0);
			bcd_in_10 : in  STD_LOGIC_VECTOR (3 downto 0);
			bcd_in_100 : in  STD_LOGIC_VECTOR (3 downto 0);
			bcd_in_1000 : in  STD_LOGIC_VECTOR (3 downto 0);
			bin_out : out  STD_LOGIC_VECTOR (13 downto 0) := (others => '0'));
	end component;

	component bin_to_BCD is
		port (
			i_Clock  : in std_logic;
			i_Start  : in std_logic;
			i_Binary : in std_logic_vector(14-1 downto 0);
			
			o_BCD : out std_logic_vector(4*4-1 downto 0);
			o_DV  : out std_logic
			);
	end component;

	component bcd_asciiConverter is
        port (
            ascii_i : in std_logic_vector(6 downto 0); 
            bcd_i : in std_logic_vector(3 downto 0); 

            ascii_o : out std_logic_vector(6 downto 0); 
            bcd_o : out std_logic_vector(3 downto 0) 
        );
    end component;

	-- ============================================= SIGNAL =============================================

	--clock divisor
	constant CLOCK_DIVISOR_VALUE : integer := 12;
	signal clockDivisorValue: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(CLOCK_DIVISOR_VALUE,16));

	-- clocks
	signal clock1_8MHz, clock: std_logic := '1';


	-- displays 7 seg
	signal ascii_input1, ascii_input2, ascii_input3, ascii_input4, ascii_input5, ascii_input6 : std_logic_vector (6 downto 0);


	signal bin1, bin2, binResult : std_logic_vector(13 downto 0) := (others => '0') ;
	signal BCDResult : std_logic_vector(15 downto 0) := (others => '0') ;

	signal ascii_o0, ascii_o1, ascii_o2, ascii_o3, ascii_o4, ascii_o5 : std_logic_vector (6 downto 0);

	signal start, done: std_logic := '0';

	-- ============================================= FSM STATES =============================================
    type state_type is (S_start, S_wait, S_done);
    signal state, next_state: state_type := S_start;

begin

	-- ============================================= FSM PROCESS =============================================
	-- process padrao de proximo estado da fsm
	fsm: process(clock, reset)
	begin
		if reset = '1' then
			state <= S_start;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process;
    
	next_state <=
		S_wait   when (state = S_start) else 
		S_wait   when (state = S_wait and done = '0')   else
		S_done   when (state = S_wait and done = '1')   else	
		state;

	start <= '1' when state = S_start else '0';
		

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
        divisor   => std_logic_vector(to_unsigned(1,16)),
        --divisor   => (others => '1'),
        baudOut_n => clock
	);

	--clock <= clock1_8MHz;

	 -- 0058 + 0893 = 0951 = 001110110111
	 -- 0058 = 0000 0000 0101 1000
	 -- 0893 = 0000 1000 1001 0011 
	 -- 

    bcd_2_bin_inst0: entity work.bcd_2_bin
	 port map(
		bcd_in_0 => "1000",
		bcd_in_10 => "0101",
		bcd_in_100 => "0000",
		bcd_in_1000 => "0000",
		bin_out => bin1
	);

	bcd_2_bin_inst1: entity work.bcd_2_bin
	 port map(
		bcd_in_0 => "0011",
		bcd_in_10 => "1001",
		bcd_in_100 => "1000",
		bcd_in_1000 => "0000",
		bin_out => bin2
	);

	binResult <= std_logic_vector( unsigned(bin1) + unsigned(bin2) );

	leds <= binResult(9 downto 0); -- 1110110111


	bin_to_BCD_inst: entity work.bin_to_BCD
	 port map(
		i_Clock => clock,
		i_Start => start,
		i_Binary => binResult,
		o_BCD => BCDResult,
		o_DV => done
	);

	-- exibir conteudo do data_temp nos displays
    bcd_asciiConverter_inst0: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => BCDResult(3 downto 0),
        ascii_o => ascii_o0,
        bcd_o => open
    );

    bcd_asciiConverter_inst1: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => BCDResult(7 downto 4),
        ascii_o => ascii_o1,
        bcd_o => open
    );

    bcd_asciiConverter_inst2: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => BCDResult(11 downto 8),
        ascii_o => ascii_o2,
        bcd_o => open
    );

    bcd_asciiConverter_inst3: bcd_asciiConverter
    port map(
        ascii_i => "0000000",
        bcd_i => BCDResult(15 downto 12),
        ascii_o => ascii_o3,
        bcd_o => open
    );

	-- displays 7 seg
	ascii_input1 <= ascii_o0; -- S

	ascii_input2 <= ascii_o1; -- E
					
	ascii_input3 <= ascii_o2; -- L

	ascii_input4 <= ascii_o3; -- E

	ascii_input5 <= "1111111" ; -- C

	ascii_input6 <= "1111111" ; -- T



	ascii2seg_inst1: ascii2seg
	port map(
		off => '0',
		asc => ascii_input1, 
		seg => display7seg1,
		dot => open
	);

    ascii2seg_inst2: ascii2seg
	port map(
		off => '0',
		asc => ascii_input2, 
		seg => display7seg2,
		dot => open
	);

    ascii2seg_inst3: ascii2seg
	port map(
		off => '0',
		asc => ascii_input3, 
		seg => display7seg3,
		dot => open
	);

    ascii2seg_inst4: ascii2seg
	port map(
		off => '0',
		asc => ascii_input4, 
		seg => display7seg4,
		dot => open
	);

    ascii2seg_inst5: ascii2seg
	port map(
		off => '0',
		asc => ascii_input5, 
		seg => display7seg5,
		dot => open
	);

    ascii2seg_inst6: ascii2seg
	port map(
		off => '0',
		asc => ascii_input6, 
		seg => display7seg6,
		dot => open
	);
	

end architecture;
