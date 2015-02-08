-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity Chip is
  
  port (
    	clk     : in std_logic;
	reset_N : in std_logic
	);

end Chip;

architecture Chip_arch of Chip is
	-- signal declaration
	-- general memory hierarchy reset signal
	signal mem_reset_N : STD_LOGIC;

	-- l2 cache
	signal tag_in : TAG;
	signal index_in : INDEX;
	signal din_cpu, din_mainmem, dout_cpu, dout_mainmem : word;
	signal cache_read_mm, cache_read_cpu, cache_write_mm, cache_write_cpu : STD_LOGIC;
	signal read_complete_l2, write_complete_l2 : STD_LOGIC;

	-- main memory
	signal addr_in_mm : word;
	signal page_in_buffer, page_out_buffer : PAGE;
	signal din_l2cache, dout_l2cache : word;
	signal mem_read_buffer, mem_read_cache, mem_write_buffer, mem_write_cache : STD_LOGIC;
	signal mm_page_query, mm_page_found : STD_LOGIC;
	signal mm_read_complete, mm_write_complete : STD_LOGIC;

	-- mmu
	signal addr_in_cpu, addr_in_tlb : word;
	signal mmu_enable, tlb_addr_found : STD_LOGIC;
	signal addr_out_tlb, addr_out_ctrl : word;
	signal mm_page_lookup_needed : STD_LOGIC;

	-- tlb
	signal tlb_addr_in, tlb_addr_out : word;
	signal tlb_read, tlb_write, tlb_found : STD_LOGIC;

	-- I/O Buffer
	signal addr_in_iobuf : word;
	signal page_in_mm, page_out_mm : PAGE;
	signal track_in_disk, track_out_disk : TRACK;
	signal io_read_mm, io_write_mm, io_read_disk, io_write_disk : STD_LOGIC;
	signal io_read_complete, io_write_complete : STD_LOGIC;

	-- Magnetic disk
	signal disk_addr_in : word;
	signal disk_track_in, disk_track_out : TRACK;
	signal disk_read, disk_write : STD_LOGIC;
	signal disk_read_complete, disk_write_complete : STD_LOGIC;

	-- Memory controller
	signal controller_enable_read, controller_enable_write, controller_action_complete : STD_LOGIC;
	signal addr_from_cpu, addr_out_cpu : word;

	-- component declaration
	for all: CPU use entity work.CPU(CPU_arch)
	port map(clk=>clk, reset_N=>reset_N, controller_action_complete=>controller_action_complete,
		 addr_in_cpu=>addr_in_cpu, din_cpu=>dout_cpu, controller_read_enable=>controller_read_enable,
		 controller_write_enable=>controller_write_enable, addr_from_cpu=>addr_from_cpu);

	for all: L2Cache use entity work.L2Cache(L2Cache_arch)
	port map(tag_in=>tag_in, index_in=>index_in, din_cpu=>din_cpu, din_mainmem=>din_mainmem,
		 cache_read_mm=>cache_read_mm, cache_read_cpu=>cache_read_cpu, cache_write_mm=>cache_write_mm,
		 cache_write_cpu=>cache_write_cpu, reset_N=>mem_reset_N, dout_cpu=>dout_cpu, dout_mainmem=>dout_mainmem,
		 read_complete=>read_complete_l2, write_complete=>write_complete_l2);

	for all: TLB use entity work.TLB(TLB_arch)
	port map(addr_in=>tlb_addr_in, tlb_read=>tlb_read, tlb_write=>tlb_write, reset_N=>mem_reset_N,
		 found=>tlb_found, addr_out=>tlb_addr_out);

	for all: MainMem use entity work.MainMem(MainMem_arch)
	port map(addr_in=>addr_in_mm, page_in_buffer=>page_in_buffer, din_l2cache=>din_l2cache,
		 mem_read_buffer=>mem_read_buffer, mem_read_cache=>mem_read_cache, mem_write_buffer=>mem_write_buffer,
		 mem_write_cache=>mem_write_cache, page_query=>mm_page_query, reset_N=>mem_reset_N,
		 page_found=>mm_page_found, page_out_buffer=>page_out_buffer, dout_l2cache=>dout_l2cache,
		 read_complete=>mm_read_complete, write_complete=>mm_write_complete);
	
	for all: MMU use entity work.MMU(MMU_arch)
	port map(addr_in_cpu=>addr_in_cpu, addr_in_tlb=>addr_in_tlb, enable=>mmu_enable, tlb_found=>tlb_addr_found,
		 addr_out_tlb=>addr_out_tlb, addr_out_ctrl=>addr_out_ctrl, page_lookup_needed=>mm_page_lookup_needed);

	for all: IOBuf use entity work.IOBuf(IOBuf_arch)
	port map(addr_in=>addr_in_iobuf, page_in_mm=>page_in_mm, track_in_disk=>track_in_disk, io_read_mm=>io_read_mm,
		 io_write_mm=>io_write_mm, io_read_disk=>io_read_disk, io_write_disk=>io_write_disk, reset_N=>mem_reset_N,
		 page_out_mm=>page_out_mm, track_out_disk=>track_out_disk, read_complete=>io_read_complete, 
		 write_complete=>io_write_complete);

	for all: MagDisk use entity work.MagDisk(MagDisk_arch)
	port map(addr_in=>disk_addr_in, din=>disk_track_in, reset_N=>mem_reset_N, disk_read=>disk_read, disk_write=>disk_write,
		 dout=>disk_track_out, read_complete=>disk_read_complete, write_complete=>disk_write_complete);

	for all : MemController use entity work.MemController(MemController_arch)
	port map(addr_in_cpu=>addr_from_cpu, addr_in_mmu=>addr_out_ctrl, controller_enable_read=>controller_enable_read, controller_enable_write=>controller_enable_write,
		 page_lookup_needed=>mm_page_lookup_needed, mm_page_found=>mm_page_found, clk=>clk, l2_read_complete=>read_complete_l2,
		 l2_write_complete=>write_complete_l2, mm_read_complete=>mm_read_complete, mm_write_complete=>mm_write_complete,
		 iobuf_read_complete=>io_read_complete, iobuf_write_complete=>io_write_complete, disk_read_complete=>disk_read_complete,
		 disk_write_complete=>disk_write_complete, addr_out_cpu=>addr_out_cpu, addr_out_tlb=>addr_out_tlb, reset_N=>mem_reset_N, mmu_enable=>mmu_enable,
		 mm_page_query=>mm_page_query, tlb_read=>tlb_read, tlb_write=>tlb_write, l2_read_mm=>cache_read_mm,
		 l2_write_mm=>cache_write_mm, mm_read_io=>mem_read_buffer, mm_write_io=>mem_write_buffer, mm_read_cache=>mem_read_cache,
	  	 mm_write_cache=>mem_write_cache, iobuf_read_mm=>io_read_mm, iobuf_write_mm=>io_write_mm, iobuf_read_disk=>io_read_disk,
		 iobuf_write_disk=>io_write_disk, disk_read=>disk_read, disk_write=>disk_write, controller_action_complete=>controller_action_complete);

begin
	C1: CPU port map(clk, reset_N, controller_action_complete, addr_out_cpu, dout_cpu, controller_enable_read, controller_enable_write);

	L21: L2Cache port map(tag_in, index_in, din_cpu, din_mainmem, cache_read_mm, cache_read_cpu, 
			     cache_write_mm, cache_write_cpu, mem_reset_N, dout_cpu, dout_mainmem, 
			     read_complete_l2, write_complete_l2);

	TLB1 : TLB port map(tlb_addr_in, tlb_read, tlb_write, mem_reset_N, tlb_found, tlb_addr_out);

	MM1 : MainMem port map(addr_in_mm, page_in_buffer, din_l2cache, mem_read_buffer, mem_read_cache, mem_write_buffer,
			 mem_write_cache, mm_page_query, mem_reset_N, mm_page_found, page_out_buffer, dout_l2cache,
			 mm_read_complete, mm_write_complete);

	MMU1 : MMU port map(addr_in_cpu, addr_in_tlb, mmu_enable, tlb_addr_found, addr_out_tlb, addr_out_ctrl, mm_page_lookup_needed);

	IOBuf1: IOBUF port map(addr_in_iobuf, page_in_mm, track_in_disk, io_read_mm, io_write_mm, io_read_disk, io_write_disk,
			       mem_reset_N, page_out_mm, track_out_disk, io_read_complete, io_write_complete);
	
	Disk1: MagDisk port map(disk_addr_in, disk_track_in, mem_reset_N, disk_read, disk_write, disk_track_out, disk_read_complete,
				disk_write_complete);

	MemController1: MemController port map(addr_from_cpu, addr_out_ctrl, controller_enable_read, controller_enable_write,
		 mm_page_lookup_needed, mm_page_found, clk, read_complete_l2, write_complete_l2, mm_read_complete, mm_write_complete,
		 io_read_complete, io_write_complete, disk_read_complete, disk_write_complete, addr_out_cpu, addr_out_tlb, mem_reset_N, mmu_enable,
		 mm_page_query, tlb_read, tlb_write, cache_read_mm, cache_write_mm, mem_read_buffer, mem_write_buffer, mem_read_cache,
	  	 mem_write_cache, io_read_mm, io_write_mm, io_read_disk, io_write_disk, disk_read, disk_write, controller_action_complete);

end Chip_arch;