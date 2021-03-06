-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity IOBuf is

	port(
		addr_in 			: IN word;
		page_in_mm 			: IN page;
		track_in_disk 			: IN track;
		io_read_mm, io_write_mm 	: IN STD_LOGIC;
		io_read_disk, io_write_disk 	: IN STD_LOGIC;
		reset_N 			: IN STD_LOGIC;
		page_out_mm 			: OUT page;
		track_out_disk 			: OUT track;
		read_complete, write_complete 	: OUT STD_LOGIC
	);

end IOBuf;

architecture IOBuf_arch of IOBuf is
	
	-- Store contents as an array of words of size 128 (512 bytes / 4 bytes per word) 
	signal contents : page;

	begin

	process(reset_N, io_read_mm, io_read_disk, io_write_mm, io_write_disk)
	begin
		read_complete <= '0';

		write_complete <= '0';

		if(reset_N'event and reset_N = '0')
		then
			contents <= (others => (others => '0'));

		elsif(io_read_mm'event and io_read_mm = '1')
		then
			page_out_mm <= contents;

			read_complete <= '1' after buffer_read_delay;

		elsif(io_read_disk'event and io_read_disk = '1')
		then
			track_out_disk <= contents;	

			read_complete <= '1' after buffer_read_delay;

		elsif(io_write_mm'event and io_write_mm = '1')
		then
			contents <= page_in_mm;

			write_complete <= '1' after buffer_write_delay;

		elsif(io_write_disk'event and io_write_disk = '1')
		then
			contents <= track_in_disk;

			write_complete <= '1' after buffer_write_delay;

		else
			null;

		end if;
	end process;

end IOBuf_arch;