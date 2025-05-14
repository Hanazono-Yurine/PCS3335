library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exp8 is
	port (
		clock50M, reset: in std_logic := '0';

		serialOut: out std_logic;
		serialIn: in std_logic;

		display7segTHR : out std_logic_vector(6 downto 0);
        display7segRBR : out std_logic_vector(6 downto 0);

		switches: in std_logic_vector(9 downto 0);
		leds: out std_logic_vector(9 downto 0);

        A: in std_logic_vector(2 downto 0); -- seletor de registrador
        notADS : in std_logic := '0'; -- address strobe
        notBAUDOUT : out std_logic := '0'; -- notBAUDOUT <= baudRateGenerator
        RD : in std_logic := '0'; -- read
        notRXRDY : out std_logic := '0'; -- notRXRDY <= not LSR_bit0
        notTXRDY : out std_logic := '0';  -- notRXRDY <= not LSR_bit6
        WR  : in std_logic := '0' -- write

	);
end entity;

architecture rtl of exp8 is

	-- ========================================= COMPONENTS ================================	
	component ip_pll_50MHz is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component;

	component uart is
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

	signal clock1_8MHz, notBAUDOUT_sig: std_logic := '1';

    signal RBR_data, THR_data: std_logic_vector(7 downto 0); 

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

    uart_inst: uart
     port map(
        A => A,
        notADS => notADS,
        notBAUDOUT => notBAUDOUT_sig,
        Din => switches(7 downto 0),
        Dout => leds(7 downto 0),
        MR => reset,
        RD => RD,
        notRXRDY => notRXRDY,
        SIN => serialIn,
        SOUT => serialOut,
        notTXRDY => notTXRDY,
        WR => WR,
        XIN => clock1_8MHz,
        RCLK => notBAUDOUT_sig,
        RBR_onlyDataBitsOut => RBR_data,
        THR_data => THR_data
    );

    leds(9 downto 8) <= "00";
    notBAUDOUT <= notBAUDOUT_sig;


	ascii2seg_THR: ascii2seg
	port map(
		off => '0',
		--asc => RSR_data(7 downto 1),
		asc => THR_data(6 downto 0), -- colocar RBR_onlyDataBits
		seg => display7segTHR,
		dot => open
	);

    ascii2seg_RBR: ascii2seg
	port map(
		off => '0',
		--asc => RSR_data(7 downto 1),
		asc => RBR_data(6 downto 0), -- colocar RBR_onlyDataBits
		seg => display7segRBR,
		dot => open
	);

end architecture;