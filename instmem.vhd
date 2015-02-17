-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;
USE work.Glob_dcls.all;

entity Inst_Mem is

   	port (
		MemRead		: IN STD_LOGIC;
	 	MemWrite	: IN STD_LOGIC;
		d_in		: IN word;		 
	 	address		: IN word;
	 	d_out		: OUT word 
	);

end Inst_Mem;


architecture Inst_Mem_Arch of Inst_Mem is

	-- component declaration
	-- given in Glob_dcls.vhd
	
	-- component specification
	-- signal declaration

	signal addr: UNSIGNED(29 downto 0);
	
	signal MEM : RAM:=("10001100010000010000000010000000",	-- load a word from the hierarchy to r1
	                   "00100000001000100000111100001111",	-- store 00000000000000000000111100001111 in r2
	                   "10101100010000010000000010000000",	-- store the word in r2 to the hierarchy
	                   "00001000000000000000000000000011",	-- loop back here when finished
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
     			MEM(TO_INTEGER(addr)) <= d_in after wr_latency;

		elsif MemRead'event and MemRead = '1' then
     			d_out <= MEM(TO_INTEGER(addr)) after rd_latency;

		else
     			null;
		end if;

	end process;

end Inst_Mem_Arch;


