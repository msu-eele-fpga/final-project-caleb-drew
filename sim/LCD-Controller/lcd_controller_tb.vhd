--Required packages
--Must be compiled with 2008 VHDL standard
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--class packages
use work.print_pkg.all;
use work.assert_pkg.all;

--Test bench package for delays
use work.tb_pkg.all;
entity lcd_tb is
end entity lcd_tb;

architecture testbench of lcd_tb is
  component lcd_controller is
    generic (
      --Needed for timed counter to create data only when ready on the LCD
      CLK_PERIOD : time := 20 ns
    );
    port (
      --Basic clock and reset input
      clk          : in std_logic;
      reset        : in std_logic;
      write_enable : in std_logic;
      --LCD Specific inputs   
      write_register  : in std_logic_vector(8 downto 0);
      output_register : out std_logic_vector(7 downto 0);
      rs              : out std_logic;
      e               : out std_logic;
      busy_flag       : out std_logic
    );
  end component;

  --Basic signals 
  signal reset_tb     : std_logic := '1';
  signal clk_tb       : std_logic := '0';
  constant CLK_PERIOD : time      := 20 ns;

  --Interface signals
  --Inputs
  signal instruction  : std_logic_vector(7 downto 0) := (others => '0');
  signal RS           : std_logic                    := '0';
  signal write_enable : std_logic                    := '0';

  --Outputs
  signal write_register : std_logic_vector(8 downto 0);
  signal rs_output      : std_logic;
  signal e_output       : std_logic;
  signal ready          : std_logic;
  ----------------------------------------------------------------------------------------
begin
  dut_lcd_controller : component lcd_controller
    generic map(
      CLK_PERIOD => 20 ns
    )
    port map(
      clk                        => clk_tb,
      reset                      => reset_tb,
      write_register(7 downto 0) => instruction,
      write_register(8)          => rs,
      write_enable               => write_enable,
      rs                         => rs_output,
      e                          => e_output,
      busy_flag                  => ready
    );
    --Create clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;

    stimuli_and_checker : process is
    begin
      wait_for_clock_edge(clk_tb);
      reset_tb     <= '0';
      write_enable <= '1';
      print("Testing LCD timing specs");
      print("--Needs to set latch for 100ns before writing data");
      print("--Needs to leave data on the bus for 0.037 ms for regular instructions");
      print("--Needs to leave data on the bus for 1.52 ms for clear and home instructions");
      instruction <= "00001111";
      rs          <= '0';
      wait_for_clock_edges(clk_tb, 10);
      instruction <= "00000000";
      wait_for_clock_edges(clk_tb, 50);
      --Test setting the write enable to 0 to prevent a write
      write_enable <= '0';
      --Should be 00001111 as the output preventing new data from being added. 
      wait_for_clock_edges(clk_tb, 200000); --Total wait time before writing the next instruction
      wait_for_clock_edges(clk_tb, 50);
      --Test setting the write enable to 0 to prevent a write
      write_enable <= '1';
      wait_for_clock_edges(Clk_tb, 100);
      write_enable <= '0';
      --Should be 00001111 as the output preventing new data from being added. 
      wait_for_clock_edges(clk_tb, 200000); --Total wait time before writing the next instructio
      reset_tb <= '1';

      std.env.finish;
    end process;
  end architecture;