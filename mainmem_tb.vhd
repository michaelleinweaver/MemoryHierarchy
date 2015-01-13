-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity MainMem_tb is
end MainMem_tb;

architecture MainMem_test of MainMem_tb is

	-- signal declaration
	signal addr_in : word := Zero_word;
	signal page_in_buffer : TRACK := (others => (others =>'0'));
	signal din_l2cache : word := Zero_word;
	signal mem_read_buffer, mem_write_buffer : STD_LOGIC := '0';
	signal mem_read_cache, mem_write_cache : STD_LOGIC := '0';
	signal page_query : STD_LOGIC := '0';
	signal reset_N : STD_LOGIC;
	signal page_found : STD_LOGIC;
	signal page_out_buffer : PAGE;
	signal dout_l2cache : word;
	signal read_complete, write_complete : STD_LOGIC;
	signal page_out_expected : page;
	signal dout_expected : word;

	-- component specification
	for all : MainMem use entity work.MainMem(MainMem_arch)
	port map(addr_in=>addr_in, page_in_buffer=>page_in_buffer, din_l2cache=>din_l2cache,
			mem_read_buffer=>mem_read_buffer, mem_read_cache=>mem_read_cache,
			mem_write_buffer=>mem_write_buffer, mem_write_cache=>mem_write_cache,
			page_query=>page_query, reset_N=>reset_N, page_found=>page_found, 
			page_out_buffer=>page_out_buffer, dout_l2cache=>dout_l2cache,
			read_complete=>read_complete, write_complete=>write_complete);

begin

	MainMem1 : MainMem port map(addr_in=>addr_in, page_in_buffer=>page_in_buffer, din_l2cache=>din_l2cache,
			mem_read_buffer=>mem_read_buffer, mem_read_cache=>mem_read_cache,
			mem_write_buffer=>mem_write_buffer, mem_write_cache=>mem_write_cache,
			page_query=>page_query, reset_N=>reset_N, page_found=>page_found, 
			page_out_buffer=>page_out_buffer, dout_l2cache=>dout_l2cache,
			read_complete=>read_complete, write_complete=>write_complete);

	reset_N <= '1' after 1 ns, '0' after 2 ns, '1' after 3 ns;

	process
	begin
		wait for 5 ns;

		-- Begin reset_N testing

		-- Ensure the reset signal has been acted on:
		-- 1. The read and write completion signals should be low.
		-- 2. Reading into any address should read 0.

		assert read_complete = '0' 
			report "Read completetion signal has not been reset." severity ERROR;

		assert write_complete = '0' 
			report "Write completetion signal has not been reset." severity ERROR;

		wait for 5 ns;

		-- Arbitrary read address
		addr_in <= (1 => '1', 5 => '1', 6 => '1', others => '0');

		mem_read_cache <= '1';

		dout_expected <= (others => '0');

		wait until read_complete'event and read_complete = '1';

		mem_read_cache <= '0';

		assert dout_l2cache = dout_expected
			report "Memory contents were not reset (cache)." severity ERROR;

		wait for 5 ns;

		mem_read_buffer <= '1';

		page_out_expected <= (others => (others => '0'));

		wait until read_complete'event and read_complete = '1';

		mem_read_buffer <= '0';

		assert page_out_buffer = page_out_expected
			report "Memory contents were not reset (buffer)." severity ERROR;

		-- End reset_N testing

		-- Begin memory read/write testing

		-- Write arbitrary data to an arbitrary address, then read it back to ensure
		-- the data was written.

		-- Buffer side

		page_in_buffer <= (others => (0=>'1', 4=>'1', 5=>'1', others=>'0'));

		page_out_expected <= (others => (0=>'1', 4=>'1', 5=>'1', others=>'0'));

		addr_in <= (1 => '1', 8 => '1', 26 => '1', others => '0');

		mem_write_buffer <= '1';

		wait until write_complete'event and write_complete = '1';

		mem_write_buffer <= '0';

		mem_read_buffer <= '1';

		wait until read_complete'event and read_complete = '1';

		mem_read_buffer <= '0';

		assert page_out_buffer = page_out_expected
			report "Memory contents were not correctly written (buffer)." severity ERROR;

		-- Cache side

		din_l2cache <= (2=>'1', 6=>'1', 10=>'1', 22=>'1', others=>'0');

		dout_expected <= (2=>'1', 6=>'1', 10=>'1', 22=>'1', others=>'0');

		addr_in <= (0 => '1', 1 => '1', 2 => '1', others => '0');

		mem_write_cache <= '1';

		wait until write_complete'event and write_complete = '1';

		mem_write_cache <= '0';

		mem_read_cache <= '1';

		wait until read_complete'event and read_complete = '1';

		mem_read_cache <= '0';

		assert dout_expected = dout_l2cache
			report "Memory contents were not correctly written (cache)." severity ERROR;		

		-- End memory read/write testing

		-- Begin page query testing

		addr_in <= (0 => '1', 1 => '1', 2 => '1', others => '0');

		page_query <= '1';

		wait until page_found'event;

		assert page_found = '1'
			report "Page table was not correctly updated." severity ERROR;

		page_query <= '0';

		-- End page query testing

		wait for 5 ns;

	end process;
end MainMem_test;