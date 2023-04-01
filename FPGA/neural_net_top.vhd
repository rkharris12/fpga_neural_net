----------------------------------------------------------------------------------
-- Richie Harris
-- rkharris12@gmail.com
-- 12/29/2021
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity neural_net_top is
    port (
        
    );
end neural_net_top;

architecture rtl of neural_net_top is

    component neural_net_core is
        port (
            CLK            : in  std_logic;
            ARST_N         : in  std_logic;
            START          : in  std_logic;
            PIXEL_MEM_DATA : in  std_logic_vector(7 downto 0);
            PIXEL_MEM_ADDR : out std_logic_vector(9 downto 0);
            RESULT         : out std_logic_vector(15*16-1 downto 0); -- lsb is 0, msb is 9
            RESULT_VLD     : out std_logic
        );
    end component;

begin

    

end rtl;
