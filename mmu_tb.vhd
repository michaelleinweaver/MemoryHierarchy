-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity MMU_tb is
end MMU_tb;

architecture MMU_test of MMU_tb is

	-- signal declaration
	signal addr_in_cpu, addr_in_tlb : word := Zero_word;
	signal enable, tlb_found : STD_LOGIC := '0';
	signal addr_out_tlb, addr_out_ctrl : word;
	signal page_lookup_needed : STD_LOGIC;

	-- component specification
	for all : MMU use entity work.MMU(MMU_arch)
	port map(addr_in_cpu=>addr_in_cpu, addr_in_tlb=>addr_in_tlb, enable=>enable,
		 tlb_found=>tlb_found, addr_out_tlb=>addr_out_tlb, addr_out_ctrl=>addr_out_ctrl,
		 page_lookup_needed=>page_lookup_needed);

begin

	MMU1 : MMU port map(addr_in_cpu=>addr_in_cpu, addr_in_tlb=>addr_in_tlb, enable=>enable,
		 tlb_found=>tlb_found, addr_out_tlb=>addr_out_tlb, addr_out_ctrl=>addr_out_ctrl,
		 page_lookup_needed=>page_lookup_needed);

	process
	begin
		wait for 5 ns;

		-- Begin MMU testing

		-- Scenario: TLB found address

		addr_in_cpu <= (0 => '1', 1 => '1', 5 => '1', others => '0');

		addr_in_tlb <= (2 => '1', 4 => '1', 7 => '1', others => '0');

		tlb_found <= '1';

		enable <= '1';

		wait for 5 ns;

		enable <= '0';

		assert addr_out_ctrl = addr_in_tlb
			report "Output address was not equal to address given by TLB."
			severity ERROR;

		assert page_lookup_needed = '0'
			report "Page lookup was asserted when it was not necessary."
			severity ERROR;

		-- End Scenario: TLB found address

		wait for 5 ns;

		-- Scenario: TLB did not find address

		tlb_found <= '0';

		enable <= '1';

		wait for 5 ns;

		enable <= '0';

		assert addr_out_ctrl = U_word
			report "Output address was defined when it should not have been."
			severity ERROR;

		assert page_lookup_needed = '1'
			report "Page lookup was not asserted when it should have been."
			severity ERROR;

		-- End Scenario: TLB did not find address

		-- End MMU testing

		wait for 5 ns;

	end process;
end MMU_test;