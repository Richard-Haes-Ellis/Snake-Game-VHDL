library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MAQUINA_JUEGO is

PORT(	clk : in STD_LOGIC;
		rst : in STD_LOGIC;
		btn : in STD_LOGIC;
		lsd_en : out STD_LOGIC;
		dir_snake : STD_LOGIC_VECTOR(1 downto 0);
		data_RAM_in : out  STD_LOGIC_VECTOR(4 downto 0);	--Los datos en ram estan codificados con 5 bits
		data_RAM_out: in  STD_LOGIC_VECTOR(4 downto 0); 
		dir_RAM  : out STD_LOGIC_VECTOR(9 downto 0);		--Para un tablero de 32x30 necesitamos 2^10 direcciones
		write_Enable : out STD_LOGIC_VECTOR(0 downto 0)
		);
		
end MAQUINA_JUEGO;


architecture Behavioral of MAQUINA_JUEGO is

component lfsr1 
  port (
    reset  : in  std_logic;
    clk    : in  std_logic; 
    enable : in  std_logic;  
    count  : out std_logic_vector (9 downto 0) -- lfsr output
  );
end component;  

type    estado is(INICIO,
						LEE_ORIENT_CBZA,
						LEE_POS_CBZA_SIGUIENTE,
						PINTA_CABEZA,
						PINTA_CUERPO_O_ESQUINA,
						LEE_ORIENT_COLA,
						LEE_POS_COLA_SIGUIENTE,
						PINTA_COLA_CON_ORIENTACION,
						BORRA_COLA_ANTIGUA,
						ACTUALIZA_OBJETO,
						DELAY_GAME,
						MUERTO);
						
--------------------------------
-----------VARIABLES------------
--------------------------------

	-- Variable para saber en que direccion pintar la cola
type direction is(left,    
						straight,
						right);
						
	-- VAriable que nos informa de que objeto se ha comido en cada pase
type	  objeto is(vacio,
						wall,
						LSD,
						twix,
						manzana,
						veneno);

signal p_side,side : direction;
signal p_obj,obj : objeto;
signal estado_Actual,estado_Nuevo : estado;

	-- Variables para la posicion y direccion actual y anterior de la cabeza
signal x_pos_cbza,p_x_pos_cbza : unsigned(4 downto 0);
signal y_pos_cbza,p_y_pos_cbza : unsigned(4 downto 0);

signal x_pos_ant_cbza,p_x_pos_ant_cbza : unsigned(4 downto 0);
signal y_pos_ant_cbza,p_y_pos_ant_cbza : unsigned(4 downto 0);

signal dir_act_cbza,p_dir_act_cbza : unsigned(1 downto 0); -- direccion actual
signal dir_ant_cbza,p_dir_ant_cbza : unsigned(1 downto 0); -- direccion anterior


	-- Variables para la posicion y direccion de la cola
signal x_pos_cola,p_x_pos_cola : unsigned(4 downto 0);
signal y_pos_cola,p_y_pos_cola : unsigned(4 downto 0);

signal x_pos_ant_cola,p_x_pos_ant_cola : unsigned(4 downto 0);
signal y_pos_ant_cola,p_y_pos_ant_cola : unsigned(4 downto 0);

signal p_dir_cola,dir_cola : unsigned(1 downto 0);


	-- Tiempo entre pasadas , define la velocidad del juego.
signal p_time_lapse,time_lapse : unsigned(25 downto 0);


	-- Variable necesaria para borrar la cola dos veces si come veneno
signal colas_borradas,p_colas_borradas : unsigned(0 downto 0);


	--Variable de espera para cargar el dato de la ram
signal wait_time,p_wait_time : unsigned(0 downto 0);

	--Variables de poscidion aleatorias para los objetos
signal ran_coord: std_logic_vector(9 downto 0);

	--Variable para generar un numero aleatorio nuevo
signal p_en_ran,en_ran: std_logic;

begin

	-- Instanciamos el bloque LFSR para generar un numero aleatorio con la señal en_ran
rand_Num_gen : lfsr1 PORT MAP(rst,clk,en_ran,ran_coord);

sinc : process(clk,rst)
begin
	if(rst='1')then 
	
	-- DEFINIMOS LAS CONDICIONES INICIALES DEL JUEGO
	
		wait_time<=(Others =>'0');
		time_lapse<=(Others =>'0');
		dir_cola<="00";
		x_pos_ant_cola<="01010";
		y_pos_ant_cola<="10000";
		x_pos_cola<="01010";
		y_pos_cola<="10000";
		x_pos_cbza<="01100";
		y_pos_cbza<="10000";
		x_pos_ant_cbza<="01100";
		y_pos_ant_cbza<="10000";
		dir_act_cbza<="00";
		dir_ant_cbza<="00";
		estado_Actual<=Inicio;
		obj<=vacio;
		en_ran<='0';
		side<=straight;	
		colas_borradas<=(others=>'0');
		
	elsif(rising_edge(clk))then
	
		wait_time<=p_wait_time;
		time_lapse<=p_time_lapse;
		dir_cola<=p_dir_cola;
		x_pos_ant_cola<=p_x_pos_ant_cola;
		y_pos_ant_cola<=p_y_pos_ant_cola;
		x_pos_cola<=p_x_pos_cola;
		y_pos_cola<=p_y_pos_cola;
		x_pos_cbza<=p_x_pos_cbza;
		y_pos_cbza<=p_y_pos_cbza;
		x_pos_ant_cbza<=p_x_pos_ant_cbza;
		y_pos_ant_cbza<=p_y_pos_ant_cbza;
		dir_act_cbza<=p_dir_act_cbza;
		dir_ant_cbza<=p_dir_ant_cbza;
		estado_Actual<=estado_Nuevo;
		obj<=p_obj;
		en_ran<=p_en_ran;
		side<=p_side;
		colas_borradas<=p_colas_borradas;
		
	end if;
end process;

comb : process(en_ran,ran_coord,estado_Actual,wait_time,time_lapse,dir_cola,x_pos_ant_cola,y_pos_ant_cola,x_pos_cola,y_pos_cola,x_pos_cbza,y_pos_cbza,x_pos_ant_cbza,y_pos_ant_cbza,dir_act_cbza,dir_ant_cbza,obj,side,colas_borradas,btn,dir_snake,data_RAM_out)
	begin
	
	-- En el principio del process colocamos los valores que queremos que tengan
	-- por defecto, asi podemos evitar que aparezcan latches y nos permite reducir
	-- el numero de lineas de codigo y deja mas claro la lectura del mismo.
	
	data_RAM_in<="00000";
	dir_RAM<="0000000000";
	write_Enable<="0";
	p_wait_time<=wait_time;
	p_time_lapse<=time_lapse;
	p_dir_cola<=dir_cola;
	p_x_pos_ant_cola<=x_pos_ant_cola;
	p_y_pos_ant_cola<=y_pos_ant_cola;
	p_x_pos_cola<=x_pos_cola;
	p_y_pos_cola<=y_pos_cola;
	p_x_pos_cbza<=x_pos_cbza;
	p_y_pos_cbza<=y_pos_cbza;
	p_x_pos_ant_cbza<=x_pos_ant_cbza;
	p_y_pos_ant_cbza<=y_pos_ant_cbza;
	p_dir_act_cbza<=dir_act_cbza;
	p_dir_ant_cbza<=dir_ant_cbza;
	estado_Nuevo<=estado_Actual;
	p_obj<=obj;
	p_en_ran<='0';
	p_side<=side;	
	p_colas_borradas<=colas_borradas;
	
		case estado_Actual is
			--ESTADO INICIAL - Hasta que no pulsemos el boton derecho no empieza el juego.
			when INICIO => 
				if(btn='1')then
					estado_Nuevo<=LEE_ORIENT_CBZA;
				else
					estado_Nuevo<=estado_Actual;
				end if;
		
		
			--LEE LA ORIENTACION SIGUENTE DE LA CABEZA
			when LEE_ORIENT_CBZA =>
				p_dir_act_cbza<=unsigned(dir_snake); -- Lo obtenemos de la maquina de estados
				p_dir_ant_cbza<=dir_act_cbza;			 -- del manejo de los botones
				estado_Nuevo<=LEE_POS_CBZA_SIGUIENTE;
		
		
			--MIRA SI LA SIGUENTE CASILLA ESTA VACIA O SI HAY OBJETO, PARED ETC
			
			when LEE_POS_CBZA_SIGUiENTE =>
				case dir_act_cbza is
					when "00" =>	--Si la cabeza esta orientada hacia la RERECHA
					
					-- Leemos lo que hay en esa casilla
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cbza+1);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cbza);
							
						--ACTUALIZAMOS VARIABLES DE POSICION CABEZA
							p_x_pos_ant_cbza<=x_pos_cbza;
							p_y_pos_ant_cbza<=y_pos_cbza;
							p_x_pos_cbza<=x_pos_cbza+1;
							p_y_pos_cbza<=y_pos_cbza;
							p_wait_time<=(others => '0');
						
					when "01" =>	--Si la cabeza esta orientada hacia ARRIBA
						
					-- Leemos lo que hay en esa casilla
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cbza);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cbza-1);
							
						--ACTUALIZAMOS VARIABLES DE POSICION
							p_x_pos_ant_cbza<=x_pos_cbza;
							p_y_pos_ant_cbza<=y_pos_cbza;
							p_x_pos_cbza<=x_pos_cbza;
							p_y_pos_cbza<=y_pos_cbza-1;
							p_wait_time<=(others => '0');
						
					when "10" =>	--Si la cabeza esta orientada hacia la IZQUIERDA
					
					-- Leemos lo que hay en esa casilla
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cbza-1);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cbza);
						
						--ACTUALIZAMOS VARIABLES DE POSICION
							p_x_pos_ant_cbza<=x_pos_cbza;
							p_y_pos_ant_cbza<=y_pos_cbza;
							p_x_pos_cbza<=x_pos_cbza-1;
							p_y_pos_cbza<=y_pos_cbza;
							p_wait_time<=(others => '0');
						
					when "11" =>	--Si la cabeza esta orientada hacia ABAJO
					
					-- Leemos lo que hay en esa casilla
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cbza);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cbza+1);
							
						--ACTUALIZAMOS VARIABLES DE POSICION
							p_x_pos_ant_cbza<=x_pos_cbza;
							p_y_pos_ant_cbza<=y_pos_cbza;
							p_x_pos_cbza<=x_pos_cbza;
							p_y_pos_cbza<=y_pos_cbza+1;
						
					when others =>
				end case;
				
				if(wait_time=1)then
					if(data_RAM_out="00000")then		--VACIO ?
						estado_Nuevo<=PINTA_CABEZA;	
						p_obj<=vacio;
					elsif(data_RAM_out="10001")then	--MANZANA ?
						p_obj<=manzana;
						estado_Nuevo<=PINTA_CABEZA;
					elsif(data_RAM_out="10100")then  --VENENO	? ( No immplementado )
						p_obj<=veneno;
						estado_Nuevo<=PINTA_CABEZA;
					elsif(data_RAM_out="10101")then	--PARED ?
 						estado_Nuevo<=MUERTO;
						p_obj<=wall;
					elsif(data_RAM_out="10010")then  --LSD ? ( No implementado )
						estado_Nuevo<=PINTA_CABEZA;
						p_obj<=LSD;
					elsif(data_RAM_out="10011")then  --TWIX ? ( No implementado )
						estado_Nuevo<=PINTA_CABEZA;
						p_obj<=twix;
					else
						estado_Nuevo<=MUERTO;
					end if;
				else
					p_wait_time<=wait_time+1;
				end if;
				
			--PINTA LA CABEZA CON LA ORIENTACION ADECUADA
			when PINTA_CABEZA =>
			dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cbza);
			dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cbza);
			write_Enable<="1";
				if(dir_act_cbza=0)then 		--Si va a la derecha
					data_RAM_in<="00011";			--Cabeza orientada a la derecha
				elsif(dir_act_cbza=1)then	--Si va hacia arriba
					data_RAM_in<="00001";			--Cabeza orientada hacia arriba
				elsif(dir_act_cbza=2)then	--Si va a la izquier
					data_RAM_in<="00100";			--Cabeza orientada hacia la iquierda
				elsif(dir_act_cbza=3)then	--Si va hacia abajo
					data_RAM_in<="00010";			--Cabeza orientada hacia abajo
				end if;
				
			 --Esperamos un tiempo de reloj para que se guarde el valor en la RAM.
				if(wait_time=1)then
					p_wait_time<=(others => '0');
					estado_Nuevo<=PINTA_CUERPO_O_ESQUINA;
				else
					p_wait_time<=wait_time+1;
				end if;
		
		
		
			--EN FUNCION DE QUE SI HA GIRADO O NO PINTA UNA ESQUINA O UN CUERPO RECTO
			when PINTA_CUERPO_O_ESQUINA =>
				dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_ant_cbza);
				dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_ant_cbza);
				write_Enable<="1";
				case dir_ant_cbza is -- Si la direccion anterior de la cabeza fue...
					when "00" =>	--DERECHA
						if(dir_act_cbza=0)then	--Si va en la misma direccion
							data_RAM_in<="00111";	--Cuerpo recto horizontal
						elsif(dir_act_cbza=1)then  --Cambia de direccion
							data_RAM_in<="01011";	--Esquina (hacia la derecha subiendo)							
						elsif(dir_act_cbza=3)then	--Cambia de direccion
							data_RAM_in<="01100";	--Esquina (hacia la derecha bajando)
						end if;
					when "01" =>	--ARRIBA
						if(dir_act_cbza=1)then	--Si va en la misma direccion
							data_RAM_in<="00101";	--Cuerpo recto vertical
						elsif(dir_act_cbza=0)then	--Cambia de direccion
							data_RAM_in<="01010";	--Esquina (subiendo hacia la derecha)								
						elsif(dir_act_cbza=2)then	--Cambia de direccion
							data_RAM_in<="01100";	--Esquina (subiendo la izquierda)
						end if;
					when "10" =>	--IZQUIERDA
						if(dir_act_cbza=2)then	--Si va en la misma direccion
							data_RAM_in<="01000";	--Cuerpo recto izquirda
						elsif(dir_act_cbza=1)then	--Cambia de direccion
							data_RAM_in<="01001";	--Esquina (hacia la izquierda subiendo)							
						elsif(dir_act_cbza=3)then	--Cambia de direccion
							data_RAM_in<="01010";	--Esquina (hacia la izquierda bajando)
						end if;
					when "11" =>	--ABAJO
						if(dir_act_cbza=3)then	--Si va en la misma direccion
							data_RAM_in<="00110";	--Cuerpo recto vertical
						elsif(dir_act_cbza=0)then	--Cambia de direccion
							data_RAM_in<="01001";	--Esquina (bajando hacia la derecha)	
						elsif(dir_act_cbza=2)then	--Cambia de direccion
							data_RAM_in<="01011";	--Esquina (bajando hacia la izquierda)
						end if;
					when others =>
					end case;
					
				 --Tiempo de espera para guardar el valor en ram.
					if(wait_time=1)then
						estado_Nuevo<=LEE_ORIENT_COLA;
						p_wait_time<=(others => '0');
					else
						p_wait_time<=wait_time+1;
					end if;
		
		
		
			--LEE LA ORIENTACION DE LA COLA PARA VER LA POSICION SIGUENTE DE ELLA MISMA
			when LEE_ORIENT_COLA =>
				if(obj=manzana)then -- Si el objeto fue una manzana no hace falta borrar la cola.
										  -- asi hacemos que crezca la cabeza.
					estado_Nuevo<=ACTUALIZA_OBJETO;
				else
				-- Leemos la posicion de la cola
					dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cola);
					dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cola);
					
				-- Tiempo de espera para carcarlo desde la ram
					if(wait_time=1)then
							if(data_RAM_out="01101")then --ARRIBA
							p_dir_cola<="01";
						elsif(data_RAM_out="01110")then --ABAJO
							p_dir_cola<="11";
						elsif(data_RAM_out="01111")then --DERECHA
							p_dir_cola<="00";
						elsif(data_RAM_out="10000")then --IZQUIERDA
							p_dir_cola<="10";
						end if;
						p_wait_time<=(others => '0');
						estado_Nuevo<=LEE_POS_COLA_SIGUIENTE;
					else
						p_wait_time<=wait_time+1;
						estado_Nuevo<=estado_Actual;
					end if;
				end if;
		
		
		
			--LEEMOS LA POS SIGUENTE DE LA COLA
			when LEE_POS_COLA_SIGUIENTE =>
			-- Sabiendo la direccion de la cola podemos saber la siguente poscion que debe ocupar.
				case dir_cola is
					when "00" => -- Si la punta apunta hacia la izquierda
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cola+1);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cola);
						
						if(wait_time=1)then
						-- ACTUALIZAMOS VARIABLES DE POSICION DE COLA
							p_x_pos_cola<=x_pos_cola+1;
							p_y_pos_cola<=y_pos_cola;
								
							p_x_pos_ant_cola<=x_pos_cola;
							p_y_pos_ant_cola<=y_pos_cola;
							
							p_wait_time<=(others => '0');
						
						-- Aqui determinamos si la cola se tiene que pintar a la derecha, izquierda o igual que antes.
							if(data_RAM_out="00111")then -- Si es cuerpo
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=straight;
							elsif(data_RAM_out="01100")then -- si esquina, hacia la derecha bajando
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=right;
							elsif(data_RAM_out="01011")then -- si esquina, hacia la derecha subiendo
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=left;
							end if;
						else
							p_wait_time<=wait_time+1;
						end if;
						
					when "01" => --Si la punta apunta hacia abajo
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cola);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cola-1);
						
						if(wait_time=1)then
						-- ACTUALIZAMOS VARIABLES DE POSICION DE COLA
							p_x_pos_cola<=x_pos_cola;
							p_y_pos_cola<=y_pos_cola-1;
								
							p_x_pos_ant_cola<=x_pos_cola;
							p_y_pos_ant_cola<=y_pos_cola;
							
							p_wait_time<=(others => '0');
						
						-- Aqui determinamos si la cola se tiene que pintar a la derecha, izquierda o igual que antes.
							if(data_RAM_out="00101")then -- Si es cuerpo
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=straight;
							elsif(data_RAM_out="01010")then -- si esquina, subiendo hacia la derecha
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=right;
							elsif(data_RAM_out="01100")then -- si esquina, subiendo hacia la izquierda
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=left;
							end if;
						else
							p_wait_time<=wait_time+1;
						end if;
						
					when "10" => --Si la punta apunta hacia la derecha
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cola-1);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cola);
						
						if(wait_time=1)then
						-- ACTUALIZAMOS VARIABLES DE POSICION DE COLA
							p_x_pos_cola<=x_pos_cola-1;
							p_y_pos_cola<=y_pos_cola;
								
							p_x_pos_ant_cola<=x_pos_cola;
							p_y_pos_ant_cola<=y_pos_cola;
							
							p_wait_time<=(others => '0');
							
						-- Aqui determinamos si la cola se tiene que pintar a la derecha, izquierda o igual que antes.
							if(data_RAM_out="01000")then -- Si es cuerpo
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=straight;
							elsif(data_RAM_out="01001")then -- si esquina, hacia la izquierda subiendo
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=right;
							elsif(data_RAM_out="01010")then -- si esquina, hacia la izquierda bajando
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=left;
							end if;
						else
							p_wait_time<=wait_time+1;
						end if;
						
					when "11" => --Si la punta apunta hacia arriba
						dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cola);
						dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cola+1);
						
						if(wait_time=1)then
						-- ACTUALIZAMOS VARIABLES DE POSICION DE COLA
							p_x_pos_cola<=x_pos_cola;
							p_y_pos_cola<=y_pos_cola+1;
								
							p_x_pos_ant_cola<=x_pos_cola;
							p_y_pos_ant_cola<=y_pos_cola;
							
							p_wait_time<=(others => '0');
							
						-- Aqui determinamos si la cola se tiene que pintar a la derecha, izquierda o igual que antes.
							if(data_RAM_out="00110")then -- Si es cuerpo
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=straight;
							elsif(data_RAM_out="01011")then -- si esquina, bajando hacia la izquirda
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=right;
							elsif(data_RAM_out="01001")then -- si esquina, bajando hacia la derecha
								estado_Nuevo<=PINTA_COLA_CON_ORIENTACION;
								p_side<=left;
							end if;
						else
							p_wait_time<=wait_time+1;
						end if;
					when others =>
				end case;
		
			
			--EN FUNCION DE QUE ES LO QUE HEMOS LEIDO PINTAMOS UNA ESQUINA O CUERPO AL LADO CORRESPONDIENTE
			when PINTA_COLA_CON_ORIENTACION =>
				dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_cola);
				dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_cola);
				write_Enable<="1"; -- Preparamos para escribir en la ram
				
				-- Pintamos segun el lado que corresponda con respecto a la direccion de la cola.
				case dir_cola is
					when "00" =>
						if(side=left)then
							data_RAM_in<="01101"; -- Pinta una esquina
						elsif(side=right)then
							data_RAM_in<="01110"; -- Pinta una esquina
						else
							data_RAM_in<="01111"; -- Pinta un cuerpo recto 
						end if;
					when "01" =>
						if(side=left)then
							data_RAM_in<="10000"; -- Pinta una esquina
						elsif(side=right)then
							data_RAM_in<="01111"; -- Pinta una esquina
						else
							data_RAM_in<="01101"; -- Pinta un cuerpo recto
						end if;
					when "10" =>
						if(side=left)then
							data_RAM_in<="01110"; -- Pinta una esquina
						elsif(side=right)then
							data_RAM_in<="01101"; -- Pinta una esquina
						else
							data_RAM_in<="10000"; -- Pinta un cuerpo recto
						end if;
					when "11" =>
						if(side=left)then
							data_RAM_in<="01111"; -- Pinta una esquina
						elsif(side=right)then
							data_RAM_in<="10000"; -- Pinta una esquina
						else
							data_RAM_in<="01110"; -- Pinta un cuerpo recto
						end if;
					when others =>
				end case;
				if(wait_time=1)then
					estado_Nuevo<=BORRA_COLA_ANTIGUA;
					p_wait_time<=(others => '0');
				else
					p_wait_time<=wait_time+1;
				end if;
		
		
			--BORRAMOS LA COLA ANTIGUA CON LAS COORDENADAS DE COLA ANTIGUA
			when BORRA_COLA_ANTIGUA =>
			-- Con la variable de posicion de cola anterior podemos sobre escribir la cola con vacio.
				dir_RAM(4 downto 0)<=STD_LOGIC_VECTOR(x_pos_ant_cola);
				dir_RAM(9 downto 5)<=STD_LOGIC_VECTOR(y_pos_ant_cola);
				data_RAM_in<="00000"; -- Vacio
				write_Enable<="1"; 
				if(wait_time=1)then
				-- En el caso de que se haya comido alguna fruta como el veneno tenemos que borrar la cola dos veces.
				
					-- NO IMPLEMENTADO --
					
--					if(obj=veneno)then
--						if(colas_borradas=1)then --Si ya se ha borrado dos vezes terminamos 
--							estado_Nuevo<=DELAY_GAME;
--							p_colas_borradas<=(others => '0');
--						else
--							estado_Nuevo<=LEE_ORIENT_COLA;
--							p_colas_borradas<=colas_borradas+1;
--						end if;
--					else
					
					---------------------
					estado_Nuevo<=DELAY_GAME;
					p_wait_time<=(others => '0');
				else
					p_wait_time<=wait_time+1;
				end if;
			
			--ACTUALIZAMOS LOS OBJETOS DEL TABLERO SI PROCEDE
			when ACTUALIZA_OBJETO =>
				if(obj=manzana)then
				--Como ya hemos comido una manzana tenemos que colocar otra aleatoriamente, 
				--para ello tenemos el modulo LFSR que es un registro de desplazamiento que 
				--nos devuelve un valor "aleatorio" de 10 bits, el cual usamos para las 
				--coordenadas del tablero. Si este valor no cumple que este dentro del tablero,
				--o que sea menor que la direccion maxima de la ram (960) probamos otro valor.
					if((unsigned(ran_coord(4 downto 0))>1 and unsigned(ran_coord(4 downto 0))<31) AND (unsigned(ran_coord(9 downto 5))>1 and unsigned(ran_coord(9 downto 5))<29) AND unsigned(ran_coord)<960)then
							
						-- Leemos la celda aleatoria y comprobamos que este vacia.
							dir_RAM<=ran_coord;
							if(wait_time=1)then
								p_wait_time<=(Others=>'0');
								if(data_RAM_OUT="00000")then
								-- Si esta vacia ponemos una manzana y saltamos al siguente estado.
									write_Enable<="1";
									data_RAM_in<="10001";
									estado_Nuevo<=DELAY_GAME;
									p_en_ran<='0';
								else
								-- Si no esta vacia porbamos otro valor y saltamos al mismo estado otravez.
									if(en_ran='1')then
										p_en_ran<='0';
									elsif(en_ran='0')then
										p_en_Ran<='1';
									end if;
									estado_Nuevo<=ACTUALIZA_OBJETO;
								end if;
							else
								p_wait_time<=wait_time+1;
							end if;
					else
					-- Si no cumple con la condiciones definidas anteriormente probamos otro valor.
						if(en_ran='1')then
							p_en_ran<='0';
						elsif(en_ran='0')then
							p_en_Ran<='1';
						end if;
						estado_Nuevo<=ACTUALIZA_OBJETO;
					end if;
				else
					estado_Nuevo<=DELAY_GAME;
				end if;
				
				
			--ESPERAMOS UN TIEMPO ENTRE PASADAS PARA QUE EL JUEGO FLUYA A UNA DETERMINADA VELOCDAD
			when DELAY_GAME =>
				--if(time_lapse=15000000)then
				 if(time_lapse=10000)then
					p_time_lapse<=(others => '0');
					p_obj<=vacio;
					estado_Nuevo<=LEE_ORIENT_CBZA;
				else
					p_time_lapse<=time_lapse+1;
				end if;
			
			when others =>
		end case;
end process;
end Behavioral;
