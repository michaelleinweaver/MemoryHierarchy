-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity L2Cache is

	port(
		tag_in 								: IN tag;
		index_in 							: IN index;
		din_cpu, din_mainmem 						: IN word;
		cache_read_mm, cache_read_cpu, cache_write_mm, cache_write_cpu 	: IN STD_LOGIC;
		reset_N 							: IN STD_LOGIC;
		dout_cpu, dout_mainmem 						: OUT word;
		read_complete, write_complete 					: OUT STD_LOGIC
	);

end L2Cache;

architecture L2Cache_arch of L2Cache is

	signal contents : cache;

	signal array_index, tag_value, cache_tag_value : NATURAL;

	begin
		process(reset_N, cache_read_mm, cache_read_cpu, cache_write_mm, cache_write_cpu)
		begin
			read_complete <= '0';

			write_complete <= '0';

			array_index <= to_integer(UNSIGNED(index_in));

			tag_value <= to_integer(UNSIGNED(tag_in));

			cache_tag_value <= to_integer(UNSIGNED(contents(array_index)(55 downto 32)));

			if(reset_N'event and reset_N = '0')
			then
				contents <= (others => (others => '0'));
		
			elsif(cache_read_mm'event and cache_read_mm = '1')
			then
				dout_mainmem <= contents(array_index)(31 downto 0);

				read_complete <= '1' after l2_delay;

			elsif(cache_read_cpu'event and cache_read_cpu = '1')
			then
				dout_cpu <= contents(array_index)(31 downto 0);

				read_complete <= '1' after l2_delay;

			elsif(cache_write_mm'event and cache_write_mm = '1')
			then
				contents(array_index)(31 downto 0) <= din_mainmem;
				contents(array_index)(55 downto 32) <= tag_in;
				contents(array_index)(56) <= '1';

				write_complete <= '1' after l2_delay;

			elsif(cache_write_cpu'event and cache_write_cpu = '1')
			then
				contents(array_index)(31 downto 0) <= din_cpu;
				contents(array_index)(55 downto 32) <= tag_in;
				contents(array_index)(56) <= '1';

				write_complete <= '1' after l2_delay;

			else
				null;

			end if;
		end process;
		
end L2Cache_arch;