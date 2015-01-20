-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity L2Cache_tb is
end L2Cache_tb;

architecture L2Cache_test of L2Cache_tb is

	-- signal declaration
	signal tag_in : TAG := (others => '0');
	signal index_in : INDEX := (others => '0');
	signal din_cpu, din_mainmem : word := Zero_word;
	signal cache_read_mm, cache_write_mm : STD_LOGIC := '0';
	signal cache_read_cpu, cache_write_cpu :  STD_LOGIC := '0';
	signal reset_N : STD_LOGIC;
	signal dout_cpu, dout_mainmem :  word;
	signal read_complete, write_complete :  STD_LOGIC;
	signal dout_cpu_expected, dout_mainmem_expected : word;

	-- component specification
	for all : L2Cache use entity work.L2Cache(L2Cache_arch)
	port map(tag_in=>tag_in, index_in=>index_in, din_cpu=>din_cpu, din_mainmem=>din_mainmem,
		 cache_read_mm=>cache_read_mm, cache_read_cpu=>cache_read_cpu, 
		 cache_write_mm=>cache_write_mm, cache_write_cpu=>cache_write_cpu, reset_N=>reset_N, 
		 dout_cpu=>dout_cpu, dout_mainmem=>dout_mainmem, read_complete=>read_complete,
		 write_complete=>write_complete);

begin

	L2Cache1 : L2Cache port map(tag_in=>tag_in, index_in=>index_in, din_cpu=>din_cpu, din_mainmem=>din_mainmem,
		 cache_read_mm=>cache_read_mm, cache_read_cpu=>cache_read_cpu, 
		 cache_write_mm=>cache_write_mm, cache_write_cpu=>cache_write_cpu, reset_N=>reset_N, 
		 dout_cpu=>dout_cpu, dout_mainmem=>dout_mainmem, read_complete=>read_complete,
		 write_complete=>write_complete);

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
		tag_in <= (1 => '1', 7 => '1', 12 => '1', others => '0');

		cache_read_mm <= '1';

		dout_mainmem_expected <= (others => '0');

		wait until read_complete'event and read_complete = '1';

		cache_read_mm <= '0';

		assert dout_mainmem = dout_mainmem_expected
			report "Memory contents were not reset (Main Memory)." 
			severity ERROR;

		wait for 5 ns;

		cache_read_cpu <= '1';

		dout_cpu_expected <= (others => '0');

		wait until read_complete'event and read_complete = '1';

		cache_read_cpu <= '0';

		assert dout_cpu = dout_cpu_expected
			report "Memory contents were not reset (CPU)." 
			severity ERROR;

		-- End reset_N testing

		wait for 5 ns;

		-- Begin memory read/write testing

		-- Write arbitrary data to an arbitrary address, then read it back to ensure
		-- the data was written.

		-- CPU side

		din_cpu <= (0=>'1', 8=>'1', 9=>'1', others=>'0');

		dout_cpu_expected <= (0=>'1', 8=>'1', 9=>'1', others=>'0');

		tag_in <= (1 => '1', 8 => '1', 16 => '1', others => '0');

		cache_write_cpu <= '1';

		wait until write_complete'event and write_complete = '1';

		cache_write_cpu <= '0';

		cache_read_cpu <= '1';

		wait until read_complete'event and read_complete = '1';

		cache_read_cpu <= '0';

		assert dout_cpu = dout_cpu_expected
			report "Memory contents were not correctly written (CPU)." 
			severity ERROR;

		-- Main Memory side

		din_mainmem <= (2=>'1', 6=>'1', 10=>'1', 22=>'1', others=>'0');

		dout_mainmem_expected <= (2=>'1', 6=>'1', 10=>'1', 22=>'1', others=>'0');

		tag_in <= (0 => '1', 1 => '1', 2 => '1', others => '0');

		cache_write_mm <= '1';

		wait until write_complete'event and write_complete = '1';

		cache_write_mm <= '0';

		cache_read_mm <= '1';

		wait until read_complete'event and read_complete = '1';

		cache_read_mm <= '0';

		assert dout_mainmem = dout_mainmem_expected
			report "Memory contents were not correctly written (Main Memory)." 
			severity ERROR;		

		-- End memory read/write testing

		wait for 5 ns;

	end process;
end L2Cache_test;