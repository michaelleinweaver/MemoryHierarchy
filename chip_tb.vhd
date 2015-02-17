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
	signal reset_N : STD_LOGIC;
	signal clk : STD_LOGIC := '0';

	-- component specification
	for all : Chip use entity work.Chip(Chip_arch)
	port map(clk=>clk, reset_N=>reset_N);

begin

	Chip1 : Chip port map(clk=>clk, reset_N=>reset_N);

	reset_N <= '1' after 1 ns, '0' after 2 ns, '1' after 3 ns;

	clk <= NOT clk after CLK_PERIOD;

end Chip_test;
