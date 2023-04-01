----------------------------------------------------------------------------------
-- Richie Harris
-- rkharris12@gmail.com
-- 12/29/2021
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity neural_net_core is
    port (
        CLK            : in  std_logic;
        ARST_N         : in  std_logic;
        START          : in  std_logic;
        PIXEL_MEM_DATA : in  std_logic_vector(7 downto 0);
        PIXEL_MEM_ADDR : out std_logic_vector(9 downto 0);
        RESULT         : out std_logic_vector(15*16-1 downto 0); -- lsb is 0, msb is 9
        RESULT_VLD     : out std_logic
    );
end neural_net_core;

architecture rtl of neural_net_core is

    component w1_mem is
        port (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(239 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(239 DOWNTO 0)
        );
    end component;

    component w2_mem IS
        PORT (
            a : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            d : IN STD_LOGIC_VECTOR(239 DOWNTO 0);
            clk : IN STD_LOGIC;
            we : IN STD_LOGIC;
            qspo : OUT STD_LOGIC_VECTOR(239 DOWNTO 0)
        );
    END component;

    component w3_mem IS
        PORT (
            a : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            d : IN STD_LOGIC_VECTOR(239 DOWNTO 0);
            clk : IN STD_LOGIC;
            we : IN STD_LOGIC;
            qspo : OUT STD_LOGIC_VECTOR(239 DOWNTO 0)
        );
    END component;

    component output_mem is
        port (
            CLK    : in  std_logic;
            ARST_N : in  std_logic;
            WEN    : in  std_logic;
            WDATA  : in  std_logic_vector(239 downto 0);
            RADDR  : in  unsigned(3 downto 0);
            RDATA  : out std_logic_vector(15 downto 0)
        );
    end component;

    component mac is
        port (
            CLK    : in  std_logic;
            ARST_N : in  std_logic;
            CLR    : in  std_logic;
            DATA   : in  signed(15 downto 0);
            WEIGHT : in  signed(15 downto 0);
            RESULT : out std_logic_vector(15 downto 0)
        );
    end component;

    constant C_DATA_WIDTH         : integer := 16;
    constant C_MAC_WIDTH          : integer := 32;
    constant C_MUL_INPUT_CYCLES   : integer := 256;
    constant C_MUL_HIDDEN_CYCLES  : integer := 15;
    constant C_HIDDEN_LAYER_WIDTH : integer := C_DATA_WIDTH*C_MUL_HIDDEN_CYCLES;

    type state_type is (E_IDLE, E_MUL1, E_WB1, E_CLR1,  E_MUL2, E_WB2, E_CLR2,  E_MUL3, E_DONE);
    signal state                  : state_type;
    signal mem_addr               : unsigned(9 downto 0);
    signal result_mem_we          : std_logic;
    type slv_array_type is array (natural range <>) of std_logic_vector;
    signal result_mem_rdata       : std_logic_vector(15 downto 0);
    signal accum_clr              : std_logic;
    signal data_src_sel           : std_logic;
    signal layer_idx              : unsigned(1 downto 0);
    signal weight_src_sel         : std_logic_vector(1 downto 0);
    signal done                   : std_logic;

    signal pixel_data_ext         : signed(15 downto 0);
    signal data_src               : signed(15 downto 0);
    signal weight_src             : std_logic_vector(C_HIDDEN_LAYER_WIDTH-1 downto 0);
    signal h1_weight_rdata        : std_logic_vector(C_HIDDEN_LAYER_WIDTH-1 downto 0);
    signal h2_weight_rdata        : std_logic_vector(C_HIDDEN_LAYER_WIDTH-1 downto 0);
    signal h3_weight_rdata        : std_logic_vector(C_HIDDEN_LAYER_WIDTH-1 downto 0);
    type signed_array_type is array (natural range <>) of signed;
    signal weight_src_array       : signed_array_type(C_MUL_HIDDEN_CYCLES-1 downto 0)(C_DATA_WIDTH-1 downto 0);
    signal mac_result             : slv_array_type(C_MUL_HIDDEN_CYCLES-1 downto 0)(C_DATA_WIDTH-1 downto 0);

    function unpack_mac_result (
        mac_result : slv_array_type)
        return std_logic_vector is
        variable temp : std_logic_vector(C_HIDDEN_LAYER_WIDTH-1 downto 0);
    begin
        for i in 0 to C_MUL_HIDDEN_CYCLES-1 loop
            temp(C_DATA_WIDTH*(i+1)-1 downto C_DATA_WIDTH*i) := mac_result(i);
        end loop;
        return temp;
    end unpack_mac_result;

begin

    -- control logic
    process(CLK, ARST_N) begin
        if (ARST_N = '0') then
            state     <= E_IDLE;
            mem_addr  <= (others => '0');
            layer_idx <= (others => '0');
        elsif rising_edge(CLK) then
            case(state) is 
                when E_IDLE =>
                    mem_addr <= (others => '0');
                    if (START = '1') then
                        state     <= E_MUL1;
                        mem_addr  <= mem_addr + 1;
                        layer_idx <= (others => '0');
                    end if;
                when E_MUL1 =>
                    mem_addr <= mem_addr + 1;
                    if (mem_addr = C_MUL_INPUT_CYCLES+1) then
                        state    <= E_WB1;
                        mem_addr <= (others => '0');
                    end if;
                when E_WB1 =>
                    state     <= E_CLR1;
                    layer_idx <= layer_idx + 1;
                when E_CLR1 =>
                    state    <= E_MUL2;
                    mem_addr <= mem_addr + 1;
                when E_MUL2 =>
                    mem_addr <= mem_addr + 1;
                    if (mem_addr = C_MUL_HIDDEN_CYCLES+1) then
                        state    <= E_WB2;
                        mem_addr <= (others => '0');
                    end if;
                when E_WB2 =>
                    state     <= E_CLR2;
                    layer_idx <= layer_idx + 1;
                when E_CLR2 =>
                    state    <= E_MUL3;
                    mem_addr <= mem_addr + 1;
                when E_MUL3 =>
                    mem_addr <= mem_addr + 1;
                    if (mem_addr = C_MUL_HIDDEN_CYCLES+1) then
                        state    <= E_DONE;
                        mem_addr <= (others => '0');
                    end if;
                when E_DONE =>
                    state <= E_IDLE;
                when others => null;
            end case;
        end if;
    end process;

    PIXEL_MEM_ADDR <= std_logic_vector(mem_addr);
    result_mem_we  <= '1' when (state = E_WB1 or state = E_WB2) else '0';
    accum_clr      <= '1' when (state = E_IDLE or state = E_CLR1 or state = E_CLR2) else '0';
    data_src_sel   <= '0' when (state = E_MUL1) else '1';
    weight_src_sel <= std_logic_vector(layer_idx);
    done           <= '1' when (state = E_DONE) else '0';

    -- datapath logic
    pixel_data_ext <= signed(shift_left(resize(unsigned(PIXEL_MEM_DATA), C_DATA_WIDTH), 4)); --map [0,255] to [-8,8) Q4_11

    -- select read sources
    data_src   <= pixel_data_ext when (data_src_sel = '0') else signed(result_mem_rdata);
    weight_src <= h1_weight_rdata when (weight_src_sel = "00") else
                  h2_weight_rdata when (weight_src_sel = "01") else
                  h3_weight_rdata;
    
    -- MAC units
    GEN_MACS : for i in 0 to C_MUL_HIDDEN_CYCLES - 1 generate
        weight_src_array(i) <= signed(weight_src(C_DATA_WIDTH*(16-(i+1))-1 downto C_DATA_WIDTH*(16-(i+2))));
        mac_x : mac
            port map (
                CLK    => CLK,
                ARST_N => ARST_N,
                CLR    => accum_clr,
                DATA   => data_src,
                WEIGHT => weight_src_array(i),
                RESULT => mac_result(i)
        );
    end generate;
    
    -- latch output
    process(CLK, ARST_N) begin
        if (ARST_N = '0') then
            RESULT     <= (others => '0');
            RESULT_VLD <= '0';
        elsif rising_edge(CLK) then
            RESULT_VLD <= '0';
            if (done = '1') then
                RESULT     <= unpack_mac_result(mac_result);
                RESULT_VLD <= '1';
            end if;
        end if;
    end process;

    -- weight memories
    u_w1_mem : w1_mem
        port map (
            clka   => CLK,
            ena    => '1',
            wea(0) => '0',
            addra  => std_logic_vector(mem_addr(8 downto 0)),
            dina   => (others => '0'),
            douta  => h1_weight_rdata
        );

    u_w2_mem : w2_mem
        port map (
            a   => std_logic_vector(mem_addr(3 downto 0)),
            d   => (others => '0'),
            clk => CLK,
            we  => '0',
            qspo => h2_weight_rdata
        );

    u_w3_mem : w3_mem
        port map (
            a   => std_logic_vector(mem_addr(3 downto 0)),
            d   => (others => '0'),
            clk => CLK,
            we  => '0',
            qspo => h3_weight_rdata
        );

    -- output memory, also stores temporary result
    u_output_mem : output_mem
        port map (
            CLK    => CLK,
            ARST_N => ARST_N,
            WEN    => result_mem_we,
            WDATA  => unpack_mac_result(mac_result),
            RADDR  => mem_addr(3 downto 0),
            RDATA  => result_mem_rdata
        );

end rtl;
