library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GEN_COLOR is

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
		
end GEN_COLOR;

architecture Behavioral of GEN_COLOR is

begin
gen_color:process(Blank_H, Blank_V, RED_in, GRN_in,BLUE_in)
begin
	if (Blank_H='1' or Blank_V='1') then
		RED<=(others => '0'); 
		GRN<=(others => '0');
		BLUE<=(others => '0');
	else
		RED<=RED_in; 
		GRN<=GRN_in; 
		BLUE<=BLUE_in;
	end if;
end process;

end Behavioral;

