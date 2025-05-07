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

		rbrRead : in std_logic := '0';
		--debug
		switches: in std_logic_vector(9 downto 0);
		leds: out std_logic_vector(9 downto 0);

		resetLSR_bit1_3 : in std_logic := '0';
		scope1, scope2 : out std_logic := '0'
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

			-- LSR
			LSR_bit5THRE, LSR_bit6TEMT : out std_logic := '1';
    
            serialOut: out std_logic;
            --debug
            leds: out std_logic_vector(9 downto 0)
        );
    end component;

    component receiver is
		port (
			clock, reset: in std_logic := '0';
			LCR_out: in std_logic_vector(7 downto 0); 
			serialIn: in std_logic;
	
			RSR_data : out std_logic_vector(9 downto 0); -- valor completo armazenado no RSR
			RSR_data8Bits : out std_logic_vector(7 downto 0); -- apenas os bit data recebidos com 0 nos mais sig
			LSR_bit2PE : out std_logic := '0';
			leds: out std_logic_vector(9 downto 0);
			RBR_lido : in std_logic;
			RBR_load : out std_logic;

			stateIsStopBit : out std_logic;
			stateIsfinish : out std_logic;
			stateIsErroStopBit : out std_logic;
			receivedAllStopBits : out std_logic
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

	component waifusAreTheBestForBufferRegister is
		port (
			clock, load, RBR_read : in std_logic;
			rsrInput : in std_logic_vector(9 downto 0);
			lido : out std_logic;
			rsrOutput : out std_logic_vector(9 downto 0)
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

	-- LSR
	signal LSR_bit5THRE, LSR_bit6TEMT : std_logic := '1';

    

	signal load: std_logic := '0';
	signal load_DataInLCR: std_logic := '0';

	-- exp 6
	signal sig_display7seg : std_logic_vector(6 downto 0);
	signal RSR_data: std_logic_vector(9 downto 0);

	signal LSR_bit2PE: std_logic := '0';
	signal RSR_data8Bits : std_logic_vector(7 downto 0);

	-- leds para debug da FSM
	signal ledsTransmitterFSM, ledsReceiverFSM: std_logic_vector(9 downto 0);

	signal rbrFoiLido, rbrLoad : std_logic := '0';
	signal RBR_data: std_logic_vector(9 downto 0);

	-- EXP 7

	signal stateIsfinish, stateIsStopBit, stateIsErroStopBit : std_logic := '0';
	signal LSR_bit0, LSR_bit1, LSR_bit3  : std_logic := '0';

	signal LSR_load: std_logic_vector(1 downto 0) := "00";






	signal receivedAllStopBits : std_logic;


	signal counter	: unsigned( 15 downto 0 ) := (others => '0');

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

	-- ************************************* REGISTERS
	
	RBR: waifusAreTheBestForBufferRegister
	port map (
		clock     => clock,
		load      => rbrLoad,
		RBR_read  => rbrRead,
		rsrInput  => RSR_data(9 downto 0),
		lido      => rbrFoiLido,
		rsrOutput => RBR_data
	);

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
	  data_o      => LD_MS_out,
	  serial_o_r  => open,
	  serial_o_l  => open
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
	  data_o      => LD_LS_out,
	  serial_o_r  => open,
	  serial_o_l  => open
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
      data_o      => LCR_out,
	  serial_o_r  => open,
	  serial_o_l  => open
    );

	LSR: shiftregister -- Line Status Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => reset,
      serial_i    => '1',
      loadOrShift => LSR_load,
      data_i      => "0" & LSR_bit6TEMT & LSR_bit5THRE & "0" & LSR_bit3 & LSR_bit2PE & LSR_bit1 & LSR_bit0,
      data_o      => LSR_out,
			serial_o_r  => open,
			serial_o_l  => open
    );


	transmitter_inst: transmitter
	port map (
	  clock        => clock,
	  reset        => reset,
	  load         => load,
	  LCR_out      => LCR_out,
	  THR_in       => switches(7 downto 0),
	  LSR_bit5THRE => LSR_bit5THRE,
	  LSR_bit6TEMT => LSR_bit6TEMT,
	  serialOut    => serialOut,
	  leds         => ledsTransmitterFSM
	);
	
	LCR_load <= "11" when load_DataInLCR = '1' else "00" ;

	LCR_in <= switches(7 downto 0);

	load_DataInLCR <= switches(8);
	load <= switches(9);


  -- ======================================================= EXP 6 ============================================================

	receiver_inst: receiver
	port map (
	  clock         => clock,
	  reset         => reset,
	  LCR_out       => LCR_out,
	  serialIn      => serialIn,
	  RSR_data      => RSR_data,
	  RSR_data8Bits => RSR_data8Bits,
	  LSR_bit2PE    => LSR_bit2PE,
	  leds          => ledsReceiverFSM,
		RBR_lido      => rbrFoiLido,
		RBR_load      => rbrLoad,
		stateIsfinish => stateIsfinish,
		stateIsStopBit => stateIsStopBit,
		receivedAllStopBits => receivedAllStopBits,
		stateIsErroStopBit => stateIsErroStopBit
	);

	ascii2seg_inst: ascii2seg
	 port map(
		off => '0',
		--asc => RSR_data(7 downto 1),
		asc => RBR_data(7 downto 1),
		seg => sig_display7seg,
		dot => open
	);

	display7seg <= sig_display7seg;

	------------------------- EXP 7

	LSR_bit0 <= '1' when stateIsfinish = '1' else
				'0' when rbrRead = '1' else
				LSR_out(0);
	
	LSR_bit1 <= '1' when stateIsfinish = '1' and LSR_out(0) = '1' else
				'0' when resetLSR_bit1_3 = '1' else
				LSR_out(1);

	LSR_bit3 <= '1' when stateIsErroStopBit = '1' else
				'0'  when resetLSR_bit1_3 = '1' else
				LSR_out(3);

	LSR_load <= "11";
	--LSR_load <= "11" when stateIsfinish = '1' or rbrRead = '1' or resetLSR_bit1_3 = '1' else
	--			"00";

	------------------------------------------ DEBUG

	--leds <= ledsTransmitterFSM;
	--leds <= ledsReceiverFSM;
	leds <= "00" & LSR_out;
	--leds <= RBR_data;

	scope1 <= serialIn;
	scope2 <= stateIsStopBit;

end architecture;
