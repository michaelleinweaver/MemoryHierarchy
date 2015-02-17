-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;
USE work.Glob_dcls.all;

entity Data_Mem is

   	port (
		MemRead		: IN STD_LOGIC;
	 	MemWrite	: IN STD_LOGIC;
		d_in		: IN word;		 
	 	address		: IN word;
	 	d_out		: OUT word 
	);

end Data_Mem;


architecture Data_Mem_Arch of Data_Mem is

	-- component declaration
	-- given in Glob_dcls.vhd
	
	-- component specification
	-- signal declaration

	signal addr: UNSIGNED(29 downto 0);
	
	signal mem : RAM:=("00000000000000000000000000000000",
	                   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
 			   "00000000000000000000000000000000",
 			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",
			   "00000000000000000000000000000000",     	
			   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000", 
	                   "00000000000000000000000000000000",	              	             
	                   "00000000000000000000000000000000", 
			   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",                
	                   "00000000000000000000000000000000",		   	   
			   "00000000000000000000000000000000",               
	                   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",    
	                   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",   
	                   "00000000000000000000000000000000",
	                   "00000000000000000000000000000000",
			   "00000000000000000000000000000000"
	);
	
begin

	addr <= UNSIGNED(address(31 downto 2));

	process(MemRead, MemWrite)
	begin
		if MemWrite'event and MemWrite = '1' then
     			mem(TO_INTEGER(addr)) <= d_in after wr_latency;

		elsif MemRead'event and MemRead = '1' then
     			d_out <= mem(TO_INTEGER(addr)) after rd_latency;

		else
     			null;
		end if;

	end process;

end Data_Mem_Arch;


