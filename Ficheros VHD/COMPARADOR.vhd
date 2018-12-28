library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity COMPARADOR is

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
		 
end COMPARADOR;

architecture Behavioral of COMPARADOR is
signal p_O1,
		 p_O2,
		 p_O3 : STD_LOGIC;
begin

comb:process(data)
begin
	if(unsigned(data) >= End_Of_Screen) then
		p_O1 <= '1';
	else
		p_O1 <= '0';
	end if;
	if((unsigned(data) >= Start_Of_Pulse) AND (End_Of_Pulse >= unsigned(data))) then
		p_O2 <= '0';
	else
		p_O2 <= '1';
	end if;
	if(unsigned(data) = End_Of_Line) then
		p_O3 <= '1';
	else
		p_O3 <= '0';
	end if;
end process;

sinc:process(clk,reset)
begin
	if(reset='1') then
		O1 <= '0';
		O2 <= '1';
		O3 <= '0';
	elsif(rising_edge(clk)) then
		O1<=p_O1;
		O2<=p_O2;
		O3<=p_O3;
	end if;
end process;

end Behavioral;

