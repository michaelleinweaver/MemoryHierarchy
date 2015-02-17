-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE ieee.std_logic_1164.all;

package Glob_dcls is
	
	-- Data types 
	constant word_size 	: NATURAL := 32;
	constant half_word_size : NATURAL := 16;
	constant Byte_size 	: NATURAL := 8;
	constant reg_addr_size 	: NATURAL := 5;
	constant opcode_size 	: NATURAL := 6;
	constant offset_size 	: NATURAL := 16;
	constant target_size 	: NATURAL := 26;
	
	subtype word is STD_LOGIC_VECTOR(word_size-1 downto 0); 	
	subtype half_word is STD_LOGIC_VECTOR(half_word_size-1 downto 0); 
	subtype Byte is STD_LOGIC_VECTOR(Byte_size-1 downto 0);
	subtype reg_addr is STD_LOGIC_VECTOR(reg_addr_size-1 downto 0);
	subtype opcode is STD_LOGIC_VECTOR(opcode_size-1 downto 0);
	subtype offset is STD_LOGIC_VECTOR(offset_size-1 downto 0);
	subtype target is STD_LOGIC_VECTOR(target_size-1 downto 0);
	subtype ALU_opcode is STD_LOGIC_VECTOR(2 downto 0);
  	subtype ram_addr is integer range 0 to 31;
  	type RAM is array (ram_addr) of word;

	-- First two bits of hierarchy address specify memory module
	--	00: Disk
	--	01: Buffer
	--	10: Main Memory
	--	11: L2 Cache

	-- TLB address utilizes the last nine bits of the address
	-- to map to the correct physical address
	subtype tlb_addr is integer range 0 to 511;
	type TLB_contents is array(tlb_addr) of word;

	-- Cache address is divided as follows:
		-- Bits 31 .. 30 specify the memory module
		-- Bits 29 .. 6 specify the tag
 		-- Bits 5  .. 2 specify the index (16 words)
		-- Bits 1 .. 0 specify the byte
	subtype cache_index is INTEGER range 0 to 15;
	subtype tag_index is INTEGER range 23 downto 0;
	subtype tag is STD_LOGIC_VECTOR(tag_index);
	subtype index is half_word;

	-- Entry consists of 32 bits for data, 1 valid bit, and 24 bit tag
	type cache is array(cache_index) of STD_LOGIC_VECTOR(56 downto 0);

	-- Address is divided into parts:
		-- Bits 31 .. 30 specify the memory module
		-- Bits 29 .. 12 specify the sector
		-- Bits 11 .. 9 specify the track
		-- Bits 8 .. 0 specify the byte
	subtype track_addr is INTEGER range 0 to 7;
	subtype sector_addr is INTEGER range 0 to 262144;
	subtype track_index is INTEGER range 0 to 511;
	type track is array(track_index) of Byte;
	type sector is array (track_addr) of track;
	type disk_storage is array (sector_addr) of sector;

	-- Tracks and pages are both 512 bytes: use this identifier with the
	-- I/O Buffer and Main Memory ports
	subtype page is track;
	subtype page_range is INTEGER range 0 to 127;

	-- Include the address and a valid bit
	type page_table is array (page_range) of STD_LOGIC_VECTOR(8 downto 0);

	type register_file is array (0 to word_size - 1) of word;

	-- Constants   
	constant One_word	: word 	:= (others=>'1');
	constant Zero_word	: word 	:= (others=>'0');
	constant Z_word		: word 	:= (others=>'Z');
	constant U_word		: word 	:= (others=>'U');
	constant Four_word	: word	:= (2=>'1', others=>'0');
	constant Zero_byte 	: Byte 	:= (others=>'0');
	constant Zero_track 	: track := (others => (others=>'0'));
        
	-- Note that the actual clock period is double this, because the 
	-- simulator does CLK <= NOT CLK after this time period
  	constant clk_period	: TIME := 20 ns;
	constant rd_latency	: TIME := 35 ns;	
	constant wr_latency	: TIME := 35 ns;
	constant stable_delay 	: TIME := 2 ns;
	
	-- Disk specification: Advanced Format
			-- 7200 RPM, 1 Platter, 4 GB total, SATA III 6 Gb/s
			-- 4096 byte sectors ==> 2^20 sectors
			-- Assume 2^3 = 8 tracks/sector
			-- 2^9 bytes/sector
			-- SATA latency is average write size (512 bytes) / SATA speed
	constant rotate_latency : TIME := 8000 ns;
	constant seek_latency 	: TIME := 8000 ns;
  	constant sata_latency 	: TIME := 1024 ns;
	constant sector_size 	: NATURAL := 4096;

	constant buffer_read_delay 	: TIME := 1000 ns;
	constant buffer_write_delay 	: TIME := 2000 ns;

	constant main_memory_delay 	: TIME := 100 ns;

	-- Similiar to Intel processor L2 cache delay
	constant l2_delay 		: TIME := 20 ns;
	constant tlb_delay 		: TIME := 20 ns;
        
	-- Components
	component reg is
		port(
			 d_in    : IN word;
			 clk	 : IN STD_LOGIC;
			 wr_en   : IN STD_LOGIC;
			 reset_N : IN STD_LOGIC;
			 d_out   : OUT word
		);
	end component;

	component ALU is
  		port(
			op_code  : IN ALU_opcode;
        		in0, in1 : IN word;	
        		out1     : OUT word;
        		Zero     : OUT STD_LOGIC
  		);	
	end component;

	component RegFile is 
  	   	port(
        		clk, wr_en, reset_N	      : IN STD_LOGIC;
        		rd_addr_1, rd_addr_2, wr_addr : IN reg_addr;
        		d_in                          : IN word; 
        		d_out_1, d_out_2              : OUT word
  	   	);
	end component;
	
	-- 64 KB capacity
	component Inst_Mem IS
   		port(
			MemRead	 : IN STD_LOGIC;
	 		MemWrite : IN STD_LOGIC;
	 		d_in	 : IN word;		 
	 		address	 : IN word;
	 		d_out	 : OUT word 
		);
	end component;

	-- 64 KB capacity 
	component Data_Mem IS
   		port(
			MemRead	 : IN STD_LOGIC;
	 		MemWrite : IN STD_LOGIC;
	 		d_in	 : IN   word;		 
	 		address	 : IN   word;
	 		d_out	 : OUT  word 
		);
	END component;

	component datapath is
  		port (
   		 	clk        	: IN STD_LOGIC;
    			reset_N    	: IN STD_LOGIC;
   		 	PCUpdate   	: IN STD_LOGIC;         -- write_enable of PC
    			IorD       	: IN STD_LOGIC;         -- Address selection for memory (PC vs. store address)
    			InstMemRead    	: IN STD_LOGIC;		-- read_enable for memory
    			InstMemWrite   	: IN STD_LOGIC;		-- write_enable for memory
			DataMemRead 	: IN STD_LOGIC;	
			DataMemWrite 	: IN STD_LOGIC;
			addrin_mem 	: IN word;
			din_ctrl 	: IN word;
			DataMemLoc 	: IN STD_LOGIC;
    			IRWrite    	: IN STD_LOGIC;         	    	-- write_enable for Instruction Register
    			MemtoReg   	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects ALU or MEMORY to write to register file.
    			RegDst     	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects rt or rd as destination of operation
    			RegWrite   	: IN STD_LOGIC;         		-- Register File write-enable
    			ALUSrcA    	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects source of A port of ALU
    			ALUSrcB    	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects source of B port of ALU
    			ALUControl 	: IN ALU_opcode;			-- receives ALU opcode from the controller
    			PCSource   	: IN STD_LOGIC_VECTOR(1 downto 0);  	-- selects source of PC
    			opcode_out 	: OUT opcode;			     	-- send opcode to controller
    			func_out   	: OUT opcode;			     	-- send func field to controller
   			zero       	: OUT STD_LOGIC;
			addr_out   	: OUT word
		);
	end component;

	component control is 
   		port(
      			clk   	    			: IN STD_LOGIC; 
      			reset_N	    			: IN STD_LOGIC; 
      			opcode_in   			: IN opcode;     -- declare type for the 6 most significant bits of IR
      			funct_in    			: IN opcode;     -- declare type for the 6 least significant bits of IR 
     			zero        			: IN STD_LOGIC;
			controller_action_complete 	: IN STD_LOGIC;
			addr_in     			: IN word;
     			PCUpdate    			: OUT STD_LOGIC; -- this signal controls whether PC is updated or not
     			IorD         			: OUT STD_LOGIC;
     			InstMemRead  			: OUT STD_LOGIC;
     			InstMemWrite 			: OUT STD_LOGIC;
			DataMemRead 			: OUT STD_LOGIC;
			DataMemWrite 			: OUT STD_LOGIC;
     			IRWrite     			: OUT STD_LOGIC;
     			MemtoReg    			: OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     			RegDst      			: OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     			RegWrite    			: OUT STD_LOGIC;
     			ALUSrcA     			: OUT STD_LOGIC_VECTOR (1 downto 0);
     			ALUSrcB     			: OUT STD_LOGIC_VECTOR (1 downto 0);
     			ALUcontrol  			: OUT ALU_opcode;
     			PCSource    			: OUT STD_LOGIC_VECTOR (1 downto 0);
			controller_read_enable 		: OUT STD_LOGIC;
			controller_write_enable 	: OUT STD_LOGIC;
			addr_out 			: OUT word;
			DataMemLoc 			: OUT STD_LOGIC
		);
	end component;

	component CPU is
  		port (
    			clk     			: IN STD_LOGIC;
    			reset_N 			: IN STD_LOGIC;
			controller_action_complete 	: IN STD_LOGIC;	
			addr_in_cpu 			: IN word;
			din_cpu 			: IN word;
			controller_read_enable 		: OUT STD_LOGIC;
			controller_write_enable 	: OUT STD_LOGIC;
			addr_from_cpu 			: OUT word
		);
	end component;

	component L2Cache is
		port(
			tag_in 								: IN tag;
			index_in 							: IN index;
			din_cpu, din_mainmem 						: IN word;
			cache_read_mm, cache_read_cpu, cache_write_mm, cache_write_cpu 	: IN STD_LOGIC;
			reset_N 							: in STD_LOGIC;
			dout_cpu, dout_mainmem 						: OUT word;
			read_complete, write_complete 					: OUT STD_LOGIC
		);
	end component;

	component TLB is
  		port (
    			addr_in 			: IN word;
			tlb_read, tlb_write, reset_N 	: IN STD_LOGIC;
			found 				: OUT STD_LOGIC;
			addr_out 			: OUT word
		);
	end component;

	component MainMem is 
		port(
			addr_in 								: IN word;
			page_in_buffer 								: IN page;
			din_l2cache 								: IN word;
			mem_read_buffer, mem_read_cache, mem_write_buffer, mem_write_cache 	: IN STD_LOGIC;
			page_query, reset_N 							: IN STD_LOGIC;
			page_found 								: OUT STD_LOGIC;
			page_out_buffer 							: OUT page;
			dout_l2cache 								: OUT word;
			read_complete, write_complete 						: OUT STD_LOGIC
		);
	end component;

	component MMU IS
		port(
			addr_in_cpu, addr_in_tlb 	: IN word;
			enable, tlb_found 		: IN STD_LOGIC;
			addr_out_tlb, addr_out_ctrl 	: OUT word;
			page_lookup_needed 		: OUT STD_LOGIC
		);
	end component;

	component IOBuf is
		port(
			addr_in 			: IN word;
			page_in_mm 			: IN page;
			track_in_disk 			: IN track;
			io_read_mm, io_write_mm 	: IN STD_LOGIC;
			io_read_disk, io_write_disk 	: IN STD_LOGIC;
			reset_N 			: IN STD_LOGIC;
			page_out_mm 			: OUT page;
			track_out_disk 			: OUT track;
			read_complete, write_complete	: OUT STD_LOGIC
		);
	end component;

	component MagDisk is
		port(
			addr_in 			: IN word;
			din 				: IN track;
			disk_read, disk_write 		: IN STD_LOGIC;
			reset_N 			: IN STD_LOGIC;
			dout 				: OUT track;
			read_complete, write_complete 	: OUT STD_LOGIC
		);
	end component;

	component MemController is
		port(
			addr_in_mmu 					: IN word;
			addr_in_cpu					: IN word;
			controller_enable_read, controller_enable_write : IN STD_LOGIC;
			page_lookup_needed 				: IN STD_LOGIC;
			mm_page_found					: IN STD_LOGIC;
			clk						: IN STD_LOGIC;
			l2_read_complete, l2_write_complete		: IN STD_LOGIC;
			mm_read_complete, mm_write_complete		: IN STD_LOGIC;
			iobuf_read_complete, iobuf_write_complete	: IN STD_LOGIC;
			disk_read_complete, disk_write_complete		: IN STD_LOGIC;
			addr_out_cpu 					: OUT word;
			addr_out_tlb 					: OUT word;
			reset_N						: OUT STD_LOGIC;
			mmu_enable, mm_page_query 			: OUT STD_LOGIC;
			tlb_read, tlb_write 				: OUT STD_LOGIC;
			l2_read_mm, l2_write_mm 			: OUT STD_LOGIC;
			l2_read_cpu, l2_write_cpu 			: OUT STD_LOGIC;
			mm_read_io, mm_write_io 			: OUT STD_LOGIC;
			mm_read_cache, mm_write_cache 			: OUT STD_LOGIC;
			iobuf_read_mm, iobuf_write_mm 			: OUT STD_LOGIC;
			iobuf_read_disk, iobuf_write_disk 		: OUT STD_LOGIC;
			disk_read, disk_write 				: OUT STD_LOGIC;
			controller_action_complete 			: OUT STD_LOGIC		
		);
	end component;

	component Chip is
		port (
    			clk     : IN STD_LOGIC;
			reset_N : IN STD_LOGIC
		);
	end component;

end Glob_dcls;


