library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port(
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_start : in std_logic;
        i_add   : in std_logic_vector(15 downto 0); 
        o_done  : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0); 
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0); 
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    -- signal used for INTIIALISATION
    signal init_count: std_logic;
    
    -- signals used for DECISION CONTAINER
    signal base_addr, count: unsigned(15 downto 0);
    signal addr_read, addr_write: unsigned(15 downto 0);
    signal ra_load, o_sel, c_load: std_logic;
    
    signal load_en: std_logic;
    signal rlength_load, rs_load, rc_load, rk_load: std_logic;
    signal wait_res, rk_sel, o_end: std_logic;
    
    -- signals used for LENGTH CONTAINER
    signal k: std_logic_vector(15 downto 0);
    
    -- signals used for S CONTAINER
    signal s: std_logic;
    
    -- signals used for C CONTAINER
    signal c14, c13, c12, c11, c10, c9, c8, c6, c5, c4, c3, c2: std_logic_vector(7 downto 0);
    
    -- signals used for K CONTAINER
    signal in_k: std_logic_vector(7 downto 0);
    signal k7, k6, k5, k4, k3, k2, k1: std_logic_vector(7 downto 0);
    
    -- signals used for DIFFERENTIAL FUNCTION
    signal cc7, cc6, cc5, cc4, cc3, cc2, cc1: std_logic_vector(7 downto 0);
    signal p7, p6, p5, p4, p3, p2, p1: signed(18 downto 0);
    signal sum: signed(18 downto 0);
    signal ovf: signed(18 downto 0);
    signal res_o3, res_o5: signed(18 downto 0);
    signal res: std_logic_vector(18 downto 0);
    
    -- signals used for FSM
    type type_state is (S0, S1, S2, S3, S4, S5, S6);
    signal next_state, current_state: type_state;
    
begin
    --
    -- DECISION CONTAINER:
    -- The circuit inserts in o_mem_addr the address where data are written/read and defines all
    -- the value of the necessary signals
    --
    
    -- address register
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            base_addr <= (others => '0');
        elsif rising_edge(i_clk) then
            if ra_load = '1' then
                base_addr <= unsigned(i_add);
            end if;
        end if;
    end process;
    
    -- count register
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            count <= (others => '0');
        elsif rising_edge(i_clk) then
            if init_count = '1' then
                count <= (others => '0');
            elsif c_load = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;
    
    -- calculation of the address where I read data
    addr_read <= base_addr + count;
    
    -- address where I write data
    addr_write <= addr_read + (unsigned(k) - 4);
    
    -- choice of the address to use
    o_mem_addr <= std_logic_vector(addr_read) when o_sel = '0' else
                 std_logic_vector(addr_write);
    
    -- component that defines the value of the load of all the registers
    process(load_en, count)
    begin
        -- If the component is not enabled, all the signal are setted to 0
        if load_en = '0' then
            rlength_load <= '0';
            rs_load <= '0';
            rc_load <= '0';
            rk_load <= '0';
            
        -- If the component is enabled
        else
            -- If I read the cells that cointain C1 or C7, I don't save their value in the shift register K
            if count = 3 or count = 9 then
                rlength_load <= '0';
                rs_load <= '0';
                rc_load <= '0';
                rk_load <= '0';
            -- If I read the K part
            elsif count < 2 then
                rlength_load <= '1';
                rs_load <= '0';
                rc_load <= '0';
                rk_load <= '0';
            -- If I read the S part 
            elsif count = 2 then
                rlength_load <= '0';
                rs_load <= '1';
                rc_load <= '0';
                rk_load <= '0';
            -- If I read the C part
            elsif count < 17 then
                rlength_load <= '0';
                rs_load <= '0';
                rc_load <= '1';
                rk_load <= '0';
            -- If I read the data (variable part)
            else
                rlength_load <= '0';
                rs_load <= '0';
                rc_load <= '0';
                rk_load <= '1';
            end if;
        end if;
    end process;
    
    -- component that defines the next value to insert in the K CONTAINER
    -- The decision is executed in the S3 state because, for definition, the flip flop takes the value of
    -- its input immediately after the rising edge, and so before every operation in the circuit
    
    process(count, k)
        variable num_k: unsigned(15 downto 0);
    begin
        num_k := unsigned(k);
        
        -- If I can insert other data from the string
        if count < num_k + to_unsigned(17, num_k'length) then
            rk_sel <= '0';
        -- If I finish to read the string
        else
            rk_sel <= '1';
        end if;
    end process;
    
    -- component that defines all the other internal signals
    process(count, k)
        variable num_k: unsigned(15 downto 0);
    begin
        num_k := unsigned(k);
        
        -- If I don't read at least 4 elements from the variable part
        if count <= 20 then
            wait_res <= '0';
            o_end <= '0';
        -- If I don't finish all the operations
        elsif count <= num_k + to_unsigned(20, num_k'length) then
            wait_res <= '1';
            o_end <= '0';
        -- If I finish all the operations
        else
            wait_res <= '1';
            o_end <= '1';
        end if;
    end process;
    
    --
    -- LENGTH CONTAINER: It contains the length of the sequence -> K1K2
    --
    
    -- length register
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            k <= (others => '0');
        elsif rising_edge(i_clk) then
            if rlength_load = '1' then
                k <= k(7 downto 0) & i_mem_data;
            end if;
        end if;
    end process;
    
    --
    -- S CONTAINER: It contains the value of S
    --
    
    -- s register
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            s <= '0';
        elsif rising_edge(i_clk) then
            if rs_load = '1' then
                s <= i_mem_data(0);
            end if;
        end if;
    end process;
    
    --
    -- C CONTAINER: Its structure is a shift register with 12 registers relatived to the effectively used
    -- coefficients: (C2..C6) for order 3; (C8..C14) for order 5
    --
    
    process(i_clk, i_rst)
        begin
            if i_rst = '1' then
                c14 <= (others => '0');
                c13 <= (others => '0');
                c12 <= (others => '0');
                c11 <= (others => '0');
                c10 <= (others => '0');
                c9 <= (others => '0');
                c8 <= (others => '0');
                
                c6 <= (others => '0');
                c5 <= (others => '0');
                c4 <= (others => '0');
                c3 <= (others => '0');
                c2 <= (others => '0');
            elsif rising_edge(i_clk) then
                if rc_load = '1' then
                    c14 <= i_mem_data;
                    c13 <= c14;
                    c12 <= c13;
                    c11 <= c12;
                    c10 <= c11;
                    c9 <= c10;
                    c8 <= c9;
                    
                    c6 <= c8;
                    c5 <= c6;
                    c4 <= c5;
                    c3 <= c4;
                    c2 <= c3;
                end if;
            end if;
    end process;
    
    --
    -- K CONTAINER: Its structure is a shift register with 7 registers
    --
    
    -- It defines the next value to insert in the registry.
    -- If I have data to read from the string, I'll insert i_mem_data. Otherwise, I'll insert 0x00 
    in_k <= i_mem_data when rk_sel = '0' else
            (others => '0');
            
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            k7 <= (others => '0');
            k6 <= (others => '0');
            k5 <= (others => '0');
            k4 <= (others => '0');
            k3 <= (others => '0');
            k2 <= (others => '0');
            k1 <= (others => '0');
        elsif rising_edge(i_clk) then
            if rk_load = '1' then
                k7 <= in_k;
                k6 <= k7;
                k5 <= k6;
                k4 <= k5;
                k3 <= k4;
                k2 <= k3;
                k1 <= k2;
            end if;
        end if;
    end process;
    
    --
    -- DIFFERENTIAL FUNCTION: It defines the result based on its input.
    -- The operations that the differential function execute are the following ones:
    --
    
    -- 1. Choice of the correct coefficients ('0' -> 3-order filter; '1' -> 5-order filter)
    cc7 <= (others => '0') when s = '0' else
           c14;
    cc6 <= c6 when s = '0' else
           c13;
    cc5 <= c5 when s = '0' else
           c12;
    cc4 <= c4 when s = '0' else
           c11;
    cc3 <= c3 when s = '0' else
           c10;
    cc2 <= c2 when s = '0' else
           c9;
    cc1 <= (others => '0') when s = '0' else
           c8;
    
    -- 2. Calculate all the products
    p7 <= resize(signed(cc7) * signed(k7), 19);
    p6 <= resize(signed(cc6) * signed(k6), 19);
    p5 <= resize(signed(cc5) * signed(k5), 19);
    p4 <= resize(signed(cc4) * signed(k4), 19);
    p3 <= resize(signed(cc3) * signed(k3), 19);
    p2 <= resize(signed(cc2) * signed(k2), 19);
    p1 <= resize(signed(cc1) * signed(k1), 19);
    
    -- 3. Calculate the sum
    sum <= ((p7 + p6) + (p5 + p4)) + ((p3 + p2) + p1);
    
    -- 4. Normalisation (only if the number is negative, +1 is added to the result of the shift)
    ovf <= (0 => sum(18), others => '0');
    res_o5 <= (shift_right(sum, 6) + signed(ovf)) + (shift_right(sum, 10) + signed(ovf));
    res_o3 <= res_o5 + (shift_right(sum, 4) + signed(ovf)) + (shift_right(sum, 8) + signed(ovf));
    
    res <= std_logic_vector(res_o3) when s = '0' else
           std_logic_vector(res_o5);
    
    -- 5. Saturation
    process(res)
        variable num: signed(18 downto 0);
    begin
        num := signed(res);
        if num < -128 then
            o_mem_data <= "10000000";
        elsif num > 127 then
            o_mem_data <= "01111111";
        else o_mem_data <= res(7 downto 0);
        end if;
    end process;
    
    --
    -- DEFINITION OF THE FSM
    --
    state_reg: process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            current_state <= S0;
        elsif rising_edge(i_clk) then
            current_state <= next_state;
        end if;
    end process;
    
    delta: process(current_state, i_start, wait_res, o_end, rk_sel)
    begin
        case current_state is
            when S0 =>
                if i_start = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;
            when S1 =>
                next_state <= S2;
            when S2 =>
                next_state <= S3;
            when S3 =>
                next_state <= S4;
            when S4 =>
                if o_end = '1' then
                    next_state <= S6;
                elsif wait_res = '1' then
                    next_state <= S5;
                else
                    next_state <= S2;
                end if;
            when S5 =>
                if rk_sel = '1' then
                    next_state <= S3;
                else
                    next_state <= S2;
                end if;
            when S6 =>
                if i_start = '1' then
                    next_state <= S6;
                else
                    next_state <= S0;
                end if;
        end case;
    end process;
        
    lambda: process(current_state)
    begin
        init_count <= '0';
        ra_load <= '0';
        o_sel <= '0';
        load_en <= '0';
        c_load <= '0';
        o_mem_we <= '0';
        o_mem_en <= '0';
        o_done <= '0';
        
        case current_state is
            when S0 =>
            when S1 =>
                ra_load <= '1';
                init_count <= '1';
            when S2 =>
                o_sel <= '0';
                o_mem_we <= '0';
                o_mem_en <= '1';
            when S3 =>
                c_load <= '1';
                load_en <= '1';
            when S4 =>
            when S5 =>
                o_sel <= '1';
                o_mem_we <= '1';
                o_mem_en <= '1';
            when S6 =>
                o_done <= '1';
        end case;
    end process;
    
end Behavioral;
