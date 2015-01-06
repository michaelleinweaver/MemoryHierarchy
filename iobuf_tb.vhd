-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity IOBuf_tb is
end IOBuf_tb;

architecture IOBuf_test of IOBuf_tb is
	-- signal declaration
	signal io_read_mm, io_write_mm, io_read_disk, io_write_disk : STD_LOGIC := '0';
	signal addr_in : word := Zero_word;
	signal page_in_mm : PAGE := (others => (others => '0'));
	signal track_in_disk : TRACK := (others => (others => '0'));
	signal reset_N : STD_LOGIC;
	signal read_complete, write_complete : STD_LOGIC;
	signal track_out_disk : TRACK;
	signal track_out_expected : TRACK;
	signal page_out_mm : PAGE;
	signal page_out_expected : PAGE;

	-- component specification
	for all : IOBuf use entity work.IOBuf(IOBuf_arch)
	port map(addr_in=>addr_in, page_in_mm=>page_in_mm, track_in_disk=>track_in_disk,
			io_read_mm=>io_read_mm, io_write_mm=>io_write_mm, io_read_disk=>io_read_disk,
			io_write_disk=>io_write_disk, reset_N=>reset_N, page_out_mm=>page_out_mm, 
			track_out_disk=>track_out_disk, read_complete=>read_complete, 
			write_complete=>write_complete);

begin
	IOBuf1 : IOBuf port map(addr_in=>addr_in, page_in_mm=>page_in_mm, track_in_disk=>track_in_disk,
			io_read_mm=>io_read_mm, io_write_mm=>io_write_mm, io_read_disk=>io_read_disk,
			io_write_disk=>io_write_disk, reset_N=>reset_N, page_out_mm=>page_out_mm, 
			track_out_disk=>track_out_disk, read_complete=>read_complete, 
			write_complete=>write_complete);


	reset_N <= '1' after 1 ns, '0' after 2 ns, '1' after 3 ns;

	process
	begin
		wait for 5 ns;

		-- Begin reset_N testing

		-- Ensure the reset signal has been acted on:
		-- 1. The read and write completion signals should be low.
		-- 2. Reading into any address should read 0 from mm output and disk output.

		assert read_complete = '0' 
			report "Read completetion signal has not been reset." severity ERROR;

		assert write_complete = '0' 
			report "Write completetion signal has not been reset." severity ERROR;

		wait for 5 ns;

		-- Arbitrary read address
		addr_in <= (1 => '1', 5 => '1', 14 => '1', others => '0');

		io_read_mm <= '1';

		page_out_expected <= (others => (others => '0'));

		wait until read_complete'event and read_complete = '1';

		io_read_mm <= '0';

		assert page_out_mm = page_out_expected
			report "Buffer contents were not reset (mm output)." severity ERROR;

		io_read_disk <= '1';

		track_out_expected <= (others => (others => '0'));

		wait until read_complete'event and read_complete = '1';

		io_read_disk <= '0';

		assert track_out_disk = track_out_expected
			report "Buffer contents were not reset (disk output)." severity ERROR;

		-- End reset_N testing

		-- Begin mm read/write testing

		-- Write arbitrary data to an arbitrary address, then read it back to ensure
		-- the data was written.

		addr_in <= (7 => '1', 12 => '1', 14 => '1', others => '0');

		page_in_mm <= (others => "11110000");

		page_out_expected <= page_in_mm;

		io_write_mm <= '1';

		wait until write_complete'event and write_complete = '1';

		io_write_mm <= '0';

		io_read_mm <= '1';

		wait until read_complete'event and read_complete = '1';

		io_read_mm <= '0';

		assert page_out_mm = page_out_expected
			report "Read page was not equal to expected value (mm output)" severity ERROR;

		-- End mm read/write testing

		-- Begin disk read/write testing

		addr_in <= (4 => '1', 16 => '1', 23 => '1', others => '0');

		track_in_disk <= (others => "11110000");

		track_out_expected <= track_in_disk;

		io_write_disk <= '1';

		wait until write_complete'event and write_complete = '1';

		io_write_disk <= '0';

		io_read_disk <= '1';

		wait until read_complete'event and read_complete = '1';

		io_read_disk <= '0';

		assert track_out_disk = track_out_expected
			report "Read page was not equal to expected value (mm output)" severity ERROR;

		-- End disk read/write testing

	end process;
end IOBuf_test;