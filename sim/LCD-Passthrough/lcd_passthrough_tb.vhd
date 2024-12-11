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
  component lcd_passthrough is
    port (
      --Basic clock and reset input
      clk   : in std_logic;
      reset : in std_logic;
      --LCD Specific inputs
      write_register : in std_logic_vector(9 downto 0);
      --LCD Specific outputs
      output_register : out std_logic_vector(7 downto 0);
      rs              : out std_logic;
      latch           : out std_logic
    );
  end component;

  --Basic signals 
  signal reset_tb     : std_logic := '1';
  signal clk_tb       : std_logic := '0';
  constant CLK_PERIOD : time      := 20 ns;

  --Interface signals
  --Inputs
  signal instruction : std_logic_vector(9 downto 0) := (others => '0');

  --Outputs
  signal write_register : std_logic_vector(7 downto 0);
  signal rs_output      : std_logic;
  signal latch_output   : std_logic;

begin
  dut_lcd_controller : component lcd_passthrough
    port map(
      clk                        => clk_tb,
      reset                      => reset_tb,
      write_register(9 downto 0) => instruction(9 downto 0),
      rs                         => rs_output,
      latch                      => latch_output,
    );
    --Create clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;

    stimuli_and_checker : process is
    begin
      wait_for_clock_edge(clk_tb);
      reset_tb <= '0';
      print("Testing LCD maps appropriately specs");
      instruction <= "0000001111";
      wait_for_clock_edges(clk_tb, 10);
      instruction <= "1100001111";
      --Should be 00001111 as the output preventing new data from being added. 
      wait_for_clock_edges(clk_tb, 10); --Total wait time before writing the next instruction
      reset_tb <= '1';
      std.env.finish;
    end process;
  end architecture;