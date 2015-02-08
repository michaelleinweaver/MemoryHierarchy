-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE ieee.std_logic_1164.all;

package Glob_dcls is
	
	-- Data types 
	constant word_size : natural := 32;			
	subtype word is std_logic_vector(word_size-1 downto 0); 
	constant half_word_size : natural := 16;			
	subtype half_word is std_logic_vector(half_word_size-1 downto 0); 
	constant Byte_size : natural := 8;
	subtype Byte is std_logic_vector(Byte_size-1 downto 0);
	constant reg_addr_size : natural := 5;
	subtype reg_addr is std_logic_vector(reg_addr_size-1 downto 0);
	constant opcode_size : natural := 6;
	subtype opcode is std_logic_vector(opcode_size-1 downto 0);
	constant offset_size : natural := 16; 
	subtype offset is std_logic_vector(offset_size-1 downto 0);
	constant target_size : natural := 26;
	subtype target is std_logic_vector(target_size-1 downto 0);
	subtype ALU_opcode is std_logic_vector(2 downto 0);

  subtype RAM_ADDR is integer range 0 to 31;
  type RAM is array (RAM_ADDR) of word;

	-- First two bits of hierarchy address specify memory module
	--	00: Disk
	--	01: Buffer
	--	10: Main Memory
	--	11: L2 Cache

	-- TLB address utilizes the last nine bits of the address
	-- to map to the correct physical address
	subtype TLB_ADDR is integer range 0 to 511;
	type TLB_contents is array(TLB_ADDR) of word;

	-- Cache address is divided as follows:
		-- Bits 31 .. 30 specify the memory module
		-- Bits 29 .. 6 specify the tag
 		-- Bits 5  .. 2 specify the index (16 words)
		-- Bits 1 .. 0 specify the byte
	subtype CACHE_INDEX is integer range 0 to 15;
	subtype TAG is STD_LOGIC_VECTOR(23 downto 0);
	subtype INDEX is half_word;

	-- Entry consists of 32 bits for data, 1 valid bit, and 24 bit tag
	type CACHE is array(CACHE_INDEX) of STD_LOGIC_VECTOR(56 downto 0);

	-- Address is divided into parts:
		-- Bits 31 .. 30 specify the memory module
		-- Bits 29 .. 12 specify the sector
		-- Bits 11 .. 9 specify the track
		-- Bits 8 .. 0 specify the byte
	subtype TRACK_ADDR is integer range 0 to 7;
	subtype SECTOR_ADDR is integer range 0 to 2048;
	type TRACK is array(0 to 511) of Byte;
	type SECTOR is array (TRACK_ADDR) of TRACK;

	-- Tracks and pages are both 512 bytes: use this identifier with the
	-- I/O Buffer and Main Memory ports
	subtype PAGE is TRACK;
	subtype PAGE_RANGE is integer range 0 to 127;

	-- Include the address and a valid bit
	type page_table is array (PAGE_RANGE) of STD_LOGIC_VECTOR(8 downto 0);

	type disk_storage is array (SECTOR_ADDR) of SECTOR;

	type register_file is array (0 to word_size - 1) of word;

	-- Constants   
	constant One_word: word 	:= (others=>'1');
	constant Zero_word: word 	:= (others=>'0');
	constant Z_word: word 		:= (others=>'Z');
	constant U_word: word 		:= (others=>'U');
	constant Four_word: word	:= (2=>'1', others=>'0');
	constant Zero_byte : Byte := (others=>'0');
	constant Zero_track : STD_LOGIC_VECTOR(511 downto 0) := (others=>'0');
        
	-- Note that the actual clock period is double this, because the 
	-- simulator does CLK <= NOT CLK after this time period
  constant CLK_PERIOD		: time := 20 ns;
	constant RD_LATENCY		: time := 35 ns;	
	constant WR_LATENCY		: time := 35 ns;
	constant STABLE_DELAY : time := 2 ns;
	
	-- Disk specification: Advanced Format
			-- 7200 RPM, 1 Platter, 4 GB total, SATA III 6 Gb/s
			-- 4096 byte sectors ==> 2^20 sectors
			-- Assume 2^3 = 8 tracks/sector
			-- 2^9 bytes/sector
			-- SATA latency is average write size (512 bytes) / SATA speed
	constant ROTATE_LATENCY : time := 8000 ns;
	constant SEEK_LATENCY : time := 8000 ns;
  constant SATA_LATENCY : time := 1024 ns;
	constant SECTOR_SIZE : natural := 4096;

	constant BUFFER_READ_DELAY : time := 1000 ns;
	constant BUFFER_WRITE_DELAY : time := 2000 ns;

	constant MAIN_MEMORY_DELAY : time := 100 ns;

	-- Similiar to Intel processor L2 cache delay
	constant L2_DELAY : time := 20 ns;
	constant TLB_DELAY : time := 20 ns;
        
	-- Components
	component reg is
		port(
			 d_in    : in word;
			 clk		 : in STD_LOGIC;
			 wr_en   : in STD_LOGIC;
			 reset_N : in STD_LOGIC;
			 d_out   : out word
		);
	end component;

	component ALU is
  		port(
					op_code  : in ALU_opcode;
        	in0, in1 : in word;	
        	out1     : out word;
        	Zero     : out STD_LOGIC
  		);	
		end component;

		component RegFile is 
  	   port(
        clk, wr_en, reset_N	          : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in REG_addr;
        d_in                          : in word; 
        d_out_1, d_out_2              : out word
  	   );
		end component;
	
		component INST_MEM IS
   		port(
				MemRead	 : IN std_logic;
	 			MemWrite : IN std_logic;
	 			d_in		 : IN   word;		 
	 			address	 : IN   word;
	 			d_out		 : OUT  word 
			);
		END component;

		-- 64 KB data 
		component DATA_MEM IS
   		port(
				MemRead	 : IN std_logic;
	 			MemWrite : IN std_logic;
	 			d_in		 : IN   word;		 
	 			address	 : IN   word;
	 			d_out		 : OUT  word 
			);
		END component;

		component datapath is
  		port (
   		 	clk        : in  std_logic;
    		reset_N    : in  std_logic;
    
   		 	PCUpdate   : in  std_logic;         -- write_enable of PC

    		IorD       : in  std_logic;         -- Address selection for memory (PC vs. store address)
    		InstMemRead    : in  std_logic;		-- read_enable for memory
    		InstMemWrite   : in  std_logic;		-- write_enable for memory
		DataMemRead : in std_logic;
		DataMemWrite : in std_logic;
		addrin_mem : in word;
		din_ctrl : in word;
		DataMemLoc : in std_logic;

    		IRWrite    : in  std_logic;         -- write_enable for Instruction Register
    		MemtoReg   : in  std_logic_vector(1 downto 0);  -- selects ALU or MEMORY to write to register file.
    		RegDst     : in  std_logic_vector(1 downto 0);  -- selects rt or rd as destination of operation
    		RegWrite   : in  std_logic;         -- Register File write-enable
    		ALUSrcA    : in  std_logic_vector(1 downto 0);         -- selects source of A port of ALU
    		ALUSrcB    : in  std_logic_vector(1 downto 0);  -- selects source of B port of ALU
    
    		ALUControl : in  ALU_opcode;	-- receives ALU opcode from the controller
    		PCSource   : in  std_logic_vector(1 downto 0);  -- selects source of PC

    		opcode_out : out opcode;		-- send opcode to controller
    		func_out   : out opcode;		-- send func field to controller
   		 zero       : out std_logic;
		addr_out   : out word
		);	-- send zero to controller (cond. branch)
		end component;

		component control is 
   		port(
      		clk   	    : IN STD_LOGIC; 
      		reset_N	    : IN STD_LOGIC; 
      		opcode_in   : IN opcode;     -- declare type for the 6 most significant bits of IR
      		funct_in    : IN opcode;     -- declare type for the 6 least significant bits of IR 
     		zero        : IN STD_LOGIC;
		controller_action_complete : IN STD_LOGIC;
		addr_in     : IN word;
        
     		PCUpdate    : OUT STD_LOGIC; -- this signal controls whether PC is updated or not
     		IorD        : OUT STD_LOGIC;
     		InstMemRead : OUT STD_LOGIC;
     		InstMemWrite : OUT STD_LOGIC;
		DataMemRead : OUT STD_LOGIC;
		DataMemWrite : OUT STD_LOGIC;
     		IRWrite     : OUT STD_LOGIC;
     		MemtoReg    : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     		RegDst      : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     		RegWrite    : OUT STD_LOGIC;
     		ALUSrcA     : OUT STD_LOGIC_VECTOR (1 downto 0);
     		ALUSrcB     : OUT STD_LOGIC_VECTOR (1 downto 0);
     		ALUcontrol  : OUT ALU_opcode;
     		PCSource    : OUT STD_LOGIC_VECTOR (1 downto 0);
		controller_read_enable : OUT STD_LOGIC;
		controller_write_enable : OUT STD_LOGIC;
		addr_out : OUT word;
		DataMemLoc : OUT STD_LOGIC
		);
		end component;

		component CPU is
  		port (
    		clk     : in std_logic;
    		reset_N : in std_logic;
		controller_action_complete : in std_logic;	
		addr_in_cpu : in word;
		din_cpu : in word;
		controller_read_enable : out std_logic;
		controller_write_enable : out std_logic;
		addr_from_cpu : out word
		);
		end component;

		component L2Cache is
			port(
				tag_in : IN TAG;
				index_in : IN INDEX;
				din_cpu, din_mainmem : IN word;
				cache_read_mm, cache_read_cpu, cache_write_mm, cache_write_cpu : IN STD_LOGIC;
				reset_N : in STD_LOGIC;
				dout_cpu, dout_mainmem : OUT word;
				read_complete, write_complete : OUT STD_LOGIC
			);
		end component;

		component TLB is
  		port (
    		addr_in : in word;
				tlb_read, tlb_write, reset_N : in std_logic;
				found : out std_logic;
				addr_out : out word
				);
		end component;

		component MainMem is 
			port(
				addr_in : in word;
				page_in_buffer : in PAGE;
				din_l2cache : IN word;
				mem_read_buffer, mem_read_cache, mem_write_buffer, mem_write_cache : IN STD_LOGIC;
				page_query, reset_N : in STD_LOGIC;
				page_found : out STD_LOGIC;
				page_out_buffer : out PAGE;
				dout_l2cache : OUT word;
				read_complete, write_complete : OUT STD_LOGIC
			);
		end component;

		component MMU IS
			port(
				addr_in_cpu, addr_in_tlb : IN word;
				enable, tlb_found : in STD_LOGIC;
				addr_out_tlb, addr_out_ctrl : OUT word;
				page_lookup_needed : out std_logic
			);
		end component;

		component IOBuf is
		port(
			addr_in : IN word;
			page_in_mm : IN PAGE;
			track_in_disk : IN TRACK;
			io_read_mm, io_write_mm : IN STD_LOGIC;
			io_read_disk, io_write_disk : IN STD_LOGIC;
			reset_N : IN STD_LOGIC;
			page_out_mm : OUT PAGE;
			track_out_disk : OUT TRACK;
			read_complete, write_complete : OUT STD_LOGIC
		);
		end component;

		component MagDisk is
			port(
				addr_in : IN word;
				din : IN TRACK;
				disk_read, disk_write : IN STD_LOGIC;
				reset_N : IN STD_LOGIC;
				dout : OUT TRACK;
				read_complete, write_complete : OUT STD_LOGIC
			);
		end component;

		component MemController is
			port(
				addr_in_mmu 																		: IN word;
				addr_in_cpu	: IN word;
				controller_enable_read, controller_enable_write : IN STD_LOGIC;
				page_lookup_needed 															: IN STD_LOGIC;
				mm_page_found																		: IN STD_LOGIC;
				clk																							: IN STD_LOGIC;
				l2_read_complete, l2_write_complete							: IN STD_LOGIC;
				mm_read_complete, mm_write_complete							: IN STD_LOGIC;
				iobuf_read_complete, iobuf_write_complete				: IN STD_LOGIC;
				disk_read_complete, disk_write_complete					: IN STD_LOGIC;
				addr_out_cpu 																		: OUT word;
				addr_out_tlb : OUT word;
				reset_N																					: OUT STD_LOGIC;
				mmu_enable, mm_page_query 											: OUT STD_LOGIC;
				tlb_read, tlb_write 														: OUT STD_LOGIC;
				l2_read_mm, l2_write_mm 												: OUT STD_LOGIC;
				l2_read_cpu, l2_write_cpu 											: OUT STD_LOGIC;
				mm_read_io, mm_write_io 												: OUT STD_LOGIC;
				mm_read_cache, mm_write_cache 									: OUT STD_LOGIC;
				iobuf_read_mm, iobuf_write_mm 									: OUT STD_LOGIC;
				iobuf_read_disk, iobuf_write_disk 							: OUT STD_LOGIC;
				disk_read, disk_write 													: OUT STD_LOGIC;
				controller_action_complete : OUT STD_LOGIC		
			);
		end component;

end Glob_dcls;


