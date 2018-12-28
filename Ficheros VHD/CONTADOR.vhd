
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CONTADOR is

	GENERIC (Nbit  : INTEGER := 10);
	PORT(	clk 		: in STD_LOGIC;
			rst 		: in STD_LOGIC;
			enable 	: in STD_LOGIC;
			resets	: in STD_LOGIC;
			Q			: out STD_LOGIC_VECTOR(Nbit-1 downto 0)
			);
			
end CONTADOR;

architecture Behavioral of CONTADOR is
signal cuenta, p_cuenta : unsigned(Nbit-1 downto 0);
begin

Q <= STD_LOGIC_VECTOR(cuenta);

comb : process(enable,cuenta,resets)
begin
	if(enable='1' AND resets='0') then
		p_cuenta <= cuenta + 1;
	elsif(resets ='1') then
		p_cuenta <= (others => '0');
	else 
		p_cuenta <= cuenta;
	end if;
end process;
	
sinc : process(clk,rst)
begin
	if(rst='1') then
		cuenta <= (others => '0');
	elsif(rising_edge(clk)) then
		cuenta <= p_cuenta;
	end if;
end process;
end Behavioral;

