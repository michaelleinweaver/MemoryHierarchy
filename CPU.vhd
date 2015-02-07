-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU is
  
  port (
    clk     : in std_logic;
    reset_N : in std_logic
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

	-- component specification
	for all : datapath use entity work.datapath(datapath_arch)
	port map(clk=>clk, reset_N=>reset_N, PCUpdate=>PCUpdate, IorD=>IorD, InstMemRead=>InstMemRead,
						InstMemWrite=>InstMemWrite, DataMemRead=>DataMemRead, DataMemWrite=>DataMemWrite,
						IRWrite=>IRWrite, MemtoReg=>MemtoReg, RegDst=>RegDst, 
						RegWrite=>RegWrite, ALUSrcA=>ALUSrcA, ALUSrcB=>ALUSrcB, ALUControl=>ALUControl,
						PCSource=>PCSource, opcode_out=>dp_opcode, func_out=>dp_funct, zero=>zero);

	for all : control use entity work.control(control_arch)
	port map(clk=>clk, reset_N=>reset_N, opcode_in=>dp_opcode, funct_in=>dp_funct, zero=>zero, addrin_mem=>addrin_mem,
						PCUpdate=>PCUpdate, IorD=>IorD, InstMemRead=>InstMemRead, InstMemWrite=>InstMemWrite, 
						DataMemRead=>DataMemRead, DataMemWrite=>DataMemWrite, IRWrite=>IRWrite,
						MemtoReg=>MemtoReg, RegDst=>RegDst, RegWrite=>RegWrite, ALUSrcA=>ALUSrcA, ALUSrcB=>ALUSrcB,
						ALUControl=>ALUControl, PCSource=>PCSource);

	

begin
	D1: datapath port map(clk, reset_N, PCUpdate, IorD, InstMemRead, InstMemWrite, DataMemRead, DataMemWrite,
												IRWrite, MemtoReg, RegDst,
												RegWrite, ALUSrcA, ALUSrcB, ALUControl, PCSource, dp_opcode, dp_funct,
												zero);

	C1: control port map(clk, reset_N, dp_opcode, dp_funct, zero, addrin_mem, PCUpdate, IorD, InstMemRead, InstMemWrite, 
												DataMemRead, DataMemWrite, IRWrite,
												MemtoReg, RegDst, RegWrite, ALUSrcA, ALUSrcB, ALUControl, PCSource);
end CPU_arch;
