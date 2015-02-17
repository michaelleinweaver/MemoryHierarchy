-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity Chip_tb is
end Chip_tb;

architecture Chip_test of Chip_tb is

	-- signal declaration
	signal clk, reset_N : STD_LOGIC;

	-- Use this signal to run the test process once only
	signal dummy : STD_LOGIC;

	-- component specification
	for all : Chip use entity work.Chip(Chip_arch)
	port map(clk=>clk, reset_N=>reset_N);

begin

	Chip1 : Chip port map(clk=>clk, reset_N=>reset_N);

	reset_N <= '1' after 1 ns, '0' after 2 ns, '1' after 3 ns;

	dummy <= '1' after 5 ns;

	process
	begin
		-- Begin general testing



		-- End general testing

		wait until dummy'event AND dummy = '0';

	end process;
end Chip_test;
