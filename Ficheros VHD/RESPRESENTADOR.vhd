library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Representador is
Port (LSD : in  STD_LOGIC;
	eje_x : in STD_LOGIC_VECTOR (9 downto 0); -- la coordenada x del pixel que se esta pintando 
	eje_y : in STD_LOGIC_VECTOR (9 downto 0); -- la coordenada y del pixel que se esta pintando
	Data_RAM: in STD_LOGIC_VECTOR (4 downto 0); 
	Data_ROM : in STD_LOGIC_VECTOR (2 downto 0); 
	Addr_RAM : out STD_LOGIC_VECTOR (9 downto 0); 
	Addr_ROM : out STD_LOGIC_VECTOR (12 downto 0);
	RGB : out STD_LOGIC_VECTOR(7 downto 0)); 
end Representador;

architecture Behavioral of Representador is

signal x_tablero_aux : unsigned (9  downto 0);
signal x_tablero     : unsigned (9  downto 0);
signal y_tablero     : unsigned (9  downto 0);
signal Addr_ROM_aux  : unsigned (12  downto 0);
signal dir_imagen    : unsigned (12 downto 0);

begin
 
Addr_ROM <= std_logic_vector(Addr_ROM_aux);

decodificador_rom: process(Data_RAM) 
begin 
	CASE Data_RAM is
		WHEN "00000"=> dir_imagen <= "0000000000000";--vacío
		WHEN "00001"=> dir_imagen <= "0001000000000";--cabeza arriba
		WHEN "00010"=> dir_imagen <= "0000100000000";--cabeza abajo
		WHEN "00011"=> dir_imagen <= "0001100000000";--cabeza derecha
		WHEN "00100"=> dir_imagen <= "0010000000000";--cabeza izquierda
		WHEN "00101"=> dir_imagen <= "0011000000000";--cuerpo arriba
		WHEN "00110"=> dir_imagen <= "0010100000000";--cuerpo abajo
		WHEN "00111"=> dir_imagen <= "0011100000000";--cuerpo derecha
		WHEN "01000"=> dir_imagen <= "0100000000000";--cuerpo izquierda
		WHEN "01001"=> dir_imagen <= "1000000000000";--esquina arriba izquierda
		WHEN "01010"=> dir_imagen <= "0111100000000";--esquina abajo izquierda
		WHEN "01011"=> dir_imagen <= "0111000000000";--esquina arriba derecha
		WHEN "01100"=> dir_imagen <= "0110100000000";--esquina arriba izquierda
		WHEN "01101"=> dir_imagen <= "0101000000000";--cola arriba
		WHEN "01110"=> dir_imagen <= "0100100000000";--cola abajo
		WHEN "01111"=> dir_imagen <= "0101100000000";--cola derecha
		WHEN "10000"=> dir_imagen <= "0110000000000";--cola izquierda
		WHEN "10001"=> dir_imagen <= "1001000000000";--manzana
		WHEN "10010"=> dir_imagen <= "1000100000000";--LSD
		WHEN "10011"=> dir_imagen <= "1010000000000";--twix
		WHEN "10100"=> dir_imagen <= "1001100000000";--veneno
		WHEN "10101"=> dir_imagen <= "1010100000000";--muro
		WHEN OTHERS=>  dir_imagen <= "0000000000000";
	END CASE;
end process;

dibuja: process(eje_x, eje_y,Data_ROM,LSD,y_tablero,x_tablero,Addr_ROM_aux,dir_imagen) 
begin

	-- Si resulta que los pixeles que se estan pintando estan fuera del tablero
	if (((eje_x>=0 and eje_x<64) or (eje_x>575)) or (eje_y>479)) then 
	RGB<="00000000";
	y_tablero <= (others => '0');
	x_tablero <= (others => '0');
	x_tablero_aux <=(others => '0');
	Addr_ROM_aux  <=(others => '0');
	Addr_RAM<=(others => '0');
	else
		-- Dividimos por 16 eje_x y eje_y para obtener las coordenada en el tablero 
		x_tablero_aux <= unsigned(eje_x)-"0001000000"; -- Le restamos 64 para centrar el tablero
		y_tablero(9 downto 5)<=(Others => '0');	-- Lo demas a cero 
		y_tablero(4 downto 0) <= unsigned(eje_y(8 downto 4)); -- Dividimos por 16 
		x_tablero(5)<='0';   -- Lo demas a cero
		x_tablero(4 downto 0)<= x_tablero_aux(8 downto 4); -- Dividimos por 16
		
		-- En el pimrer termino tenemos la direccion de la imagen que se tiene que pintar
		-- En el segundo termino tenemos  la  fila  de esa imagen que se tiene que pintar
		-- En el ultimo termino tenemos  la  columna de la imagen que se tiene que pintar	
		Addr_ROM_aux <= dir_imagen +((unsigned(eje_y)-(y_tablero sll 4)) sll 4) + (unsigned(eje_x)-64-(x_tablero sll 4)) -1;
		
		-- Le asignamos a la direccion de la ram las coordenadas del tablero 
		-- pra obtener informacion de lo que hay en dicha celda 
		
		Addr_RAM(9 downto 5)<=std_logic_vector(y_tablero(4 downto 0));
		Addr_RAM(4 downto 0)<=std_logic_vector(x_tablero(4 downto 0));
		
		if (LSD ='0') then
			CASE Data_ROM is
				WHEN "000"=> RGB <= "00000000"; --negro
				WHEN "111"=> RGB <= "11111111"; --blanco
				WHEN "100"=> RGB <= "11100000"; --rojo
				WHEN "110"=> RGB <= "11111100"; --amarillo
				WHEN "010"=> RGB <= "00011100"; --verde
				WHEN "101"=> RGB <= "11100011"; --lila
				WHEN "011"=> RGB <= "00011111"; --cian
				WHEN "001"=> RGB <= "00000011"; --azul
				WHEN OTHERS=> RGB <="00000000";
			END CASE;
		else
			CASE Data_ROM is
				WHEN "000"=> RGB <= "11111111"; 
				WHEN "111"=> RGB <= "10101010";
				WHEN "100"=> RGB <= "11101010";
				WHEN "110"=> RGB <= "00101101";
				WHEN "010"=> RGB <= "11011011";
				WHEN "101"=> RGB <= "10110100";
				WHEN "011"=> RGB <= "00010011";
				WHEN "001"=> RGB <= "11011010";
				WHEN OTHERS=> RGB <="11111111";
			END CASE;
		end if; 
	end if;
end process;

end Behavioral;

