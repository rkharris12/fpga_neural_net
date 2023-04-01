----------------------------------------------------------------------------------
-- Richie Harris
-- rkharris12@gmail.com
-- 12/29/2021
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity output_mem is
    port (
        CLK    : in  std_logic;
        ARST_N : in  std_logic;
        WEN    : in  std_logic;
        WDATA  : in  std_logic_vector(239 downto 0);
        RADDR  : in  unsigned(3 downto 0);
        RDATA  : out std_logic_vector(15 downto 0)
    );
end output_mem;

architecture rtl of output_mem is

    constant C_DATA_WIDTH : integer := 16;

    type slv_array_type is array (natural range <>) of std_logic_vector;
    signal ram : slv_array_type(15 downto 0)(15 downto 0);

begin

    process(CLK, ARST_N) begin
        if (ARST_N = '0') then
            ram   <= (others => (others => '0'));
            RDATA <= (others => '0');
        elsif rising_edge(CLK) then
            RDATA <= ram(to_integer(RADDR));
            if (WEN = '1') then
                ram(0)  <= x"1000"; -- bias
                --ram(1)  <= WDATA(C_DATA_WIDTH*15-1 downto C_DATA_WIDTH*14);
                --ram(2)  <= WDATA(C_DATA_WIDTH*14-1 downto C_DATA_WIDTH*13);
                --ram(3)  <= WDATA(C_DATA_WIDTH*13-1 downto C_DATA_WIDTH*12);
                --ram(4)  <= WDATA(C_DATA_WIDTH*12-1 downto C_DATA_WIDTH*11);
                --ram(5)  <= WDATA(C_DATA_WIDTH*11-1 downto C_DATA_WIDTH*10);
                --ram(6)  <= WDATA(C_DATA_WIDTH*10-1 downto C_DATA_WIDTH*9);
                --ram(7)  <= WDATA(C_DATA_WIDTH*9-1  downto C_DATA_WIDTH*8);
                --ram(8)  <= WDATA(C_DATA_WIDTH*8-1  downto C_DATA_WIDTH*7);
                --ram(9)  <= WDATA(C_DATA_WIDTH*7-1  downto C_DATA_WIDTH*6);
                --ram(10) <= WDATA(C_DATA_WIDTH*6-1  downto C_DATA_WIDTH*5);
                --ram(11) <= WDATA(C_DATA_WIDTH*5-1  downto C_DATA_WIDTH*4);
                --ram(12) <= WDATA(C_DATA_WIDTH*4-1  downto C_DATA_WIDTH*3);
                --ram(13) <= WDATA(C_DATA_WIDTH*3-1  downto C_DATA_WIDTH*2);
                --ram(14) <= WDATA(C_DATA_WIDTH*2-1  downto C_DATA_WIDTH*1);
                --ram(15) <= WDATA(C_DATA_WIDTH*1-1  downto 0);
                ram(15)  <= WDATA(C_DATA_WIDTH*15-1 downto C_DATA_WIDTH*14);
                ram(14)  <= WDATA(C_DATA_WIDTH*14-1 downto C_DATA_WIDTH*13);
                ram(13)  <= WDATA(C_DATA_WIDTH*13-1 downto C_DATA_WIDTH*12);
                ram(12)  <= WDATA(C_DATA_WIDTH*12-1 downto C_DATA_WIDTH*11);
                ram(11)  <= WDATA(C_DATA_WIDTH*11-1 downto C_DATA_WIDTH*10);
                ram(10)  <= WDATA(C_DATA_WIDTH*10-1 downto C_DATA_WIDTH*9);
                ram(9)  <= WDATA(C_DATA_WIDTH*9-1  downto C_DATA_WIDTH*8);
                ram(8)  <= WDATA(C_DATA_WIDTH*8-1  downto C_DATA_WIDTH*7);
                ram(7)  <= WDATA(C_DATA_WIDTH*7-1  downto C_DATA_WIDTH*6);
                ram(6) <= WDATA(C_DATA_WIDTH*6-1  downto C_DATA_WIDTH*5);
                ram(5) <= WDATA(C_DATA_WIDTH*5-1  downto C_DATA_WIDTH*4);
                ram(4) <= WDATA(C_DATA_WIDTH*4-1  downto C_DATA_WIDTH*3);
                ram(3) <= WDATA(C_DATA_WIDTH*3-1  downto C_DATA_WIDTH*2);
                ram(2) <= WDATA(C_DATA_WIDTH*2-1  downto C_DATA_WIDTH*1);
                ram(1) <= WDATA(C_DATA_WIDTH*1-1  downto 0);
            end if;
        end if;
    end process;

end rtl;
