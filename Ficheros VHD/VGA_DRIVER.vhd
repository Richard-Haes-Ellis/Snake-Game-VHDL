
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity VGA_DRIVER is
	Port ( 
		clk : in STD_LOGIC;
		reset : in STD_LOGIC;
		VS : out STD_LOGIC;
		HS : out STD_LOGIC;
		RED : out STD_LOGIC_VECTOR (2 downto 0);
		GRN : out STD_LOGIC_VECTOR (2 downto 0);
		BLUE : out STD_LOGIC_VECTOR (1 downto 0);
		eje_x : out STD_LOGIC_VECTOR (9 downto 0);
		eje_y : out STD_LOGIC_VECTOR (9 downto 0);
		RED_in : in STD_LOGIC_VECTOR(2 downto 0);
		GRN_in : in STD_LOGIC_VECTOR(2 downto 0);
		BLUE_in : in STD_LOGIC_VECTOR(1 downto 0));
end VGA_DRIVER;
architecture Behavioral of VGA_DRIVER is

component COMPARADOR 

	GENERIC (Nbit : INTEGER := 10;
	End_Of_Screen : INTEGER := 10;
	Start_Of_Pulse: INTEGER := 20;
	End_Of_Pulse  : INTEGER := 30;
	End_Of_Line	  : INTEGER := 40);
	
	PORT(
		clk : in STD_LOGIC;
	 reset : in STD_LOGIC;
	  data : in STD_LOGIC_VECTOR(Nbit-1 downto 0);
		 O1 : out STD_LOGIC;
		 O2 : out STD_LOGIC;
		 O3 : out STD_LOGIC
			);
		 
end component;

component CONTADOR 

	GENERIC (Nbit  : INTEGER := 10);
	PORT(	
			clk 		: in STD_LOGIC;
			rst 		: in STD_LOGIC;
			enable 	: in STD_LOGIC;
			resets	: in STD_LOGIC;
			Q			: out STD_LOGIC_VECTOR(Nbit-1 downto 0)
			);
			
end component;

component GEN_COLOR 

	Port( 
		blank_h : in STD_LOGIC;
		blank_v : in STD_LOGIC;
		RED_in : in STD_LOGIC_VECTOR (2 downto 0);
		GRN_in : in STD_LOGIC_VECTOR (2 downto 0);
		BLUE_in : in STD_LOGIC_VECTOR (1 downto 0);
		RED : out STD_LOGIC_VECTOR (2 downto 0);
		GRN : out STD_LOGIC_VECTOR (2 downto 0);
		BLUE : out STD_LOGIC_VECTOR (1 downto 0)
		);
		
end component;

signal clk_pixel,
		 p_clk_pixel,
		 enable_cont_v,
		 reset_vertical,
		 reset_horizontal,
		 black_h,
		 black_v : STD_LOGIC;
		 
signal ejex,
		 ejey : STD_LOGIC_VECTOR(9 downto 0);
		 
begin

enable_cont_v <= reset_horizontal AND clk_pixel;

eje_x<=ejex;
eje_y<=ejey;

comph : COMPARADOR GENERIC MAP(10,639,655,751,799) PORT MAP(clk,reset,ejex,black_h,HS,reset_horizontal);
compv : COMPARADOR GENERIC MAP(10,479,489,491,520) PORT MAP(clk,reset,ejey,black_v,VS,reset_vertical);

conth : CONTADOR GENERIC MAP(10) PORT MAP(clk,reset,clk_pixel,reset_horizontal,ejex);
contv : CONTADOR GENERIC MAP(10) PORT MAP(clk,reset,enable_cont_v,reset_vertical,ejey);

color : GEN_COLOR PORT MAP(black_h,black_v,red_in,grn_in,blue_in,RED,GRN,BLUE);

clk_pixel <= not p_clk_pixel;
div :process(clk,reset)
begin
	if (reset='1') then
		p_clk_pixel<='0';
	elsif (rising_edge(clk)) then
		p_clk_pixel<= clk_pixel;
	end if;
end process;



end Behavioral;