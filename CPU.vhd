-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU is
  
  	port (
   		 clk     			: in STD_LOGIC;
    		reset_N 			: in STD_LOGIC;
    		controller_action_complete 	: in STD_LOGIC;
    		addr_in_cpu 		: IN word;
    		din_cpu 			: IN word;
    		controller_read_enable 	: out STD_LOGIC;
    		controller_write_enable 	: out STD_LOGIC;
    		addr_from_cpu 		: out word
    	);

end CPU;

architecture CPU_arch of CPU is
	-- signal declaration
	signal PCUpdate, IorD, InstMemRead, InstMemWrite, DataMemRead, DataMemWrite : STD_LOGIC;
	signal IRWrite, RegWrite, zero : STD_LOGIC;
	signal dp_opcode, dp_funct : opcode;
	signal MemtoReg, RegDst, ALUSrcA, ALUSrcB, PCSource : STD_LOGIC_VECTOR(1 downto 0);
	signal ALUControl : ALU_opcode;
	signal addrin_mem : word;
	signal addrin_dp : word;
	signal DataMemLoc : STD_LOGIC;

	-- component specification
	for all : datapath use entity work.datapath(datapath_arch)
	port map(clk=>clk, reset_N=>reset_N, addr_in_ctrl=>addr_in_cpu, PCUpdate=>PCUpdate, IorD=>IorD, InstMemRead=>InstMemRead,
						InstMemWrite=>InstMemWrite, DataMemRead=>DataMemRead, DataMemWrite=>DataMemWrite, 
						addrin_mem=>addrin_mem, din_ctrl=>din_cpu, DataMemLoc=>DataMemLoc, IRWrite=>IRWrite, 
						MemtoReg=>MemtoReg, RegDst=>RegDst, RegWrite=>RegWrite, ALUSrcA=>ALUSrcA, ALUSrcB=>ALUSrcB, ALUControl=>ALUControl,
						PCSource=>PCSource, opcode_out=>dp_opcode, func_out=>dp_funct, zero=>zero,
						addr_out=>addrin_dp);

	for all : control use entity work.control(control_arch)
	port map(clk=>clk, reset_N=>reset_N, opcode_in=>dp_opcode, funct_in=>dp_funct, zero=>zero, controller_action_complete=>controller_action_complete,
						addr_in=>addrin_dp, PCUpdate=>PCUpdate, IorD=>IorD, InstMemRead=>InstMemRead, 
						InstMemWrite=>InstMemWrite, DataMemRead=>DataMemRead, DataMemWrite=>DataMemWrite, IRWrite=>IRWrite,
						MemtoReg=>MemtoReg, RegDst=>RegDst, RegWrite=>RegWrite, ALUSrcA=>ALUSrcA, ALUSrcB=>ALUSrcB,
						ALUControl=>ALUControl, PCSource=>PCSource, controller_read_enable=>controller_read_enable,
						controller_write_enable=>controller_write_enable, addr_out=>addr_from_cpu, DataMemLoc=>DataMemLoc);

	

	begin
		D1: datapath port map(clk, reset_N, PCUpdate, IorD, InstMemRead, InstMemWrite, DataMemRead, DataMemWrite, addrin_mem, din_cpu, DataMemLoc, IRWrite, MemtoReg, RegDst,
												RegWrite, ALUSrcA, ALUSrcB, ALUControl, PCSource, dp_opcode, dp_funct,
												zero, addrin_dp);

		C1: control port map(clk, reset_N, dp_opcode, dp_funct, zero, controller_action_complete, addrin_dp, PCUpdate, IorD, InstMemRead, InstMemWrite, 
												DataMemRead, DataMemWrite, IRWrite,
												MemtoReg, RegDst, RegWrite, ALUSrcA, ALUSrcB, ALUControl, PCSource, 
												controller_read_enable, controller_write_enable);
end CPU_arch;
