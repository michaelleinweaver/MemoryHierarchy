-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity MemController is
	port(
		addr_in_mmu 																		: IN word;
		controller_enable_read, controller_enable_write : IN STD_LOGIC;
		page_lookup_needed 															: IN STD_LOGIC;
		mm_page_found																		: IN STD_LOGIC;
		clk																							: IN STD_LOGIC;
		addr_out_cpu 																		: OUT word;
		reset_N																					: OUT STD_LOGIC;
		mmu_enable, mm_page_query 											: OUT STD_LOGIC;
		tlb_read, tlb_write 														: OUT STD_LOGIC;
		l2_read_mm, l2_write_mm 												: OUT STD_LOGIC;
		l2_read_cpu, l2_write_cpu 											: OUT STD_LOGIC;
		mm_read_io, mm_write_io 												: OUT STD_LOGIC;
		mm_read_cache, mm_write_cache 									: OUT STD_LOGIC;
		iobuf_read_mm, iobuf_write_mm 									: OUT STD_LOGIC;
		iobuf_read_disk, iobuf_write_disk 							: OUT STD_LOGIC;
		disk_read, disk_write 													: OUT STD_LOGIC
	);
end MemController;

-- TODO Write all contents of memory back onto disk?
architecture MemController_arch of MemController is
	signal current_state, next_state, next_state_read : STD_LOGIC_VECTOR(4 downto 0);

	begin

	with addr_in_mmu(31 downto 30) select
		next_state_read <= "10000" when "11",
											 "01110" when "10",
											 "01100" when "01",
											 "01010" when others;

	-- Signal generating process
	process
	begin
		if(current_state = "00000")
		then
			next_state <= "00001";

			reset_N <= '0';

		elsif(current_state = "00001")
		then
			next_state <= "00010";

			reset_N <= '0';

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

		elsif(current_state = "00011")
		then
			next_state <= "00100";
		
			tlb_read <= '1';

		elsif(current_state = "00100")
		then
			next_state <= "00101";

			tlb_read <= '0';

			mmu_enable <= '1';

		elsif(current_state = "00101")
		then
			mmu_enable <= '0';

			if(page_lookup_needed = '1')
			then
				next_state <= "00110";

			else
				next_state <= "01001";	
	
			end if;

		elsif(current_state = "00110")
		then
			mm_page_query <= '1';

			next_state <= "00111";

		elsif(current_state = "00111")
		then
			mm_page_query <= '0';

			if(mm_page_found = '1')
			then
				next_state <= "01000";
			
			end if;

		elsif(current_state = "01000")
		then
			next_state <= "01001";

			tlb_write <= '1';

		elsif(current_state = "01001")
		then
			tlb_write <= '0';

			if(controller_enable_read = '1')
			then
				next_state <= next_state_read;

			else
				next_state <= "10001";

			end if;

		elsif(current_state = "01010")
		then
			next_state <= "01011";

			disk_read <= '1';

		elsif(current_state = "01011")
		then
			next_state <= "01100";

			disk_read <= '0';

			iobuf_write_disk <= '1';

		elsif(current_state = "01100")
		then
			next_state <= "01101";

			iobuf_write_disk <= '0';

			iobuf_read_mm <= '1';

		elsif(current_state = "01101")
		then
			next_state <= "01110";

			iobuf_read_mm <= '0';

			mm_write_io <= '1';

		elsif(current_state = "01110")
		then
			next_state <= "01111";

			mm_write_io <= '0';

			mm_read_cache <= '1';

		elsif(current_state = "01111")
		then
			next_state <= "10000";

			mm_read_cache <= '0';

			l2_write_mm <= '1';

		elsif(current_state = "10000")
		then
			next_state <= "00010";

			l2_write_mm <= '0';

			l2_read_cpu <= '1';

		elsif(current_state = "10001")
		then
			l2_write_cpu <= '1';

			if(addr_in_mmu(31 downto 30) = "11")
			then
				next_state <= "00010";		

			else
				next_state <= "10010";

			end if;

		elsif(current_state = "10010")
		then
			l2_write_cpu <= '0';

			l2_read_mm <= '1';

			next_state <= "10011";

		elsif(current_state = "10011")
		then
			l2_read_mm <= '0';
	
			mm_write_cache <= '1';

			if(addr_in_mmu(31 downto 30) = "10")
			then
				next_state <= "00010";		

			else
				next_state <= "10100";

			end if;

		elsif(current_state <= "10100")
		then
			mm_write_cache <= '0';

			mm_read_io <= '1';

			next_state <= "10101";

		elsif(current_state <= "10101")
		then
			mm_read_io <= '0';

			iobuf_write_mm <= '1';

			if(addr_in_mmu(31 downto 30) = "11")
			then
				next_state <= "00010";		

			else
				next_state <= "10110";

			end if;

		elsif(current_state <= "10110")
		then
			iobuf_write_mm <= '0';

			iobuf_read_disk <= '1';

			next_state <= "10111";

		elsif(current_state <= "10111")
		then
			iobuf_read_disk <= '0';

			disk_write <= '1';

			next_state <= "00010";

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