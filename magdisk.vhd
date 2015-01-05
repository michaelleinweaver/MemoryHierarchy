-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity MagDisk is
	port(
		addr_in : IN word;
		din : IN TRACK;
		reset_N : IN STD_LOGIC;
		disk_read, disk_write : IN STD_LOGIC;
		dout : OUT TRACK;
		read_complete, write_complete : OUT STD_LOGIC
	);
end MagDisk;

architecture MagDisk_arch of MagDisk is

	signal addr_sector: natural;

	signal addr_track : natural;

	signal read_latency, write_latency, clock_period : time;

	signal CONTENTS : disk_storage;

	begin

	addr_sector <= to_integer(unsigned(addr_in(29 downto 12)));

	addr_track <= to_integer(unsigned(addr_in(11 downto 9)));

	clock_period <= 2 * CLK_PERIOD;

	read_latency <= SEEK_LATENCY + ROTATE_LATENCY + SATA_LATENCY;

	write_latency <= SEEK_LATENCY + ROTATE_LATENCY + SATA_LATENCY;

	process(reset_N, disk_read, disk_write)
	begin
		if(reset_N'event and reset_N = '0')
		then
			-- For each sector, for each track of that sector, for all bytes in that track,
			-- assign all zeroes
			CONTENTS <= (others => (others => (others => Zero_byte)));

			read_complete <= '0';

			write_complete <= '0';

		elsif(disk_write'event and disk_write = '1')
		then
			CONTENTS(addr_sector)(addr_track) <= din
				after write_latency;

			-- Reset the signal after one clock period
			write_complete <= '1' after write_latency, '0' after (write_latency + clock_period);

		elsif(disk_read'event and disk_read = '1')
		then
			dout <= CONTENTS(addr_sector)(addr_track) after read_latency;

			-- Reset the signal after one clock period
			read_complete <= '1' after read_latency, '0' after (read_latency + clock_period);

		else
			null;

		end if;
	end process;

end MagDisk_arch;