entity bolsonaroPresidente2028 is
	port
	(
		-- Input ports
		mito				: in bit_vector(9 downto 0) ;
		digitoDoMito0	: out bit_vector(6 downto 0);
		digitoDoMito1	: out bit_vector(6 downto 0);
		digitoDoMito2	: out bit_vector(6 downto 0);
		digitoDoMito3	: out bit_vector(6 downto 0);
		digitoDoMito4	: out bit_vector(6 downto 0);
		digitoDoMito5	: out bit_vector(6 downto 0)
	);
end bolsonaroPresidente2028;

architecture ta_OK of bolsonaroPresidente2028 is

	component hex2seg is
		 port (
					hex : in  bit_vector(3 downto 0);
					seg : out bit_vector(6 downto 0)
			);
	end component;
	
	signal imbrochavel0 : bit_vector(6 downto 0);
	signal imbrochavel1 : bit_vector(6 downto 0);
	signal imbrochavel2 : bit_vector(6 downto 0);

begin

	metralha0 : hex2seg port map(
					hex => mito(3 downto 0),
					seg => imbrochavel0
	);
	metralha1 : hex2seg port map(
					hex => mito(7 downto 4),
					seg => imbrochavel1
	);
	metralha2 : hex2seg port map(
					hex =>  "00" & mito(9) & mito (8),
					seg => imbrochavel2
	);

	digitoDoMito0 <= imbrochavel0;
	digitoDoMito5 <= imbrochavel0;
	
	digitoDoMito1 <= imbrochavel1;
	digitoDoMito4 <= imbrochavel1;
	
	digitoDoMito2 <= imbrochavel2;
	digitoDoMito3 <= imbrochavel2;

end ta_OK;

