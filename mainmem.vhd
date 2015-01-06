-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity MainMem is 
	port(
		addr_in : in word;
		page_in_buffer : in PAGE;
		din_l2cache : IN word;
		mem_read_buffer, mem_read_cache, mem_write_buffer, mem_write_cache : IN STD_LOGIC;
		page_query, reset_N : in STD_LOGIC;
		page_found : out STD_LOGIC;
		page_out_buffer : out PAGE;
		dout_l2cache : OUT word;
		read_complete, write_complete : OUT STD_LOGIC
	);
end MainMem;

architecture MainMem_arch of MainMem is
	
	-- Total storage is 128 words (512 Bytes / 4 bytes per word)
	signal contents : PAGE;

	signal page_table : page_table;

	-- Assume big endian
	signal byte_three, byte_two, byte_one, byte_zero : Byte;

	signal address_start : natural;

	begin

		address_start <= to_integer(unsigned(addr_in(7 downto 0)));

		process(mem_read_buffer, mem_read_cache, mem_write_buffer, mem_write_cache, page_query)
		begin
			read_complete <= '0';

			write_complete <= '0';

			if(reset_N'event and reset_N = '0')
			then
				contents <= (others => (others => '0'));

			elsif(page_query'event and page_query = '1')
			then
				if(page_table(address_start)(7 downto 0) = addr_in(7 downto 0) and
					page_table(address_start)(8) = '1')
				then
					page_found <= '1';
	
				else
					page_found <= '0';

				end if;

			elsif(mem_read_buffer'event and mem_read_buffer = '1')
			then
				page_out_buffer <= contents;

				read_complete <= '1' after MAIN_MEMORY_DELAY;

			elsif(mem_read_cache'event and mem_read_cache = '1')
			then
				byte_three <= contents(address_start);
				byte_two <= contents(address_start + 8);
				byte_one <= contents(address_start + 16);
				byte_zero <= contents(address_start + 24);

				dout_l2cache <= byte_three & byte_two & byte_one & byte_zero;

				read_complete <= '1' after MAIN_MEMORY_DELAY;

			elsif(mem_write_buffer'event and mem_write_buffer = '1')
			then
				-- Write addresses for each of the entries
				for I in 0 to 127 loop
					page_table(I) <= '1' & std_logic_vector(to_unsigned(I, 8));
				end loop;

				contents <= page_in_buffer;

				write_complete <= '1' after MAIN_MEMORY_DELAY;

			elsif(mem_write_cache'event and mem_write_cache = '1')
			then
				byte_three <= din_l2cache(31 downto 24);
				byte_two <= din_l2cache(23 downto 16);
				byte_one <= din_l2cache(15 downto 8);
				byte_zero <= din_l2cache(7 downto 0);

				contents(address_start) <= byte_three;
				contents(address_start + 8) <= byte_two;
				contents(address_start + 16) <= byte_one;
				contents(address_start + 24) <= byte_zero;	

				page_table(address_start) <= '1' & addr_in(7 downto 0);

				write_complete <= '1' after MAIN_MEMORY_DELAY;

			else
				null;

			end if;

		end process;
end MainMem_arch;