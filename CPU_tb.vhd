-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU_tb is
end CPU_tb;

architecture CPU_test of CPU_tb is
	-- component specification
	for all : CPU use entity work.CPU(CPU_arch)
	port map(clk=>clk, reset_N=>reset_N);

	-- signal declaration
	signal clk : STD_LOGIC := '0';
	signal reset_N : STD_LOGIC;

begin
	CPU1 : CPU port map(clk=>clk, reset_N=>reset_N);

	clk <= NOT clk after CLK_PERIOD;

	reset_N <= '1' after 1 ns, '0' after 2 ns, '1' after 3 ns;
end CPU_test;
