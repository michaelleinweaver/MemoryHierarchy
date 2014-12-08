-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity L2Cache is
	port(
		tag_in : IN TAG;
		index_in : IN INDEX;
		din_cpu, din_mainmem : IN word;
		cache_read_mm, cache_read_cpu, cache_write_mm, cache_write_cpu : IN STD_LOGIC;
		reset_N : IN STD_LOGIC;
		dout_cpu, dout_mainmem : OUT word;
		read_complete, write_complete : OUT STD_LOGIC
	);
end L2Cache;

architecture L2Cache_arch of L2Cache is

	signal contents : CACHE;

	signal array_index, tag_value, cache_tag_value : natural;

	signal cache_entry : STD_LOGIC_VECTOR(56 downto 0);

	signal L2_SPLIT_DELAY, clock_period : time;

	begin

	L2_SPLIT_DELAY <= L2_DELAY / 3;

	clock_period <= 2 * CLK_PERIOD;

	array_index <= to_integer(unsigned(index_in));

	tag_value <= to_integer(unsigned(tag_in));

	cache_entry <= contents(array_index);

	cache_tag_value <= to_integer(unsigned(cache_entry(55 downto 32)));

	process(reset_N, cache_read_mm, cache_read_cpu, cache_write_mm, cache_write_cpu)
	begin
		if(reset_N'event and reset_N = '0')
		then
			contents <= (others => (others => '0'));

			read_complete <= '0';

			write_complete <= '0';
		
		elsif(cache_read_mm'event and cache_read_mm = '1')
		then
			if(contents(array_index)(56) = '1' and tag_value = cache_tag_value)
			then
				dout_mainmem <= cache_entry(31 downto 0) after L2_DELAY;

				-- Reset the signal after one clock period
				read_complete <= '1' after 0 ns, '0' after clock_period;

			else
				read_complete <= '0';

			end if;

		elsif(cache_read_cpu'event and cache_read_cpu = '1')
		then
			if(cache_entry(56) = '1' and tag_value = cache_tag_value)
			then
				dout_cpu <= cache_entry(31 downto 0) after L2_DELAY;

				-- Reset the signal after one clock period
				read_complete <= '1' after 0 ns, '0' after clock_period;

			else
				read_complete <= '0';

			end if;
	
		elsif(cache_write_mm'event and cache_write_mm = '1')
		then
			cache_entry(31 downto 0) <= din_mainmem after L2_SPLIT_DELAY;
			cache_entry(55 downto 32) <= tag_in after L2_SPLIT_DELAY;
			cache_entry(56) <= '1' after L2_SPLIT_DELAY;

			-- Reset the signal after one clock period
			write_complete <= '1' after 0 ns, '0' after clock_period;

		elsif(cache_write_cpu'event and cache_write_cpu = '1')
		then
			cache_entry(31 downto 0) <= din_cpu after L2_SPLIT_DELAY;
			cache_entry(55 downto 32) <= tag_in after L2_SPLIT_DELAY;
			cache_entry(56) <= '1' after L2_SPLIT_DELAY;

			-- Reset the signal after one clock period
			write_complete <= '1' after 0 ns, '0' after clock_period;

		else
			null;

		end if;
	end process;
		
end architecture;