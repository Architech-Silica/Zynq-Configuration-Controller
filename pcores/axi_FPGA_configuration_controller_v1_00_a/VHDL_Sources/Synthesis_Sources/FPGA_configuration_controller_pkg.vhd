library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.all;

package FPGA_configuration_controller_pkg is
    function log2(x : natural) return integer;
end FPGA_configuration_controller_pkg;

package body FPGA_configuration_controller_pkg is


-------------------------------------------------------------------------------
-- Function log2 -- returns number of bits needed to encode x choices
--   x = 0  returns 0
--   x = 1  returns 0
--   x = 2  returns 1
--   x = 4  returns 2, etc.
-------------------------------------------------------------------------------
function log2(x : natural) return integer is
  variable i  : integer := 0; 
  variable val: integer := 1;
begin 
  if x = 0 then return 0;
  else
    for j in 0 to 8 loop -- for loop for XST 
      if val >= x then null; 
      else
        i := i+1;
        val := val*2;
      end if;
    end loop;
    return i-1;
  end if;  
end function log2; 

end package body FPGA_configuration_controller_pkg;
