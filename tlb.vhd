-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity TLB is 

	port(
		addr_in 			: in word;
		tlb_read, tlb_write, reset_N 	: in STD_LOGIC;
		found				: out STD_LOGIC;
		addr_out 			: out word
	);

end TLB;

architecture TLB_arch of TLB is

	signal contents : TLB_contents;

	signal index : NATURAL;

	begin
		process(reset_N, tlb_read, tlb_write)
		begin
			index <= to_integer(UNSIGNED(addr_in(8 downto 0)));

			if(reset_N'event and reset_N = '0')
			then
				contents <= (others => U_word);

				found <= '0';

			elsif(tlb_read'event and tlb_read = '1')
			then
				addr_out <= contents(index);

				if(contents(index) /= U_word)
				then
					found <= '1' after tlb_delay;

				else
					found <= '0' after tlb_delay;

				end if;

			elsif(tlb_write'event and tlb_write = '1')
			then
				contents(index) <= addr_in after tlb_delay;

			else
				null;
	
			end if;
		end process;

end TLB_arch;