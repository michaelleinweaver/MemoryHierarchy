-- Student name: Michael Leinweaver
-- Student ID number: 67836368

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;
USE work.Glob_dcls.all;

entity ALU is 
  port( 
		op_code  : in ALU_opcode;
    in0, in1 : in word;	
		out1     : out word;
	  Zero     : out std_logic
  );
end ALU;

architecture ALU_arch of ALU is
	signal result : word;

	begin
		process(op_code, in0, in1)
		begin
			case op_code is
				when "000" =>
					out1 <= in0 + in1;

					result <= in0 + in1;

				when "001" =>
					out1 <= in0 - in1;
			
					result <= in0 - in1;

				when "010" =>
					out1 <= in0(30 downto 0) & '0';

					result <= in0(30 downto 0) & '0';
			    
				when "011" =>
					out1 <= '0' & in0(31 downto 1);

					result <= '0' & in0(31 downto 1);

				when "100" => 
					out1 <= in0 AND in1;
		
					result <= in0 AND in1;

				when "101" =>
					out1 <= in0 OR in1;

					result <= in0 OR in1;

				when "110" =>
					out1 <= in0 XOR in1;

					result <= in0 XOR in1;

				when "111" =>
					out1 <= in0 NOR in1;
		
					result <= in0 NOR in1;

				when others =>
					null;
			end case;
		end process;

		process(result)
		begin
			if(result = Zero_word)
			then
				Zero <= '1';

			else
				Zero <= '0';

			end if;
		end process;
end ALU_arch;
