LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;
USE work.Glob_dcls.all;

ENTITY INST_MEM IS

   	PORT (
		MemRead		: IN STD_LOGIC;
	 	MemWrite	: IN STD_LOGIC;
		d_in		: IN word;		 
	 	address		: IN word;
	 	d_out		: OUT word 
	);

END INST_MEM;


ARCHITECTURE INST_MEM_ARCH OF INST_MEM IS

	-- component declaration
	-- given in Glob_dcls.vhd

	-- component specification
	-- signal declaration

	signal addr: UNSIGNED(29 downto 0);
	
	signal MEM : RAM:=("00100000000000010000000000000001",	--   addi r1, r0, 1   -- r1 = 0; 
	                   "00000000001000010001000000100000",	--   add  r2, r1, r1  -- r2 = r1*2
	                   "10001100000000110000000001111100",	--   lw   r3, 124(r0) -- r3 = 111....11
	                   "00000000000000000010000000100100",	--   and r4, r0, r0   -- shift right r3 by r2 times (2 times r1)
			   "00010000100000100000000000000011",	--   beq  r4, r2, 3
			   "00000000000000110001100001000010",	--   srl r3, r3, 1 
 			   "00100000100001000000000000000001",	--   addi r4, r4, 1
 			   "00001000000000000000000000000100",	--   j 4
			   "00110000000001000000000000000111",	--   andi r4, r0, 7   -- shift left r3 by r1 times
			   "00010000100000010000000000000011",	--   beq  r4, r1, 3
			   "00000000000000110001100001000000",	--   sll r3, r3, 1 
			   "00100000100001000000000000000001",	--   addi r4, r4, 1
			   "00001000000000000000000000001001",	--   j 9
			   "00000000000000010010000001000000",	--   sll r4, r1, 1    -- r4 = r1*4
			   "00000000000001000010000001000000",	--   sll r4, r4, 1     	
			   "10001100100001010000000001111100", 	--   lw r5, 124(r4)   -- r5 = mem[32+r1]
	                   "00000000101000110010100000100101",  --   or r5, r5, r3    -- r5 = r5 or r3	 
	                   "10101100100001010000000001111100",	--   sw r5, 124(r4)   -- mem[32+r1] = r5	              	             
	                   "00000000000001000010000000100010",	--   sub r4, r0, r4   -- r4 = -r4   
			   "10101100100001010000000011111100",	--   sw r5, 252(r4)   -- mem[63-r1] = r5
	                   "00100000001000010000000000000001",	--   addi r1, r1, 1   -- r1 = r1 + 1  
	                   "00110100000000100000000000010000",	--   ori r2, r0, 16   -- r2 = 16
	                   "00010100001000101111111111101010",	--   bne r1, r2, -22  -- if (r1 != 16) jump back 22 instruction	to mem[1]                   
	                   "00001000000000000000000000010111",	--   j 23             -- loop back here forever 			   	   
			   "00000000010000100010100001000000",	--   	                   
	                   "00110000110001110000000000011000",	--
	                   "00000000101001000100000000100101",	--    
	                   "00000000011001000100100000100100",	--  
	                   "00001000000000000000000000010000",	--     
	                   "00000000000000000000000000000000",	--
	                   "00000000000000000000000000000000",
			   "00000000000000000000000000000000"
	);
	
BEGIN

addr <= UNSIGNED(address(31 downto 2));

memory: process(MemRead, MemWrite)
	
begin
	if MemWrite'event and MemWrite = '1' then
     		MEM(TO_INTEGER(addr)) <= d_in after WR_LATENCY;
	elsif MemRead'event and MemRead = '1' then
     		d_out <= MEM(TO_INTEGER(addr)) after RD_LATENCY;
	else
     		null;
	end if;
end process memory;

END INST_MEM_ARCH;


