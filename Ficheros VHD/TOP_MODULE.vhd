library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity TOP_MODULE is
Port ( 
		clk : in STD_LOGIC;
		reset : in STD_LOGIC;
		VS : out STD_LOGIC;
		HS : out STD_LOGIC;
		RED : out STD_LOGIC_VECTOR (2 downto 0);
		GRN : out STD_LOGIC_VECTOR (2 downto 0);
		BLUE : out STD_LOGIC_VECTOR (1 downto 0);
		button_up : in std_logic;
		button_down : in std_logic;
		button_left : in std_logic;
		button_right : in std_logic);
end TOP_MODULE;

architecture Behavioral of TOP_MODULE is

-- MAquina que se encarga de manejar los pulsos de los botones 
-- y determinar la direccion que tiene el snake
component state_machine 	
 port(but1: in std_logic;
	but2: in std_logic;
	but3: in std_logic;
	but4: in std_logic;
	clk: in std_logic;
	rst: in std_logic;
	state: out std_logic_vector (1 downto 0)); -- Guardamos la direciion en un vector de 2 bits
end component;

-- Aqui tenemos toda la logica del juego 
component MAQUINA_JUEGO 
PORT(	clk : in STD_LOGIC;
		rst : in STD_LOGIC;
		btn : in STD_LOGIC;
		lsd_en : out std_logic;
		dir_snake : STD_LOGIC_VECTOR(1 downto 0);
		data_RAM_in : out  STD_LOGIC_VECTOR(4 downto 0); --Los datos en ram estan codificados con 5 bits
		data_RAM_out: in  STD_LOGIC_VECTOR(4 downto 0); 
		dir_RAM  : out STD_LOGIC_VECTOR(9 downto 0);		 --Para un tablero de 32x30 necesitamos 2^10 direcciones
		write_Enable : out STD_LOGIC_VECTOR(0 downto 0));	
end component;


-- En la ram tenemos guardado el tablero del juego
component RAM
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
  );
end component;

-- El reresentador lee el tablero en ram y lo pinta en pantalla
component Representador 
Port (LSD : in  STD_LOGIC;
	eje_x : in STD_LOGIC_VECTOR (9 downto 0); 
	eje_y : in STD_LOGIC_VECTOR (9 downto 0); 
	Data_RAM: in STD_LOGIC_VECTOR (4 downto 0); 
	Data_ROM : in STD_LOGIC_VECTOR (2 downto 0); 
	Addr_RAM : out STD_LOGIC_VECTOR (9 downto 0); 
	Addr_ROM : out STD_LOGIC_VECTOR (12 downto 0);
	RGB : out STD_LOGIC_VECTOR(7 downto 0)); 
end component;

-- En la rom tenemos guardado los sprites de cada componente del juego
component ROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
end component;

--El vga driver se encarga de cumplir con el protocolo VGA para pintar lo que queramos
component VGA_DRIVER 
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
end component;

signal RED_in,
		 GRN_in : std_logic_vector(2 downto 0);
signal BLUE_in : std_logic_vector(1 downto 0);

signal addrom 	 : std_logic_vector(12 downto 0);

signal dir_RAM_game : std_logic_vector(9 downto 0);
signal dir_RAM_rep  : std_logic_vector(9 downto 0);

signal data_RAM_in_game  : std_logic_vector(4 downto 0);
signal data_RAM_in_rep  : std_logic_vector(4 downto 0);
signal data_RAM_out_game : std_logic_vector(4 downto 0);
signal data_RAM_out_rep  : std_logic_vector(4 downto 0);

signal datarom : std_logic_vector(2 downto 0);

signal ejex,ejey : std_logic_vector(9 downto 0);

signal rgb_out : std_logic_vector(7 downto 0);

signal write_Enable_game : std_logic_vector(0 downto 0);
signal write_Enable_rep  : std_logic_vector(0 downto 0);
signal LSD : std_logic;

signal dir_snake : std_logic_vector(1 downto 0);


begin

RED_in<=rgb_out(7 downto 5);
GRN_in<=rgb_out(4 downto 2);
BLUE_in<=rgb_out(1 downto 0);

LSD<='0';
write_Enable_rep<="0";
data_RAM_in_rep<="00000";


display_driver : VGA_DRIVER 	 PORT MAP(clk,reset,VS,HS,RED,GRN,BLUE,ejex,ejey,RED_in,GRN_in,BLUE_in);
rom_module		: ROM 		 	 PORT MAP(clk,addrom,datarom);
ram_module		: RAM			 	 PORT MAP(clk,write_Enable_game,dir_RAM_game,data_RAM_in_game,data_RAM_out_game,clk,write_Enable_rep,dir_RAM_rep,data_RAM_in_rep,data_RAM_out_rep);
representa		: REPRESENTADOR PORT MAP(LSD,ejex,ejey,data_RAM_out_rep,datarom,dir_RAM_rep,addrom,rgb_out);
game_machine 	: MAQUINA_JUEGO PORT MAP(clk,reset,button_right,lsd,dir_snake,data_RAM_in_game,data_RAM_out_game,dir_RAM_game,write_Enable_game);
button_Handler : STATE_MACHINE PORT MAP(button_up,button_down,button_right,button_left,clk,reset,dir_snake);

end Behavioral;

