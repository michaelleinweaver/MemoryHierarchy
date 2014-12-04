-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity control is 
   port(
      clk   	    : IN STD_LOGIC; 
      reset_N	    : IN STD_LOGIC; 
      opcode_in   : IN opcode;     -- declare type for the 6 most significant bits of IR
      funct_in    : IN opcode;     -- declare type for the 6 least significant bits of IR 
     	zero        : IN STD_LOGIC;
        
     	PCUpdate    : OUT STD_LOGIC; -- this signal controls whether PC is updated or not
     	IorD        : OUT STD_LOGIC;
     	MemRead     : OUT STD_LOGIC;
     	MemWrite    : OUT STD_LOGIC;
     	IRWrite     : OUT STD_LOGIC;
     	MemtoReg    : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegDst      : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegWrite    : OUT STD_LOGIC;
     	ALUSrcA     : OUT STD_LOGIC_VECTOR (1 downto 0);
     	ALUSrcB     : OUT STD_LOGIC_VECTOR (1 downto 0);
     	ALUcontrol  : OUT ALU_opcode;
     	PCSource    : OUT STD_LOGIC_VECTOR (1 downto 0)
	);
end control;

architecture control_arch of control is
	-- signal declaration
	signal current_state, next_state, next_state_decode, next_state_mem : STD_LOGIC_VECTOR(3 downto 0);
	signal ALUimmediate_control, ALUrtype_control : ALU_opcode;
	signal ALUSrcBWhenShift : STD_LOGIC_VECTOR(1 downto 0);
	
begin
	-- Use these select statements to make the code for selecting the two sources
	-- and operation type for the ALU more compact

	-- ALU source selection logic
	with funct_in select 
		ALUSrcBWhenShift <= "10" when "000000",
										 		"10" when "000010",
										 		"01" when others;

	with current_state select
		ALUSrcA <= "00" when "0000",
						 	 "00" when "0001",
						 	 "01" when "0010",
						 	 "01" when "0100",
						 	 "01" when "0101",
						 	 "01" when "0111",
						 	 ALUSrcBWhenShift when others;

	with current_state select
		ALUSrcB <= "11" when "0000",
						 	 "10" when "0001",
						 	 "01" when "0010",
						 	 "01" when "0111",
						 	 "00" when others;

	-- ALU control logic
	with opcode_in select
		ALUimmediate_control <= "000" when "001000",
														"100" when "001100",
														"101" when others;

	with funct_in select
		ALUrtype_control <= "000" when "100000",
												"001" when "100010",
												"100" when "100100",
												"101" when "100101",
												"010" when "000000",
												"011" when "000010",
								  			ALUImmediate_control when others;

	with current_state select
		ALUControl <= "000" when "0000",
									"000" when "0001",
									"000" when "0010",
									"001" when "0100",
									"001" when "0101",
									ALUrtype_control when others;
									
	-- next state calculation
	with current_state select
		next_state <= "0001" when "0000",
									next_state_decode when "0001",
									next_state_mem when "0010",
									"1010" when "0011",
									"1011" when "0111",		
									"1100" when "1000",
									"0000" when others;	
									
	with opcode_in select
		next_state_decode <= "0010" when "100011",
												 "0010" when "101011",
												 "0011" when "000000",
												 "0100" when "000101",
												 "0101" when "000100",
												 "0110" when "000010",
												 "0111" when others;		

	with opcode_in select
		next_state_mem <= "1000" when "100011",
											"1001" when others;				

	-- signal-generating process
	process
	begin	
		-- If we're in fetch
	  if(current_state = "0000")
		then
		  RegWrite <= '0';

		  MemToReg <= "00";

			IorD <= '1';

			-- Introduce a small read delay so the PC can stabilize after short
			-- commands like jump have executed
			MemRead <= '1' after 1 ns;

			IRWrite <= '1';

			PCSource <= "00";

			PCUpdate <= '1';

		-- If we're in decode
		elsif(current_state = "0001")
		then
			IRWrite <= '0';

			IorD <= '0';

			MemRead <= '0';

			PCUpdate <= '0';

		-- If we're performing an R-Type, non-immediate
		elsif(current_state = "0011")
		then
			RegDst <= "01";

		-- If we're performing an R-Type immediate
		elsif(current_state = "0111")
		then
			RegDst <= "00";

		-- If we're performing a load specifically
		elsif(current_state = "1000")
		then
			-- Let the address stabilize
			MemRead <= '1' after 1 ns;
	
			RegDst <= "00";

		-- If we're performing a store specifically
		elsif(current_state = "1001")
		then
		  IorD <= '0' after 2 ns, '1' after 6 ns;
		  
		  MemWrite <= '1' after 4 ns, '0' after 6 ns;

		-- If we're performing a BNE
		elsif(current_state = "0100")
		then
			-- Wait for zero to stabilize
			wait for 2 ns;

			-- If these are not equal
			if(zero = '0')
			then
				PCSource <= "01";
				PCUpdate <= '1';
			
			else
				IorD <= '1';

			end if;

		-- If we're performing a BEQ
		elsif(current_state = "0101")
		then
			-- Wait for zero to stabilize
			wait for 2 ns;

			-- If these are equal
			if(zero = '1')
			then
				PCSource <= "01";
				PCUpdate <= '1';

			else
				IorD <= '1';

			end if;

		-- If we're performing a jump
		elsif(current_state = "0110")
		then
			PCSource <= "10";

			PCUpdate <= '1';

		-- If we're in the second stage of a lw
		elsif(current_state = "1100")
		then
			MemToReg <= "01";

			PCUpdate <= '0';

			MemRead <= '0';

			IorD <= '1';

			RegWrite <= '1';

		-- If we've finished execution and just need to return to fetch
		elsif(current_state = "1010" OR current_state = "1011")
		then 
			-- Prevent the PC from updating in case a garbage value is momentarily selected
			-- as the input to the PC
			PCUpdate <= '0';

			-- Prevent the memory from reading until we've returned from fetch
			MemRead <= '0';

			-- Ensure the memory has the correct address when fetching
			IorD <= '1';

			RegWrite <= '1';

		else
			null;

		end if;

		-- Wait for a change in the current state
		wait until current_state'event;
	end process;

	-- state update process
	process(clk)
	begin
	  if(clk'event AND clk = '1')
		then
			current_state <= next_state;

		end if;
	end process;
end control_arch;