-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity TLB_tb is
end TLB_tb;

architecture TLB_test of TLB_tb is

	-- signal declaration
	signal addr_in : word := Zero_word;
	signal tlb_read, tlb_write : STD_LOGIC := '0';
	signal reset_N : STD_LOGIC;
	signal found : STD_LOGIC;
	signal addr_out : word;
	signal found_expected : STD_LOGIC := '0';
	signal addr_out_expected : word := Zero_word;

	-- component specification
	for all : TLB use entity work.TLB(TLB_arch)
	port map(addr_in=>addr_in, tlb_read=>tlb_read, tlb_write=>tlb_write,
		 reset_N=>reset_N, found=>found, addr_out=>addr_out);

begin

	TLB1 : TLB port map(addr_in=>addr_in, tlb_read=>tlb_read, tlb_write=>tlb_write,
		 reset_N=>reset_N, found=>found, addr_out=>addr_out);

	reset_N <= '1' after 1 ns, '0' after 2 ns, '1' after 3 ns;

	process
	begin
		wait for 5 ns;

		-- Begin reset_N testing

		-- Ensure the reset signal has been acted on:
		-- 1. The found signal should be low.
		-- 2. Reading into any address should read the U_word.

		assert found = '0' 
			report "Found signal has not been reset." severity ERROR;

		wait for 5 ns;

		-- Arbitrary read address
		addr_in <= (0 => '1', 3 => '1', 24 => '1', others => '0');

		tlb_read <= '1';

		addr_out_expected <= U_word;

		wait for TLB_DELAY;

		wait for 5 ns;

		tlb_read <= '0';

		assert addr_out = addr_out_expected
			report "TLB contents were not reset." severity ERROR;

		-- End reset_N testing

		wait for 5 ns;

		-- Begin lookup testing

		-- Write arbitrary address to an arbitrary index, then read it back to ensure
		-- the address was written.

		addr_in <= (0 => '1', 3 => '1', 24 => '1', others => '0');

		addr_out_expected <= (0 => '1', 3 => '1', 24 => '1', others => '0');

		tlb_write <= '1';

		wait for TLB_DELAY;

		wait for 5 ns;

		tlb_write <= '0';

		wait for 5 ns;

		tlb_read <= '1';

		wait for TLB_DELAY;

		wait for 5 ns;

		tlb_read <= '0';

		assert addr_out = addr_out_expected 
			report "New address was not correctly written." SEVERITY ERROR;

		assert found = '1'
			report "Found signal was not correctly raised." SEVERITY ERROR;

		-- End lookup testing

		wait for 5 ns;

	end process;
end TLB_test;