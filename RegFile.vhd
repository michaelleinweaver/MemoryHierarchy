-- Student name: Michael Leinweaver
-- Student ID number: 67836368

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity RegFile is 

  port(
        clk, wr_en, reset_N	      : IN STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : IN REG_addr;
        d_in                          : IN word; 
        d_out_1, d_out_2              : OUT word
  );

end RegFile;

architecture RF_arch of RegFile is
	signal registers : register_file;

	begin
		-- write process
		process(clk, reset_N)
		begin
			if(reset_N = '0')
			then
				registers <= (others => Zero_word);

			elsif(clk = '1' AND clk'event AND wr_en = '1')
			then
				case wr_addr is
					when "00000" => registers(0) <= std_logic_vector(to_unsigned(0, word_size));
					when others => registers(to_integer(unsigned(wr_addr))) <= d_in;
				end case;

			end if;
		end process;

		with rd_addr_1 select
			d_out_1 <= registers(0) when "UUUUU",
		 	registers(to_integer(unsigned(rd_addr_1))) when others;

		with rd_addr_2 select
			d_out_2 <= registers(0) when "UUUUU",
			registers(to_integer(unsigned(rd_addr_2))) when others;
end RF_arch;
