----------------------------------------------------------------------------------
-- Richie Harris
-- rkharris12@gmail.com
-- 12/29/2021
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mac is
    port (
        CLK    : in  std_logic;
        ARST_N : in  std_logic;
        CLR    : in  std_logic;
        DATA   : in  signed(15 downto 0);
        WEIGHT : in  signed(15 downto 0);
        RESULT : out std_logic_vector(15 downto 0)
    );
end mac;

architecture rtl of mac is

    constant C_MAC_WIDTH : integer := 32;

    signal product       : signed(C_MAC_WIDTH-1 downto 0);
    signal sum           : signed(C_MAC_WIDTH-1 downto 0);
    signal activation    : signed(C_MAC_WIDTH-1 downto 0);

begin

    product <= shift_left(DATA*WEIGHT, 4); -- get rid of extra integer bits
    
    process(CLK, ARST_N) begin
        if (ARST_N = '0') then
            sum <= (others => '0');
        elsif rising_edge(CLK) then
            if (CLR = '1') then
                sum <= (others => '0');
            else
                sum <= sum + product;
            end if;
        end if;
    end process;

    activation <= sum when (sum(C_MAC_WIDTH-1) = '0') else (others => '0');

    RESULT <= std_logic_vector(activation(C_MAC_WIDTH-1 downto 16));

end rtl;
