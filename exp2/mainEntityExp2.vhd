library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity mainEntityExp2 is
    port (
        --input counter
        counter_clock, counter_reset, counter_enable, counter_load, counter_up : in std_logic;
        
        --input/output shiftregister
        reg_clock, reg_reset, reg_serial_i : in std_logic;
		reg_loadOrShift : in std_logic_vector( 1 downto 0 );
        reg_serial_o_r, reg_serial_o_l : out std_logic;

        --entrada em paralelo das chaves
        keys_data_i : in std_logic_vector( 9 downto 0 );

        --origem do reg_data_i
        reg_source_data_i: in std_logic; -- 0 -> reg_data_i <= chaves; 1 -> reg_data_i <= contador

        --output display-7-seg counter
        counter_seg2, counter_seg1, counter_seg0: out std_logic_vector(6 downto 0);

        --output display-7-seg shiftregister
        reg_seg2, reg_seg1, reg_seg0: out std_logic_vector(6 downto 0)
    );
end entity;

architecture arch of mainEntityExp2 is

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

    component hex2seg is
        port ( hex : in  std_logic_vector(3 downto 0); -- Entrada binaria
               seg : out std_logic_vector(6 downto 0)  -- Saída hexadecimal
            );
    end component;

    signal sig_counter_data_o : std_logic_vector( 9 downto 0 );
    signal sig_reg_data_o : std_logic_vector( 9 downto 0 );
    signal sig_reg_data_i : std_logic_vector( 9 downto 0 );
    

begin

    counter_inst: counter
    generic map (
        WIDTH => 10
    )
    port map (
        clock  => counter_clock,
        reset  => counter_reset,
        enable => counter_enable,
        load   => counter_load,
        up     => counter_up,
        data_i => keys_data_i,
        data_o => sig_counter_data_o
    );

    sig_reg_data_i <= sig_counter_data_o when reg_source_data_i = 1 else
                      keys_data_i;

    shiftregister_inst: shiftregister
    generic map (
      WIDTH => 10
    )
    port map (
      clock       => reg_clock,
      reset       => reg_reset,
      serial_i    => reg_serial_i,
      loadOrShift => reg_loadOrShift,
      data_i      => sig_reg_data_i,
      data_o      => sig_reg_data_o,
      serial_o_r  => reg_serial_o_r,
      serial_o_l  => reg_serial_o_l
    );

    -- display-7-seg que mostra o valor do counter
    hex2seg_counter2: hex2seg
    port map (
      hex => "00" & sig_counter_data_o(9 downto 8),
      seg => counter_seg2
    );

    hex2seg_counter1: hex2seg
    port map (
      hex => sig_counter_data_o(7 downto 4),
      seg => counter_seg1
    );

    hex2seg_counter0: hex2seg
    port map (
      hex => sig_counter_data_o(3 downto 0),
      seg => counter_seg0
    );
    
    -- display-7-seg que mostra o valor do reg
    hex2seg_reg2: hex2seg
    port map (
      hex => "00" & sig_reg_data_o(9 downto 8),
      seg => reg_seg2
    );

    hex2seg_reg1: hex2seg
    port map (
      hex => sig_reg_data_o(7 downto 4),
      seg => reg_seg1
    );

    hex2seg_reg0: hex2seg
    port map (
      hex => sig_reg_data_o(3 downto 0),
      seg => reg_seg0
    );


end architecture;
