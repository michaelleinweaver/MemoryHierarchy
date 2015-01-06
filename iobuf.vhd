-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity IOBuf is
	port(
		addr_in : IN word;
		page_in_mm : IN PAGE;
		track_in_disk : IN TRACK;
		io_read_mm, io_write_mm : IN STD_LOGIC;
		io_read_disk, io_write_disk : IN STD_LOGIC;
		reset_N : IN STD_LOGIC;
		page_out_mm : OUT PAGE;
		track_out_disk : OUT TRACK;
		read_complete, write_complete : OUT STD_LOGIC
	);
end IOBuf;

architecture IOBuf_arch of IOBuf is
	
	-- Store contents as an array of words of size 128 (512 bytes / 4 bytes per word) 
	signal contents : PAGE;

	signal clock_period : time;

	begin

	clock_period <= 2 * CLK_PERIOD;

	process(reset_N, io_read_mm, io_read_disk, io_write_mm, io_write_disk)
	begin
		if(reset_N'event and reset_N = '0')
		then
			contents <= (others => (others => '0'));

			read_complete <= '0';

			write_complete <= '0';

		elsif(io_read_mm'event and io_read_mm = '1')
		then
			page_out_mm <= contents after BUFFER_READ_DELAY;

			-- Reset the signal after one clock period
			read_complete <= '1' after BUFFER_READ_DELAY, '0' after (BUFFER_READ_DELAY + clock_period);

		elsif(io_read_disk'event and io_read_disk = '1')
		then
			track_out_disk <= contents after BUFFER_READ_DELAY;	

			-- Reset the signal after one clock period
			read_complete <= '1' after BUFFER_READ_DELAY, '0' after (BUFFER_READ_DELAY + clock_period);

		elsif(io_write_mm'event and io_write_mm = '1')
		then
			contents <= page_in_mm after BUFFER_WRITE_DELAY;

			-- Reset the signal after one clock period
			write_complete <= '1' after BUFFER_WRITE_DELAY, '0' after (BUFFER_WRITE_DELAY + clock_period);

		elsif(io_write_disk'event and io_write_disk = '1')
		then
			contents <= track_in_disk after BUFFER_WRITE_DELAY;

			-- Reset the signal after one clock period
			write_complete <= '1' after BUFFER_WRITE_DELAY, '0' after (BUFFER_WRITE_DELAY + clock_period);

		else
			null;

		end if;
	end process;

end IOBuf_arch;