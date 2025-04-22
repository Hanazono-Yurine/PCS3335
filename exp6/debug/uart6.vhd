library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart6 is
	port (
		clock50M, reset: in std_logic := '0';
		serialOut: out std_logic;

        -- exp 6
        serialIn: in std_logic;
        display7seg : out std_logic_vector(6 downto 0);

		--debug
		scope: out std_logic;
        switches: in std_logic_vector(9 downto 0);
        leds: out std_logic_vector(9 downto 0)
	);
end entity;

architecture rtl of uart6 is

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

    component transmitter is
        port (
            clock, reset: in std_logic := '0';
            -- load : load no THR e comeca a transmissao
            load : in std_logic := '0';
            LCR_out : in std_logic_vector(7 downto 0); 
            THR_in : in std_logic_vector(7 downto 0);
    
            serialOut: out std_logic;
            --debug
            scope: out std_logic;
            leds: out std_logic_vector(9 downto 0)
        );
    end component;

    component receiver is
        port (
            clock, reset: in std_logic := '0';
            LCR_out, LSR_out: in std_logic_vector(7 downto 0); 
            serialIn: in std_logic;
    
            RSR_data: out std_logic_vector(9 downto 0);
			leds: out std_logic_vector(9 downto 0)
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

	-- Registers parallel input and output
	signal LCR_out, LSR_out: std_logic_vector(7 downto 0); 
	signal LCR_in: std_logic_vector(7 downto 0) := "0" & "0" & "011" & "0" & "11"; -- Divisor Latch Access & Break & Parity & BitStop & Character Length
	-- Registers load or shit
	signal  LCR_load: std_logic_vector(1 downto 0) := "00";
	-- Registers serial input and output
	signal sig_scope: std_logic := '1';

    

	signal load: std_logic := '0';
	signal load_DataInLCR: std_logic := '0';

    -- exp 6
    signal RSR_out : std_logic_vector(9 downto 0) := (others => '1');
    signal RSR_L_or_S: std_logic_vector(1 downto 0) := "00";
    signal sig_display7seg : std_logic_vector(6 downto 0);
	signal RSR_data: std_logic_vector(9 downto 0);
	signal sig_leds: std_logic_vector(9 downto 0);

    -- leds para debug da FSM
    signal ledsTransmitterFSM, ledsReceiverFSM: std_logic_vector(9 downto 0);

begin

	-- ============================================= INSTANCES =============================================
	--ip_pll
    ip_pll: ip_pll_50MHz
    port map (
        refclk   => clock50M,
        rst      => '0',
        outclk_0 => clock1_8MHz
    );

	-- ************************************* REGISTERS
	latchDivisor_MS: shiftregister
	generic map (
	  WIDTH => 8
	)
	port map (
	  clock       => clock1_8MHz,
	  reset       => reset,
	  serial_i    => '0',
	  loadOrShift => "11",
	  data_i      => clockDivisorValue(15 downto 8),
	  data_o      => LD_MS_out
	  --serial_o_r  => serial_o_r,
	  --serial_o_l  => serial_o_l
	);

	latchDivisor_LS: shiftregister
	generic map (
	  WIDTH => 8
	)
	port map (
	  clock       => clock1_8MHz,
	  reset       => reset,
	  serial_i    => '0',
	  loadOrShift => "11",
	  data_i      => clockDivisorValue(7 downto 0),
	  data_o      => LD_LS_out
	  --serial_o_r  => serial_o_r,
	  --serial_o_l  => serial_o_l
	);

	baudrategenerator_inst: baudRateGenerator
	port map (
	  clock     => clock1_8MHz,
	  reset     => '0',
	  --divisor   => std_logic_vector(to_unsigned(12,16)),
	  divisor   => LD_MS_out & LD_LS_out,
	  baudOut_n => clock
	);

	LCR: shiftregister -- Line Control Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => '1',
      loadOrShift => LCR_load,
      data_i      => LCR_in, 
	  --data_i      => "0" & "0" & "011" & "0" & "11", -- Divisor Latch Access & Break & Parity & BitStop & Character Length
      data_o      => LCR_out
      --serial_o_r  => sig_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	LSR: shiftregister -- Line Status Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => '1',
      loadOrShift => "11",
      data_i      => "00000000",
      data_o      => LSR_out
      --serial_o_r  => 
      --serial_o_l  => sig_reg_serial_o_l
    );


    transmitter_inst: transmitter
    port map (
      clock     => clock,
      reset     => reset,
      load      => load,
      LCR_out   => LCR_out,
      THR_in    => switches(7 downto 0),
      serialOut => serialOut,
      scope     => sig_scope,
      leds      => ledsTransmitterFSM
    );
	
	LCR_load <= "11" when load_DataInLCR = '1' else "00" ;

	LCR_in <= switches(7 downto 0);

	load_DataInLCR <= switches(8);
	load <= switches(9);


  -- ======================================================= EXP 6 ============================================================
    
    receiver_inst: receiver
    port map (
      clock       => clock,
      reset       => reset,
      LCR_out     => LCR_out,
      LSR_out     => LSR_out,
      serialIn    => serialIn,
      RSR_data    => RSR_data,
	  leds        => ledsReceiverFSM
    );

	ascii2seg_inst: ascii2seg
	 port map(
		off => '0',
		asc => RSR_data(7 downto 1),
		seg => sig_display7seg
		--dot => dot
	);

    display7seg <= sig_display7seg;

    ------------------------------------------ DEBUG

	scope <= sig_scope;

    --leds <= ledsTransmitterFSM;
    leds <= ledsReceiverFSM;

end architecture;