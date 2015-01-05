-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity MagDisk_tb is
end MagDisk_tb;

architecture MagDisk_test of MagDisk_tb is
	-- signal declaration
	signal disk_read, disk_write : STD_LOGIC := '0';
	signal addr_in : word := Zero_word;
	signal din : TRACK := (others => (others =>'0'));
	signal reset_N : STD_LOGIC;
	signal read_complete, write_complete : STD_LOGIC;
	signal dout : TRACK;
	signal dout_expected : TRACK;

	-- component specification
	for all : MagDisk use entity work.MagDisk(MagDisk_arch)
	port map(addr_in=>addr_in, din=>din, reset_N=>reset_N, disk_read=>disk_read,
					 disk_write=>disk_write, dout=>dout, read_complete=>read_complete,
					 write_complete=>write_complete);

begin
	MagDisk1 : MagDisk port map(addr_in=>addr_in, din=>din, reset_N=>reset_N, disk_read=>disk_read,
					 disk_write=>disk_write, dout=>dout, read_complete=>read_complete,
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
		addr_in <= (1 => '1', 5 => '1', 14 => '1', others => '0');

		disk_read <= '1';

		dout_expected <= (others => (others => '0'));

		wait until read_complete'event and read_complete = '1';

		disk_read <= '0';

		assert dout = dout_expected
			report "Disk contents were not reset." severity ERROR;

		-- End reset_N testing

		-- Begin disk read/write testing

		-- Write arbitrary data to an arbitrary address, then read it back to ensure
		-- the data was written.

		addr_in <= (4 => '1', 19 => '1', 22 => '1', others => '0');

		din <= (others => "11001100");

		dout_expected <= (others => "11001100");

		disk_write <= '1';

		wait until write_complete'event and write_complete = '1';

		disk_write <= '0';

		disk_read <= '1';

		wait until read_complete'event and read_complete <= '1';

		disk_read <= '0';

		assert dout = dout_expected
			report "Disk read did not result in correct data being returned" severity ERROR;

		-- End disk write testing

	end process;
end MagDisk_test;