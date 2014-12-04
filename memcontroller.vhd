-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity MemController is
	port(
		addr_in_mmu : IN word;
		controller_enable_read, controller_enable_write : IN STD_LOGIC;
		page_lookup_needed : IN STD_LOGIC;
		addr_out_cpu : OUT word;
		--mmu_enable, mm_page_query : OUT STD_LOGIC;
		--tlb_read, tlb_write : OUT STD_LOGIC;
		l2_read_mm, l2_write_mm : OUT STD_LOGIC;
		l2_read_cpu, l2_write_cpu : OUT STD_LOGIC;
		mm_read_io, mm_write_io : OUT STD_LOGIC;
		mm_read_cache, mm_write_cache : OUT STD_LOGIC;
		iobuf_read_mm, iobuf_write_mm : OUT STD_LOGIC;
		iobuf_read_disk, iobuf_write_disk : OUT STD_LOGIC;
		disk_read, disk_write : OUT STD_LOGIC
	);
end MemController;

architecture MemController_arch of MemController is
	begin

	-- TODO Write all contents of memory back onto disk?

end MemController_arch;