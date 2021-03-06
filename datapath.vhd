-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity datapath is
  
	port (
   		clk        	: IN STD_LOGIC;
    		reset_N    	: IN STD_LOGIC;
    		addr_in_ctrl 	: IN word;
    		PCUpdate   	: IN STD_LOGIC;	-- write_enable of PC
    		IorD       	: IN STD_LOGIC; -- Address selection for memory (PC vs. store address)
    		InstMemRead    	: IN STD_LOGIC;	-- read_enable for memory
    		InstMemWrite   	: IN STD_LOGIC;	-- write_enable for memory
    		DataMemRead 	: IN STD_LOGIC;
    		DataMemWrite 	: IN STD_LOGIC;
    		addrin_mem 	: IN word;
    		din_ctrl 	: IN word;
    		DataMemLoc 	: IN STD_LOGIC;
    		IRWrite    	: IN STD_LOGIC;         		-- write_enable for Instruction Register
    		MemtoReg   	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects ALU or MEMORY to write to register file.
    		RegDst     	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects rt or rd as destination of operation
    		RegWrite   	: IN STD_LOGIC;         		-- Register File write-enable
    		ALUSrcA    	: IN STD_LOGIC_VECTOR(1 downto 0);      -- selects source of A port of ALU
    		ALUSrcB    	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects source of B port of ALU
    		ALUControl 	: IN ALU_opcode;			-- receives ALU opcode from the controller
    		PCSource   	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects source of PC
    		opcode_out 	: OUT opcode;				-- send opcode to controller
    		func_out   	: OUT opcode;				-- send func field to controller
    		zero       	: OUT STD_LOGIC;
    		addr_out   	: OUT word
	);

end datapath;


architecture datapath_arch of datapath is
	-- signal declaration
	signal PCValue, RFout1, RFout2, RFin, ALUout, ALUout_im, SrcA, SrcB : word;
	signal IRout, PCout, MDRout, RegAout, RegBout, ALUout_val : word;
	signal mem_address, Md_out : word;
	signal rs, rt, rd : reg_addr;
	signal jump_addr, sign_extended_immediate, shifted_extended_immediate : word;
	signal data_mem_in : word;

	-- component specification
	for all : ALU use entity work.ALU(ALU_arch)
	port map(op_code=>op_code, in0=>SrcA, in1=>SrcB, out1=>ALUOut, Zero=>Zero);

	for all : RegFile use entity work.RegFile(RF_arch)
	port map(clk=>clk, wr_en=>wr_en, reset_N=>reset_N, rd_addr_1=>rs, rd_addr_2=>rt, wr_addr=>rd, 
						d_in=>d_in, d_out_1=>RFout1, d_out_2=>RFout2);

	for all : Inst_Mem use entity work.Inst_Mem(Inst_Mem_Arch)
	port map(MemRead=>MemRead, MemWrite=>MemWrite, d_in=>RegBout, address=>mem_address, d_out=>Md_out);

	for all : Data_Mem use entity work.Data_Mem(Data_Mem_Arch)
	port map(MemRead=>MemRead, MemWrite=>MemWrite, d_in=>RegBout, address=>mem_address, d_out=>Md_out);

	-- Don't port map here because each register gets a different set of inputs
	for all : reg use entity work.reg(reg_arch);

	begin
		ALU1 : ALU port map(ALUControl, SrcA, SrcB, ALUOut, Zero);

		RF1 : RegFile port map(clk, RegWrite, reset_N, rs, rt, rd, RFin, RFout1, RFout2);
	
		IM1: Inst_Mem port map(InstMemRead, InstMemWrite, regBout, mem_address, Md_out);

		DM1 : Data_Mem port map(DataMemRead, DataMemWrite, data_mem_in, mem_address, Md_out);

		ALUout_reg: reg port map(ALUout, clk, clk, reset_N, ALUout_val);

		IR: reg port map(Md_out, clk, IRWrite, reset_N, IRout);

		PC: reg port map(PCValue, clk, PCUpdate, reset_N, PCout);

		MDR: reg port map(Md_out, clk, DataMemRead, reset_N, MDRout);

		RegA: reg port map(RFout1, clk, clk, reset_N, RegAout);

		RegB: reg port map(RFout2, clk, clk, reset_N, RegBout);

		with DataMemLoc select
			data_mem_in <= din_ctrl when '1',
			        regBout when others;

		with IorD select 
			mem_address <= ALUout_val when '0',
			       PCout when others;

		with MemtoReg select
			RFin <= ALUout_val when "00",
				MDRout when "01",
				ALUout_val when others;
		
		with PCSource select
			PCValue <= ALUout_im when "00",
				ALUout_val when "01",
				jump_addr when "10",
				ALUout_im when others;
	
		with ALUSrcA select
			SrcA <=	PCout when "00",
				RegAout when "01",
				RegBout when "10",
				PCout when others;

		with ALUSrcB select
			SrcB <= RegBout when "00",
				sign_extended_immediate when "01",
				shifted_extended_immediate when "10",
				Four_word when "11",
				RegBout when others;
						
		ALUout_im <= ALUOut;

		addr_out <= ALUout_val;

		sign_extended_immediate <= (31 downto 16 => IRout(15)) & IRout(15 downto 0);

		shifted_extended_immediate <= (31 downto 18 => IRout(15)) & IRout(15 downto 0) & "00";

		jump_addr <= PCout(31 downto 28) & IRout(25 downto 0) & "00";
	
		rs <= IRout(25 downto 21);
		rt <= IRout(20 downto 16);
	
		with RegDst select
			rd <= IRout(20 downto 16) when "00",
			IRout(15 downto 11) when others;
	
		opcode_out <= IRout(31 downto 26);

		func_out <= IRout(5 downto 0);
end datapath_arch;
