library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
	port (
		A: in std_logic_vector(2 downto 0); -- seletor de registrador
		-- A = "000" and LCR_bit7 = '0' -> Dout <= RBR e Din => THR
		-- A = "011" -> Din => LCR
		-- A = "101" -> Dout <= LSR
		-- A = "000" and LCR_bit7 = '1' -> latchDivisor_LS <= Din   Divisor Latch (least significant byte)
		-- A = "001" and LCR_bit7 = '1' -> latchDivisor_MS <= Din   Divisor Latch (most significant byte)

		notADS : in std_logic := '0'; -- address strobe
		-- notADS = '0' -> atualiza os valores de A (os seletores sao amostrados) 
		-- notADS = '1' -> mantem os valores de A (os seletores NAO sao amostrados) 

		notBAUDOUT : out std_logic := '0'; -- notBAUDOUT <= baudRateGenerator

		Din: in std_logic_vector(7 downto 0); -- dados input
		-- somente utiliza os dados de Din pra escrever em um registrador quando WR = '1'
		Dout: out std_logic_vector(7 downto 0); -- dados OUTPUT

		MR : in std_logic := '0'; -- master reset

		RD : in std_logic := '0'; -- read
		-- RD = '1' and A = "000" -> RBR_read <=  '1'
		-- RD = '1' and A = "101" -> resetLSR_bits1_3 <=  '1'

		notRXRDY : out std_logic := '0'; -- notRXRDY <= not LSR_bit0

		SIN : in std_logic := '1'; -- serialIn <= SIN
		SOUT : out std_logic := '1'; -- SOUT <= serialOut

		notTXRDY : out std_logic := '0';  -- notRXRDY <= not LSR_bit6

		WR  : in std_logic := '0'; -- write

		XIN: in std_logic := '0'; -- XIN <= clock do IP-PLL (1.8432 MHz)
		RCLK : in std_logic := '0'; -- RCLK deve recever por fora da UART o valor de notBAUDOUT

		RBR_onlyDataBitsOut, THR_data: out std_logic_vector(7 downto 0)
		

		--clock50M, reset: in std_logic := '0';
		--serialOut: out std_logic;
		--serialIn: in std_logic;
		--display7seg : out std_logic_vector(6 downto 0);
		--RBR_read : in std_logic := '0';
		--switches: in std_logic_vector(9 downto 0);
		--leds: out std_logic_vector(9 downto 0);
		--resetLSR_bits1_3 : in std_logic := '0';
	);
end entity;

architecture rtl of uart is

	-- ========================================= COMPONENTS ================================	

	component baudRateGenerator is
		port(
			clock : in  std_logic;
			reset : in  std_logic;
			divisor : in  std_logic_vector(15 downto 0);
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
			THR_dataOut : out std_logic_vector(7 downto 0);
            --debug
            leds: out std_logic_vector(9 downto 0)
        );
    end component;

	component receiver is
		port (
			clock, reset: in std_logic := '0';
			LCR_out: in std_logic_vector(7 downto 0); 
			serialIn: in std_logic;
	
			--RSR_data : out std_logic_vector(9 downto 0); -- valor completo armazenado no RSR
			--RSR_data8Bits : out std_logic_vector(7 downto 0); -- apenas os bit data recebidos com 0 nos mais sig
			LSR_bit2PE : out std_logic := '0';
	
			leds: out std_logic_vector(9 downto 0); -- ledsReceiverFSM
	
			RBR_read : in std_logic;
			RBR_data : out std_logic_vector(9 downto 0);
			RBR_onlyDataBits : out std_logic_vector(7 downto 0); -- apenas os bit data recebidos com 0 nos mais sig
	
			LSR_out : in std_logic_vector(7 downto 0); 
			LSR_bit0, LSR_bit1, LSR_bit3 : out std_logic := '0';
			resetLSR_bits1_3 : in std_logic := '0';
			toContando : out std_logic
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

	-- EXP 7

	signal RBR_data: std_logic_vector(9 downto 0);
	--signal RBR_onlyDataBits: std_logic_vector(7 downto 0);

	--signal stateIsfinish, stateIsStopBit, stateIsErroStopBit : std_logic := '0';
	signal LSR_bit0, LSR_bit1, LSR_bit3  : std_logic := '0';

	signal LSR_load: std_logic_vector(1 downto 0) := "00";

	signal receivedAllStopBits : std_logic;

	signal toContando : std_logic := '0';

	-- EXP8

	signal THR_in : std_logic_vector(7 downto 0);
	signal THR_load : std_logic := '0';
	signal THR_dataOut : std_logic_vector(7 downto 0);
	signal RBR_onlyDataBits : std_logic_vector(7 downto 0);

	signal reset: std_logic := '0';
	signal serialOut: std_logic;
	signal serialIn: std_logic;
	signal RBR_read : std_logic := '0';
	signal leds:  std_logic_vector(9 downto 0);
	signal resetLSR_bits1_3 : std_logic := '0';

begin

	-- ============================================= INSTANCES =============================================

	baudrategenerator_inst: baudRateGenerator
	port map (
	  clock     => clock1_8MHz,
	  reset     => '0',
	  --divisor   => std_logic_vector(to_unsigned(12,16)),
	  divisor   => LD_MS_out & LD_LS_out,
	  baudOut_n => clock
	);

	-- ************************************* REGISTERS

	latchDivisor_MS: shiftregister
	generic map (
	  WIDTH => 8
	)
	port map (
	  clock       => clock,
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
	  clock       => clock,
	  reset       => reset,
	  serial_i    => '0',
	  loadOrShift => "11",
	  data_i      => clockDivisorValue(7 downto 0),
	  data_o      => LD_LS_out,
	  serial_o_r  => open,
	  serial_o_l  => open
	);

	LCR: shiftregister ------------------------------ LCR - Line Control Register
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

	LSR: shiftregister ---------------------------- LSR - Line Status Register
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


	transmitter_inst: transmitter ---------------------------- transmitter
	port map (
		clock        => clock,
		reset        => reset,
		load         => THR_load,
		LCR_out      => LCR_out,
		THR_in       => THR_in,
		LSR_bit5THRE => LSR_bit5THRE,
		LSR_bit6TEMT => LSR_bit6TEMT,
		serialOut    => serialOut,
		THR_dataOut => THR_dataOut,
		leds         => ledsTransmitterFSM
	);

	receiver_inst: receiver ---------------------------------- receiver
	port map (
		clock         => clock,
		reset         => reset,
		LCR_out       => LCR_out,
		serialIn      => serialIn,
		LSR_bit2PE    => LSR_bit2PE,
		leds          => ledsReceiverFSM,
		RBR_read      => RBR_read,
		RBR_data => RBR_data,
		RBR_onlyDataBits => RBR_onlyDataBits,
		LSR_out => LSR_out,
		LSR_bit0 => LSR_bit0,
		LSR_bit1 => LSR_bit1,
		LSR_bit3 => LSR_bit3,
		resetLSR_bits1_3 => resetLSR_bits1_3,
		toContando => toContando
	);

	LSR_load <= "11";


	-- EXP8

	Dout <= 
		RBR_onlyDataBits when A = "000" and LCR_out(7) = '0' else 
		LSR_out when A = "101" else 
		"00000000";
	
	THR_in <= Din;
	THR_load <= '1' when A = "000" and WR = '1' else '0';	
			
	LCR_in <= Din;
	LCR_load <= "11" when A = "011" and WR = '1' else "00";

	-- por enquanto vou pular a escrita nos Lacth reg

	-- vou pular o notADS

	notBAUDOUT <= clock;

	reset <= MR;

	RBR_read <=  '1' when RD = '1' and A = "000" else '0';
	resetLSR_bits1_3 <= '1' when RD = '1' and A = "101" else '0';

	notRXRDY <= not LSR_out(0);

	SOUT <= serialOut;
 	serialIn <= SIN;

	notTXRDY <= not LSR_out(6);
		
	clock1_8MHz <= XIN;
	
	RBR_onlyDataBitsOut <= RBR_onlyDataBits;
	
	THR_data <= THR_dataOut;

	

	------------------------------------------ DEBUG

	--leds <= ledsTransmitterFSM;
	--leds <= ledsReceiverFSM;
	--leds <= "00" & LSR_out;
	--leds <= RBR_data;


end architecture;