-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity MMU IS

	port(
		addr_in_cpu, addr_in_tlb 	: IN word;
		enable, tlb_found 		: in STD_LOGIC;
		addr_out_tlb, addr_out_ctrl 	: OUT word;
		page_lookup_needed 		: out STD_LOGIC
	);

end MMU;

architecture MMU_arch of MMU is
	begin

		-- Send address out to the TLB so we can check if that address exists
		addr_out_tlb <= addr_in_cpu;

		process(enable)
		begin
			if(enable'event and enable = '1')
			then
				if(tlb_found = '1')
				then
					addr_out_ctrl <= addr_in_tlb;
					page_lookup_needed <= '0';

				else
					addr_out_ctrl <= U_word;
					page_lookup_needed <= '1';

				end if;

			else
				null;

			end if;
		
		end process;

end MMU_arch;