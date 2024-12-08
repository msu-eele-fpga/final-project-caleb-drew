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
      clk   : in std_logic;
      reset : in std_logic;
      --LCD Specific inputs
      write_register  : in std_logic_vector(8 downto 0);
      output_register : out std_logic_vector(7 downto 0);
      rs              : out std_logic;
      busy_flag       : out std_logic
    );
  end component;
begin
end architecture;