library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart5Debug is
	port (
		clock50M, reset: in std_logic := '0';
		load: in std_logic := '0';
		THR_data : in std_logic_vector(7 downto 0);
		serialOut: out std_logic;

		--debug
		clock1_8MHzDebug, clockDebug: out std_logic
	);
end entity;

architecture rtl of uart5Debug is

	# ========================================= COMPONENTS ================================	
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

	# ============================================= SIGNAL =============================================

	--lacth divisor
	signal LD_MS_out: std_logic_vector(7 downto 0);
	signal LD_LS_out: std_logic_vector(7 downto 0);
	constant CLOCK_DIVISOR_VALUE : integer := 12;
	signal clockDivisorValue: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(CLOCK_DIVISOR_VALUE,16));

	-- clocks
	signal clock1_8MHz, clock: std_logic := '1';

	-- Registers parallel input and output
	signal THR_out, TSR_in, TSR_out, LCR_in, LCR_out, LSR_in, LSR_out: std_logic := std_logic_vector(7 downto 0);
	-- Registers load or shit
	signal THR_load, TSR_L_or_S: std_logic_vector(1 downto 0) := "00";
	-- Registers serial input and output
	signal TSR_serialOut: std_logic := '1';

	-- MUX serial Output Control
	signal serialOutControl : std_logic_vector(1 downto 0) := "00"; 
	-- 00 => BIT_STOP
	-- 01 => TSR_out
	-- 01 => break
	-- 11 => 

	-- counters values
	signal valueTransmBitCounter, valueClockCounter : std_logic_vector(3 downto 0) := "0000";
	-- counters reset
	signal resetTransmBitCounter, resetClockCounter: std_logic := '0';
	-- counters enable
	signal enTransmBitCounter, enClockCounter: std_logic := '0';

	signal numberBitsToTransmit: std_logic_vector(3 downto 0) := "0000";

	signal sig_serialOut: std_logic := '1';
	signal sig_regControl: std_logic_vector(1 downto 0);
	signal sig_desloca, en_desloca, reset_desloca: std_logic := '0';
	signal counterClkDiv16: std_logic_vector(3 downto 0); 
	signal counterDeslocaOut: std_logic_vector(6 downto 0);

	signal counter15_out: std_logic_vector(3 downto 0);
	
	
	signal clocks_rising : std_logic := '0';
	signal clocks_reset : std_logic := '0';

	signal TransmittedAllBits, transmittedABit, counted_bit_enable : std_logic := '0';

	signal counter15_reset, counter15_en, valueClockCounterIs14 : std_logic := '0';





	# ============================================= FSM STATES =============================================
    type state_type is (Sreset, Sload, S_idle, SnextBit, Sready);
    signal state, next_state: state_type := Sload;

begin

	# ============================================= INSTANCES =============================================
	--ip_pll
    ip_pll: ip_pll_50MHz
    port map (
        refclk   => clock50M,
        rst      => '0',
        outclk_0 => clock1_8MHz
    );

	# ************************************* REGISTERS
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

	THR: shiftregister --Transmitter Holding Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => reset,
      serial_i    => '0',
      loadOrShift => THR_load,
      data_i      => THR_data,
      data_o      => THR_out
      --serial_o_r  => sig_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	THR_load <= "11" when load = '1' else "00";

	TSR: shiftregister --Transmitter Shift Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => reset,
      serial_i    => '1',
      loadOrShift => TSR_L_or_S,
      data_i      => TSR_in,
      data_o      => TSR_out,
      serial_o_r  => TSR_serialOut
      --serial_o_l  => sig_reg_serial_o_l
    );

	LCR: shiftregister -- Line Control Register
    generic map (
      WIDTH => 8
    )
    port map (
      clock       => clock,
      reset       => '0',
      serial_i    => '1',
      loadOrShift => "11",
      data_i      => "0" & "0" & "011" & "0" & "11", -- Divisor Latch Access & Break & Parity & BitStop & Character Length
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

	# ************************************* COUNTERS

	transmitted_Bit_Counter: counter -- counter of transmitted Bit (bits data + 1 bit paraty)
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => transmittedABit,
        reset  => resetTransmBitCounter,
        enable => enTransmBitCounter,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => valueTransmBitCounter
    );

	resetTransmBitCounter <= '0' when state = Sload or state = S_idle else '1';

	enTransmBitCounter <= '0' when valueTransmBitCounter = numberBitsToTransmit else '1'; 

	transmittedABit <= '1' when state = SnextBit else '0';

	TransmittedAllBits <= '1' when valueTransmBitCounter = numberBitsToTransmit else
		'0'; 

	numberBitsToTransmit <= 
		std_logic_vector(to_unsigned(5+1,8)) when LCR_out(1 downto 0) = "00" else
		std_logic_vector(to_unsigned(6+1,8)) when LCR_out(1 downto 0) = "01" else
		std_logic_vector(to_unsigned(7+1,8)) when LCR_out(1 downto 0) = "10" else
		std_logic_vector(to_unsigned(8+1,8)) when LCR_out(1 downto 0) = "11";
	 

	clock_Counter: counter -- counter of clock cycles
    generic map (
        WIDTH => 4
    )
    port map (
        clock  => clock,
        reset  => resetClockCounter,
        enable => enClockCounter,
        load   => '0',
        up     => '1',
        data_i => (others => '0'),
        data_o => valueClockCounter
    );

	valueClockCounterIs14 <= '1' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '0'; -- ativa o sinal valueClockCounterIs14 quando o contador tiver valor 14

	enClockCounter <= '0' when valueClockCounter = STD_LOGIC_VECTOR(to_unsigned(14,4)) else '1'; -- trava o contador em 14 

	resetClockCounter <= '0' when state = S_idle else '1';

	
	# ============================================= FSM PROCESS =============================================
	-- process padrao de procimo estado da fsm
	fsm: process(clock, reset)
	begin
		if reset = '1' then
			state <= Sreset;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process;

	# ============================================= LOGIC =============================================
	-- logica proximo estado
	next_state <=
		Sload when (state = Sreset) else
		S_idle when (state = Sload and go = '1') else
		S_idle when (state = S_idle and valueClockCounterIs14 = '0') else
		SnextBit when (state = S_idle and valueClockCounterIs14 = '1' and TransmittedAllBits = '0') else
		Sready when (state = S_idle and valueClockCounterIs14 = '1' and TransmittedAllBits = '1') else
		Sready when (state = Sready and go = '1') else
		Sload when (state = Sready and go = '0') else
		S_idle when (state = SnextBit) else
		state;

	-- oq fazer em cada estado
	sig_regControl <= "11" when state = Sload and go = '1' else 
					  "00" when state = S_idle else
					  "01" when state = SnextBit else
					  "00";

	counter15_reset <= '0' when state = S_idle else '1';

	readyLed <= '1' when state = Sready else '0';
	
    serialOut <= sig_serialOut;

end architecture;