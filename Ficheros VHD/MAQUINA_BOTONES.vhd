----------------------------------------------------------------------------------
-- Company: Universidad de Sevilla
-- Engineer: Pablo Camacho Carrellán
-- 
-- Create Date:    13:24:31 12/26/2016 
-- Design Name: Máquina de estados, controles del juego.
-- Module Name:    statemachine - Behavioral 
-- Project Name: Snake

-- Nota: 00 right, 10 left, 01 up, 11 down
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity state_machine is
 port(but1: in std_logic;
	but2: in std_logic;
	but3: in std_logic;
	but4: in std_logic;
	clk: in std_logic;
	rst: in std_logic;
	state: out std_logic_vector (1 downto 0)); 
end state_machine;

architecture Behavioral of state_machine is
 type stat is (RIGHT, LEFT, UP, DOWN);
 signal act_stat: stat;
 signal new_stat: stat;
begin
 comb: process(but1,but2,but3,but4,act_stat)
 begin
 case act_stat is
 -----------------Estado derecha (si pulsamos derecha o izquierda seguiremos en el mismo estado)
	when RIGHT =>
		state<= "00";
	if but1='1' then
		new_stat<= UP;
	elsif but2='1' then
		new_stat<= DOWN;
   elsif but3='1' then
		new_stat<= RIGHT;
	elsif but4='1' then
		new_stat<= RIGHT;
	else
		new_stat<=act_stat;
	end if;
-------------------Estado izquierda (si pulsamos derecha o izquierda seguiremos en el mismo estado)	
	when LEFT =>
		state<= "10";
	if but1='1' then
		new_stat<= UP;
	elsif but2='1' then
		new_stat<= DOWN;
   elsif but3='1' then
		new_stat<= LEFT;
	elsif but4='1' then
		new_stat<= LEFT;
	else
		new_stat<=act_stat;
	end if;
-------------------Estado arriba (si pulsamos arriba o abajo seguiremos arriba)	
	when UP =>
		state<= "01";
	if but1='1' then
		new_stat<= UP;
	elsif but2='1' then
		new_stat<= UP;
   elsif but3='1' then
		new_stat<= RIGHT;
	elsif but4='1' then
		new_stat<= LEFT;
	else
		new_stat<=act_stat;
	end if;
-------------------Estado abajo (si pulsamos arriba o abajo seguiremos abajo)
	when DOWN =>
		state<= "11";
	if but1='1' then
		new_stat<= DOWN;
	elsif but2='1' then
		new_stat<= DOWN;
   elsif but3='1' then
		new_stat<= RIGHT;
	elsif but4='1' then
		new_stat<= LEFT;
	else
		new_stat<=act_stat;
	end if;
-------------------
 end case;
 end process;
 
process(clk,rst)
begin
 if(rst='1')then
	act_stat<=RIGHT;
 elsif (rising_edge(clk)) then
	act_stat<= new_stat;
 end if;
end process; 
end Behavioral;