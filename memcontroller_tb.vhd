-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity MemController_tb is
end MemController_tb;

architecture MemController_test of MemController_tb is

	-- signal declaration
	signal addr_in_mmu 					: word := Zero_word;
	signal controller_enable_read, controller_enable_write 	: STD_LOGIC := '0';
	signal page_lookup_needed 				: STD_LOGIC := '0';
	signal mm_page_found					: STD_LOGIC := '0';
	signal clk						: STD_LOGIC := '0';
	signal l2_read_complete, l2_write_complete		: STD_LOGIC := '0';
	signal mm_read_complete, mm_write_complete		: STD_LOGIC := '0';
	signal iobuf_read_complete, iobuf_write_complete	: STD_LOGIC := '0';
	signal disk_read_complete, disk_write_complete		: STD_LOGIC := '0';
	signal addr_out_cpu 					: word;
	signal reset_N						: STD_LOGIC;
	signal mmu_enable, mm_page_query 			: STD_LOGIC;
	signal tlb_read, tlb_write 				: STD_LOGIC;
	signal l2_read_mm, l2_write_mm 				: STD_LOGIC;
	signal l2_read_cpu, l2_write_cpu 			: STD_LOGIC;
	signal mm_read_io, mm_write_io 				: STD_LOGIC;
	signal mm_read_cache, mm_write_cache 			: STD_LOGIC;
	signal iobuf_read_mm, iobuf_write_mm 			: STD_LOGIC;
	signal iobuf_read_disk, iobuf_write_disk 		: STD_LOGIC;
	signal disk_read, disk_write 				: STD_LOGIC;

	-- component specification
	for all : MemController use entity work.MemController(MemController_arch)
	port map(addr_in_mmu=>addr_in_mmu, controller_enable_read=>controller_enable_read, 
		 controller_enable_write=>controller_enable_write, page_lookup_needed=>page_lookup_needed,
		 mm_page_found=>mm_page_found, clk=>clk, l2_read_complete=>l2_read_complete,
		 l2_write_complete=>l2_write_complete, mm_read_complete=>mm_read_complete,
		 mm_write_complete=>mm_write_complete, iobuf_read_complete=>iobuf_read_complete,
		 iobuf_write_complete=>iobuf_write_complete, disk_read_complete=>disk_read_complete,
		 disk_write_complete=>disk_write_complete, addr_out_cpu=>addr_out_cpu, reset_N=>reset_N,
		 mmu_enable=>mmu_enable, mm_page_query=>mm_page_query, tlb_read=>tlb_read, tlb_write=>tlb_write,
		 l2_read_mm=>l2_read_mm, l2_write_mm=>l2_write_mm, l2_read_cpu=>l2_read_cpu,
		 l2_write_cpu=>l2_write_cpu, mm_read_io=>mm_read_io, mm_write_io=>mm_write_io,
		 mm_read_cache=>mm_read_cache, mm_write_cache=>mm_write_cache,
		 iobuf_read_mm=>iobuf_read_mm, iobuf_write_mm=>iobuf_write_mm, iobuf_read_disk=>iobuf_read_disk,
		 iobuf_write_disk=>iobuf_write_disk, disk_read=>disk_read, disk_write=>disk_write);

begin

	MemController1 : MemController port map(addr_in_mmu=>addr_in_mmu, controller_enable_read=>controller_enable_read, 
		 controller_enable_write=>controller_enable_write, page_lookup_needed=>page_lookup_needed,
		 mm_page_found=>mm_page_found, clk=>clk, l2_read_complete=>l2_read_complete,
		 l2_write_complete=>l2_write_complete, mm_read_complete=>mm_read_complete,
		 mm_write_complete=>mm_write_complete, iobuf_read_complete=>iobuf_read_complete,
		 iobuf_write_complete=>iobuf_write_complete, disk_read_complete=>disk_read_complete,
		 disk_write_complete=>disk_write_complete, addr_out_cpu=>addr_out_cpu, reset_N=>reset_N,
		 mmu_enable=>mmu_enable, mm_page_query=>mm_page_query, tlb_read=>tlb_read, tlb_write=>tlb_write,
		 l2_read_mm=>l2_read_mm, l2_write_mm=>l2_write_mm, l2_read_cpu=>l2_read_cpu,
		 l2_write_cpu=>l2_write_cpu, mm_read_io=>mm_read_io, mm_write_io=>mm_write_io,
		 mm_read_cache=>mm_read_cache, mm_write_cache=>mm_write_cache,
		 iobuf_read_mm=>iobuf_read_mm, iobuf_write_mm=>iobuf_write_mm, iobuf_read_disk=>iobuf_read_disk,
		 iobuf_write_disk=>iobuf_write_disk, disk_read=>disk_read, disk_write=>disk_write);

	clk <= NOT clk after CLK_PERIOD;

	process
	begin
		-- Begin reset_N mechanism test

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';		

		wait for 2 ns;

		assert reset_N = '0' report "Reset_N incorrect initial value (0)" severity ERROR;

		wait until clk'event and clk = '1';

		wait for 2 ns;

		assert reset_N = '1' report "Reset_N incorrect stabilization (1)" severity ERROR;

		wait until clk'event and clk = '1';

		-- End reset_N mechanism test

		-- Begin read test, assume address not in TLB and contents in disk

		controller_enable_read <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		wait for 2 ns;

		assert tlb_read = '1' report "TLB not issued read command" severity ERROR;

		wait until clk'event and clk = '1';

		wait for 2 ns;

		assert mmu_enable = '1' report "MMU not issued enable command" severity ERROR;

		page_lookup_needed <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		page_lookup_needed <= '0';

		wait for 2 ns;

		assert mm_page_query = '1' report "MM not issued page query command" severity ERROR;

		mm_page_found <= '1';

		addr_in_mmu <= (others => '0');

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		mm_page_found <= '0';

		wait for 2 ns;

		assert tlb_write = '1' report "TLB not issued write command for update" severity ERROR;

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		wait for 2 ns;

		assert disk_read = '1' report "Disk not issued read command to IOBUF" severity ERROR;

		wait until clk'event and clk = '0';

		disk_read_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		disk_read_complete <= '0';

		wait for 2 ns;

		assert iobuf_write_disk = '1' report "Buffer not issued read from disk command" 
			severity ERROR;

		wait until clk'event and clk = '0';

		iobuf_write_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		iobuf_write_complete <= '0';

		wait for 2 ns;

		assert iobuf_read_mm = '1' report "Buffer not issued read command to mm"
			severity ERROR;

		wait until clk'event and clk = '0';

		iobuf_read_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		iobuf_read_complete <= '0';

		wait for 2 ns;

		assert mm_write_io = '1' report "MM not issued write command from buffer"
			severity ERROR;

		wait until clk'event and clk = '0';

		mm_write_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		mm_write_complete <= '0';

		wait for 2 ns;

		assert mm_read_cache = '1' report "MM not issued read command to cache"
			severity ERROR;

		wait until clk'event and clk = '0';

		mm_read_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		mm_read_complete <= '0';

		wait for 2 ns;

		assert l2_write_mm = '1' report "L2 not issued write command from MM"
			severity ERROR;

		wait until clk'event and clk = '0';

		l2_write_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		l2_write_complete <= '0';

		wait for 2 ns;

		assert l2_read_cpu = '1' report "L2 not issused read command to CPU"
			severity ERROR;

		wait until clk'event and clk = '0';

		l2_read_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		controller_enable_write <= '1';

		l2_read_complete <= '0';

		controller_enable_read <= '0';

		-- End read test

		-- Begin write test, assume address in TLB and contents in L2

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		wait for 2 ns;

		assert tlb_read = '1' report "TLB not issued read command" severity ERROR;

		wait until clk'event and clk = '1';

		wait for 2 ns;

		assert mmu_enable = '1' report "MMU not issued enable command" severity ERROR;

		page_lookup_needed <= '0';

		addr_in_mmu <= (0=>'1', others => '0');

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';
		
		wait for 2 ns;

		assert l2_write_cpu = '1' report "L2 not issued write command from CPU"
			severity ERROR;

		wait until clk'event and clk = '0';

		l2_write_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';
		
		l2_write_complete <= '0';

		wait for 2 ns;

		assert l2_read_mm = '1' report "L2 not issued read command to MM"
			severity ERROR;

		addr_in_mmu <= (0=>'0', 1=>'1', others => '0');

		wait until clk'event and clk = '0';

		l2_read_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		l2_read_complete <= '0';

		wait for 2 ns;

		assert mm_write_cache = '1' report "MM not issued write command from L2"
			severity ERROR;

		wait until clk'event and clk = '0';

		addr_in_mmu <= (others => '0');

		mm_write_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		mm_write_complete <= '0';

		wait for 2 ns;

		assert mm_read_io = '1' report "MM not issued read command to IO"
			severity ERROR;

		wait until clk'event and clk = '0';

		mm_read_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		mm_read_complete <= '0';

		wait for 2 ns;

		assert iobuf_write_mm = '1' report "IOBuf not issued write command from MM"
			severity ERROR;

		wait until clk'event and clk = '0';

		iobuf_write_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		iobuf_write_complete <= '0';

		wait for 2 ns;

		assert iobuf_read_disk = '1' report "IOBuf not issued read command to disk"
			severity ERROR;

		wait until clk'event and clk = '0';

		iobuf_read_complete <= '1';

		wait until clk'event and clk = '1';

		wait until clk'event and clk = '1';

		iobuf_read_complete <= '0';

		wait for 2 ns;

		assert disk_write = '1' report "Disk not issued write command from IOBuf"
			severity ERROR;

		controller_enable_write <= '0'; 

		wait until clk'event and clk = '1';

		-- End write test

	end process;
end MemController_test;