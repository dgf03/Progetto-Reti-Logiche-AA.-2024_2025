-- Works in behaviour
-- Works in synthesized
-- FINE! (OK)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_8 is
end tb_8;

architecture project_tb_arch of tb_8 is

    constant CLOCK_PERIOD : time := 20 ns;

    -- Signals to be connected to the component
    signal tb_clk : std_logic := '0';
    signal tb_rst, tb_start, tb_done : std_logic;
    signal tb_add : std_logic_vector(15 downto 0);
 
    -- Signals for the memory
    signal tb_o_mem_addr, exc_o_mem_addr, init_o_mem_addr : std_logic_vector(15 downto 0);
    signal tb_o_mem_data, exc_o_mem_data, init_o_mem_data : std_logic_vector(7 downto 0);
    signal tb_i_mem_data : std_logic_vector(7 downto 0);
    signal tb_o_mem_we, tb_o_mem_en, exc_o_mem_we, exc_o_mem_en, init_o_mem_we, init_o_mem_en : std_logic;

    -- Memory
    type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
    signal RAM : ram_type := (OTHERS => "00000000");
 
    -- Scenario
    type scenario_config_type is array (0 to 16) of integer;
    constant SCENARIO_LENGTH : integer := 75;
    constant SCENARIO_LENGTH_STL : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(SCENARIO_LENGTH, 16));
    type scenario_type is array (0 to SCENARIO_LENGTH-1) of integer;

    signal scenario_config : scenario_config_type := (to_integer(unsigned(SCENARIO_LENGTH_STL(15 downto 8))),   -- K1
                                                      to_integer(unsigned(SCENARIO_LENGTH_STL(7 downto 0))),    -- K2
                                                      127,                                                      -- S
                                                      0, -5, -10, 0, 10, 5, 0, -1, 5, -25, 0, 25, -5, 1       -- C1-C14
                                                      );
    signal scenario_input : scenario_type := (-51, -27, -3, 69, -96, 110, -106, 123, 66, 112, 26, -8, -88, -28, -63, 93, -34, -85, -49, 68, -42, -128, -29, -30, 20, -55, -97, -82, 96, -21, -125, -83, 80, 1, 114, 112, -17, -119, 108, -79, 121, 6, 41, -94, 106, 107, 127, -56, -106, -49, -115, -20, -49, -16, 78, 99, 57, 109, -110, 25, -40, -107, 70, -88, 22, 57, -103, -122, 66, -123, -73, 59, 11, 97, 93);
    signal scenario_output : scenario_type :=(-9, 11, 44, -49, 27, -7, -6, 72, -17, -5, -39, -37, -1, 0, 43, 17, -73, -3, 59, 6, -81, 13, 32, 12, -3, -41, -17, 74, 26, -88, -22, 82, 17, 0, 53, -43, -96, 66, 3, -3, 40, -31, -36, 18, 74, 2, -48, -87, 20, -9, 7, 27, -11, 45, 40, -19, 20, -64, -29, 46, -72, 56, 3, -34, 73, -48, -77, 82, -2, -70, 82, 17, 3, 39, -39);
 
    signal memory_control : std_logic := '0';      -- A signal to decide when the memory is accessed
                                                   -- by the testbench or by the project
 
    constant SCENARIO_ADDRESS : integer := 334;    -- This value may arbitrarily change
 
    component project_reti_logiche is
        port (
                i_clk : in std_logic;
                i_rst : in std_logic;
                i_start : in std_logic;
                i_add : in std_logic_vector(15 downto 0);
 
                o_done : out std_logic;
 
                o_mem_addr : out std_logic_vector(15 downto 0);
                i_mem_data : in  std_logic_vector(7 downto 0);
                o_mem_data : out std_logic_vector(7 downto 0);
                o_mem_we   : out std_logic;
                o_mem_en   : out std_logic
        );
    end component project_reti_logiche;
 
begin
    UUT : project_reti_logiche
    port map(
                i_clk   => tb_clk,
                i_rst   => tb_rst,
                i_start => tb_start,
                i_add   => tb_add,
 
                o_done => tb_done,
 
                o_mem_addr => exc_o_mem_addr,
                i_mem_data => tb_i_mem_data,
                o_mem_data => exc_o_mem_data,
                o_mem_we   => exc_o_mem_we,
                o_mem_en   => exc_o_mem_en
    );
 
    -- Clock generation
    tb_clk <= not tb_clk after CLOCK_PERIOD/2;
 
    -- Process related to the memory
    MEM : process (tb_clk)
    begin
        if tb_clk'event and tb_clk = '1' then
            if tb_o_mem_en = '1' then
                if tb_o_mem_we = '1' then
                    RAM(to_integer(unsigned(tb_o_mem_addr))) <= tb_o_mem_data;
                    tb_i_mem_data <= tb_o_mem_data after 2 ns;
                else
                    tb_i_mem_data <= RAM(to_integer(unsigned(tb_o_mem_addr))) after 2 ns;
                end if;
            end if;
        end if;
    end process;
 
    memory_signal_swapper : process(memory_control, init_o_mem_addr, init_o_mem_data,
                                    init_o_mem_en,  init_o_mem_we,   exc_o_mem_addr,
                                    exc_o_mem_data, exc_o_mem_en, exc_o_mem_we)
    begin
        -- This is necessary for the testbench to work: we swap the memory
        -- signals from the component to the testbench when needed.
 
        tb_o_mem_addr <= init_o_mem_addr;
        tb_o_mem_data <= init_o_mem_data;
        tb_o_mem_en   <= init_o_mem_en;
        tb_o_mem_we   <= init_o_mem_we;
 
        if memory_control = '1' then
            tb_o_mem_addr <= exc_o_mem_addr;
            tb_o_mem_data <= exc_o_mem_data;
            tb_o_mem_en   <= exc_o_mem_en;
            tb_o_mem_we   <= exc_o_mem_we;
        end if;
    end process;
 
    -- This process provides the correct scenario on the signal controlled by the TB
    create_scenario : process
    begin
        wait for 25 ns;
 
        -- Signal initialization and reset of the component
        tb_start <= '0';
        tb_add <= (others=>'0');
        tb_rst <= '1';
 
        -- Wait some time for the component to reset...
        wait for 125 ns;
 
        tb_rst <= '0';
        memory_control <= '0';  -- Memory controlled by the testbench
 
        wait until falling_edge(tb_clk); -- Skew the testbench transitions with respect to the clock
 
 
        for i in 0 to 16 loop
            init_o_mem_addr<= std_logic_vector(to_unsigned(SCENARIO_ADDRESS+i, 16));
            init_o_mem_data<= std_logic_vector(to_unsigned(scenario_config(i),8));
            init_o_mem_en  <= '1';
            init_o_mem_we  <= '1';
            wait until rising_edge(tb_clk);   
        end loop;
 
        for i in 0 to SCENARIO_LENGTH-1 loop
            init_o_mem_addr<= std_logic_vector(to_unsigned(SCENARIO_ADDRESS+17+i, 16));
            init_o_mem_data<= std_logic_vector(to_unsigned(scenario_input(i),8));
            init_o_mem_en  <= '1';
            init_o_mem_we  <= '1';
            wait until rising_edge(tb_clk);   
        end loop;
 
        wait until falling_edge(tb_clk);
 
        memory_control <= '1';  -- Memory controlled by the component
 
        tb_add <= std_logic_vector(to_unsigned(SCENARIO_ADDRESS, 16));
 
        tb_start <= '1';
 
        while tb_done /= '1' loop                
            wait until rising_edge(tb_clk);
        end loop;
 
        wait for 10 ns;
 
        tb_start <= '0';
 
        wait;
 
    end process;
 
    -- Process without sensitivity list designed to test the actual component.
    test_routine : process
    begin
 
        wait until tb_rst = '1';
        wait for 25 ns;
        assert tb_done = '0' report "TEST FALLITO o_done !=0 during reset" severity failure;
        wait until tb_rst = '0';
 
        wait until falling_edge(tb_clk);
        assert tb_done = '0' report "TEST FALLITO o_done !=0 after reset before start" severity failure;
 
        wait until rising_edge(tb_start);
 
        while tb_done /= '1' loop                
            wait until rising_edge(tb_clk);
        end loop;
 
        assert tb_o_mem_en = '0' or tb_o_mem_we = '0' report "TEST FALLITO o_mem_en !=0 memory should not be written after done." severity failure;
 
        for i in 0 to SCENARIO_LENGTH-1 loop
            assert RAM(SCENARIO_ADDRESS+17+SCENARIO_LENGTH+i) = std_logic_vector(to_unsigned(scenario_output(i),8)) report "TEST FALLITO @ OFFSET=" & integer'image(17+SCENARIO_LENGTH+i) & " expected= " & integer'image(scenario_output(i)) & " actual=" & integer'image(to_integer(signed(RAM(SCENARIO_ADDRESS+17+SCENARIO_LENGTH+i)))) severity failure;
        end loop;
 
        wait until falling_edge(tb_start);
        assert tb_done = '1' report "TEST FALLITO o_done == 0 before start goes to zero" severity failure;
        wait until falling_edge(tb_done);
 
        assert false report "Simulation Ended! TEST PASSATO (EXAMPLE 8)" severity failure;
    end process;
 
end project_tb_arch;
