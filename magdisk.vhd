-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity MagDisk is

	port(
		addr_in 			: IN word;
		din 				: IN TRACK;
		reset_N 			: IN STD_LOGIC;
		disk_read, disk_write 		: IN STD_LOGIC;
		dout 				: OUT TRACK;
		read_complete, write_complete 	: OUT STD_LOGIC
	);

end MagDisk;

architecture MagDisk_arch of MagDisk is

	signal addr_sector, addr_track: NATURAL;

	signal disk_latency : TIME;

	signal contents : disk_storage;

	begin

		addr_sector <= to_integer(UNSIGNED(addr_in(29 downto 12)));

		addr_track <= to_integer(UNSIGNED(addr_in(11 downto 9)));

		disk_latency <= seek_latency + rotate_latency + sata_latency;

		process(reset_N, disk_read, disk_write)
		begin
			read_complete <= '0';

			write_complete <= '0';

			if(reset_N'event and reset_N = '0')
			then
				-- For each sector, for each track of that sector, for all bytes in that track,
				-- assign all zeroes
				CONTENTS <= (others => (others => (others => Zero_byte)));

			elsif(disk_write'event and disk_write = '1')
			then
				CONTENTS(addr_sector)(addr_track) <= din;

				write_complete <= '1' after disk_latency;

			elsif(disk_read'event and disk_read = '1')
			then
				dout <= CONTENTS(addr_sector)(addr_track);

				read_complete <= '1' after disk_latency;

			else
				null;

			end if;
	end process;

end MagDisk_arch;