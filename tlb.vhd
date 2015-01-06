-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity TLB is 
	port(
		addr_in : in word;
		tlb_read, tlb_write, reset_N : in std_logic;
		found : out std_logic;
		addr_out : out word
	);
end TLB;

architecture TLB_arch of TLB is

	signal contents : TLB_contents;

	signal index : natural;

	begin

	index <= to_integer(unsigned(addr_in(8 downto 0)));

	process(reset_N, tlb_read, tlb_write)
	begin
		if(reset_N'event and reset_N = '0')
		then
			contents <= (others => U_word);

		elsif(tlb_read'event and tlb_read = '1')
		then
			if(contents(index) /= U_word)
			then
				found <= '1';
				addr_out <= contents(index) after TLB_DELAY;

			else
				found <= '0';
				addr_out <= U_word after TLB_delay;

			end if;

		elsif(tlb_write'event and tlb_write = '1')
		then
			contents(index) <= addr_in after TLB_DELAY;

		else
			null;
	
		end if;
	end process;

end TLB_arch;