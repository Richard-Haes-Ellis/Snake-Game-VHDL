library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_1164.all; 
	 use ieee.std_logic_textio.all; 
	 use ieee.numeric_std.ALL; 
	 use std.textio.all; 

entity lfsr1 is
  port (
    reset  : in  std_logic;
    clk    : in  std_logic; 
    enable : in  std_logic;
    count  : out std_logic_vector (9 downto 0) -- lfsr output
  );
end entity;

architecture rtl of lfsr1 is
    signal p_cont_i,cont_i      : std_logic_vector (9 downto 0);
    signal feedback     : std_logic;

begin
-- Se trata de un regitro de desplazamiento hacia la derecha con una senal de enable
-- que nos permite controlar cuando se desplaza los bits, al desplazar los bits a la 
-- entrada le metemos el resultante de la operacion logica XOR de los bits 8 y 9 negado

-- Con esto hemos obtenido una secuencia de numero "Aleatorios" que se repite periodicamente

process(enable,cont_i,feedback)
	begin
	-- Si activamos el enable
      if (enable = '1') then
		 -- Desplazamos los bits a la derecha
          P_cont_i(9 downto 1) <= cont_i(8 downto 0);
		 -- Y metemos el resultado de la operacion XOR negada.
    		 p_cont_i(0)<=feedback;
	-- Si desactivamos el enable 
		else
		 -- Mantenemos el mismo valor 
			 p_cont_i<=cont_i;
      end if;
end process;

process (reset, clk) 
   begin
      if (reset = '1')then
 			cont_i <="0000000000"; 
      elsif (rising_edge(clk)) then
			cont_i<=p_cont_i;
      end if;
end process;

feedback <= not(cont_i(8) xor cont_i(9));

count <= std_logic_vector(unsigned(cont_i) + 1);

end architecture;