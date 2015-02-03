-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity MemController is
	port(
		addr_in_mmu 					: IN word;
		controller_enable_read, controller_enable_write : IN STD_LOGIC;
		page_lookup_needed 				: IN STD_LOGIC;
		mm_page_found					: IN STD_LOGIC;
		clk						: IN STD_LOGIC;
		l2_read_complete, l2_write_complete		: IN STD_LOGIC;
		mm_read_complete, mm_write_complete		: IN STD_LOGIC;
		iobuf_read_complete, iobuf_write_complete	: IN STD_LOGIC;
		disk_read_complete, disk_write_complete		: IN STD_LOGIC;
		addr_out_cpu 					: OUT word;
		reset_N						: OUT STD_LOGIC;
		mmu_enable, mm_page_query 			: OUT STD_LOGIC;
		tlb_read, tlb_write 				: OUT STD_LOGIC;
		l2_read_mm, l2_write_mm 			: OUT STD_LOGIC;
		l2_read_cpu, l2_write_cpu 			: OUT STD_LOGIC;
		mm_read_io, mm_write_io 			: OUT STD_LOGIC;
		mm_read_cache, mm_write_cache 			: OUT STD_LOGIC;
		iobuf_read_mm, iobuf_write_mm 			: OUT STD_LOGIC;
		iobuf_read_disk, iobuf_write_disk 		: OUT STD_LOGIC;
		disk_read, disk_write 				: OUT STD_LOGIC
	);
end MemController;

architecture MemController_arch of MemController is
	signal current_state, next_state, next_state_read : STD_LOGIC_VECTOR(4 downto 0);

	signal reading, writing : STD_LOGIC;

	begin

	with addr_in_mmu(31 downto 30) select
		next_state_read <= "10000" when "11",
				   "01110" when "10",
				   "01100" when "01",
				   "01010" when others;

	-- Signal generating process
	process
	begin
		-- Initial reset_N state
		if(current_state = "00000")
		then
			next_state <= "00001";

			reset_N <= '0';

			reading <= '0';

			writing <= '0';

		-- Reset reset_N
		elsif(current_state = "00001")
		then
			next_state <= "00010";

			reset_N <= '0';

		-- Wait for activation state
		elsif(current_state = "00010")
		then
			-- Reset all signals from states that transition back to this state
			l2_read_cpu <= '0';

			l2_write_cpu <= '0';

			mm_write_cache <= '0';

			iobuf_write_mm <= '0';

			disk_write <= '0';

			if(controller_enable_read = '0' AND controller_enable_write = '0')
			then
				next_state <= "00010";

			else
				next_state <= "00011";

			end if;

		-- tlb activation state
		elsif(current_state = "00011")
		then
			next_state <= "00100";
		
			tlb_read <= '1';

		-- memory management unit activation state
		elsif(current_state = "00100")
		then
			next_state <= "00101";

			tlb_read <= '0';

			mmu_enable <= '1';

		-- fork state: if we found the page, move on to read/write fork state,
		-- otherwise look up the page in the main memory page table
		elsif(current_state = "00101")
		then
			mmu_enable <= '0';

			if(page_lookup_needed = '1')
			then
				next_state <= "00110";

			else
				next_state <= "01001";	
	
			end if;

		-- query the main memory page table for an address
		elsif(current_state = "00110")
		then
			mm_page_query <= '1';

			next_state <= "00111";

		-- check to see if we found the page
		elsif(current_state = "00111")
		then
			mm_page_query <= '0';

			if(mm_page_found = '1')
			then
				next_state <= "01000";
			
			end if;

		-- write the newly found address to the tlb, then move to the read/write fork state
		elsif(current_state = "01000")
		then
			next_state <= "01001";

			tlb_write <= '1';

		-- read/write fork state: set the next state based on whether we're reading 
		-- from or writing to the memory hierarchy
		elsif(current_state = "01001")
		then
			tlb_write <= '0';

			if(controller_enable_read = '1')
			then
				next_state <= next_state_read;

			else
				next_state <= "10001";

			end if;

		-- read from the disk to the buffer
		elsif(current_state = "01010")
		then
			if(reading /= '1')
			then
				disk_read <= '1';

				reading <= '1';

				next_state <= "01010";

			else
				if(disk_read_complete = '1')
				then
					reading <= '0';

					next_state <= "01011";

				else
					next_state <= "01010";
	
				end if;
			end if;

		-- write to the buffer
		elsif(current_state = "01011")
		then
			disk_read <= '0';

			if(writing /= '1')
			then
				iobuf_write_disk <= '1';

				writing <= '1';

				next_state <= "01011";

			else
				if(iobuf_write_complete = '1')
				then
					writing <= '0';

					next_state <= "01100";

				else
					next_state <= "01011";

				end if;
			end if;

		-- read from the buffer to main memory
		elsif(current_state = "01100")
		then
			iobuf_write_disk <= '0';

			if(reading /= '1')
			then
				iobuf_read_mm <= '1';

				reading <= '1';

				next_state <= "01100";

			else
				if(mm_read_complete = '1')
				then
					reading <= '0';

					next_state <= "01101";

				else
					next_state <= "01100";

				end if;	
			end if;

		-- write to main memory from the buffer
		elsif(current_state = "01101")
		then
			iobuf_read_mm <= '0';

			if(writing /= '1')
			then
				mm_write_io <= '1';

				writing <= '1';
				
				next_state <= "01101";

			else
				if(mm_write_complete = '1')
				then
					writing <= '0';

					next_state <= "01110";

				else
					next_state <= "01101";

				end if;
			end if;

		-- read from main memory to the l2 cache
		elsif(current_state = "01110")
		then
			mm_write_io <= '0';

			if(reading /= '1')
			then
				mm_read_cache <= '1';

				reading <= '1';
				
				next_state <= "01110";

			else
				if(mm_read_complete = '1')
				then
					reading <= '0';

					next_state <= "01111";

				else
					next_state <= "01110";

				end if;
			end if;

		-- write to the l2 cache from main memory
		elsif(current_state = "01111")
		then
			mm_read_cache <= '0';

			if(writing /= '1')
			then
				l2_write_mm <= '1';

				writing <= '1';

				next_state <= "01111";

			else
				if(l2_write_complete <= '1')
				then
					writing <= '0';

					next_state <= "10000";

				else
					next_state <= "01111";

				end if;
			end if;	

		-- read from the l2 cache to the cpu
		elsif(current_state = "10000")
		then
			l2_write_mm <= '0';

			if(reading /= '1')
			then
				reading <= '1';
				
				l2_read_cpu <= '1';

				addr_out_cpu <= addr_in_mmu;

				next_state <= "10000";

			else
				if(l2_read_complete = '1')
				then
					reading <= '0';

					next_state <= "00010";

				else
					next_state <= "10000";

				end if;
			end if;

		-- write from the cpu to the cache
		elsif(current_state = "10001")
		then
			if(writing /= '1')
			then
				writing <= '1';
		
				l2_write_cpu <= '1';

				next_state <= "10001";

			else
				if(l2_write_complete = '1')
				then
					writing <= '0';

					if(addr_in_mmu(31 downto 30) = "11")
					then
						next_state <= "00010";		

					else
						next_state <= "10010";

					end if;

				else
					next_state <= "10001";

				end if;
			end if;

		-- read from the l2 cache to main memory
		elsif(current_state = "10010")
		then
			l2_write_cpu <= '0';
	
			if(reading /= '1')
			then
				reading <= '1';
			
				l2_read_mm <= '1';

				next_state <= "10010";

			else
				if(l2_read_complete = '1')
				then
					reading <= '0';

					next_state <= "10011";

				else
					next_state <= "10010";

				end if;
			end if;

		-- write to main memory from the l2 cache
		elsif(current_state = "10011")
		then
			l2_read_mm <= '0';

			if(writing /= '1')
			then
				writing <= '1';

				mm_write_cache <= '1';

				next_state <= "10011";

			else
				if(mm_write_complete = '1')
				then
					writing <= '0';

					if(addr_in_mmu(31 downto 30) = "10")
					then
						next_state <= "00010";		

					else
						next_state <= "10100";

					end if;

				else
					next_state <= "10011";

				end if;
			end if;

		-- read from main memory to the buffer
		elsif(current_state <= "10100")
		then
			mm_write_cache <= '0';

			if(reading /= '1')
			then
				reading <= '1';
	
				mm_read_io <= '1';

				next_state <= "10100";

			else
				if(mm_read_complete = '1')
				then
					reading <= '0';

					next_state <= "10101";

				else
					next_state <= "10100";
	
				end if;
			end if;

		-- write to the buffer from main memory
		elsif(current_state <= "10101")
		then
			mm_read_io <= '0';

			if(writing /= '1')
			then
				writing <= '1';
		
				iobuf_write_mm <= '1';

				next_state <= "10101";

			else
				if(iobuf_write_complete = '1')
				then
					writing <= '0';

					if(addr_in_mmu(31 downto 30) = "11")
					then
						next_state <= "00010";		

					else
						next_state <= "10110";

					end if;

				else
					next_state <= "10101";

				end if;
			end if;

		-- read from the buffer to the disk
		elsif(current_state <= "10110")
		then
			iobuf_write_mm <= '0';

			if(reading /= '1')
			then
					reading <= '1';

					iobuf_read_disk <= '1';

					next_state <= "10110";

			else
				if(disk_read_complete = '1')
				then
					next_state <= "10111";

				else
					next_state <= "10110";

				end if;
			end if;

		-- write to the disk from the buffer
		elsif(current_state <= "10111")
		then
			iobuf_read_disk <= '0';

			if(writing /= '1')
			then
				writing <= '1';

				disk_write <= '1';

				next_state <= "10111";

			else
				if(disk_write_complete = '1')
				then
					next_state <= "00010";

				else
					next_state <= "10111";
				
				end if;
			end if;

		-- if the state is XXXXX, UUUUU, or some other underfined state, reset
		-- the controller
		else
			next_state <= "00000";

		end if;
		
		-- Wait for a change in the current state
		wait until current_state'event;
	end process;

	-- State update process
	process(clk)
	begin
		if(clk'event AND clk = '1')
		then
			current_state <= next_state;

		end if;
	end process;

end MemController_arch;