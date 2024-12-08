/*
* EELE - 467 Final project
* Montana State University Fall 2024
* Created 12/7/24 Drew Currie
* License : GPL
* This code will create a 10 bit register to interface
* with the 16x2 LCD Module 1602A - 1.
*
*/ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_controller is
  generic (
    --Needed for timed counter to create data only when ready on the LCD
    CLK_PERIOD : time := 20 ns;
  );
  port (
    --Basic clock and reset input
    clk   : in std_logic;
    reset : in std_logic;
    --LCD Specific inputs
    write_register  : in std_logic_vector(9 downto 0);
    output_register : out std_logic_vector(9 downto 0);
    busy_flag       : out std_logic
  );

  architecture lcd_arch of lcd_controller is

    --Tell system about the timed counter 
    component clock_divider
      generic (
        C_PERIOD : integer
      );
      port (
        --Basic signals 
        clk   : in std_logic;
        reset : in std_logic;
        --Duration count
        count : in unsigned(C_PERIOD - 1 downto 0);
        --Output done signal
        done : out std_logic;
      );
    end component;
    --Unit conversion constant
    --Timing specs in the datasheet for the LCD are all in ms 
    --Converting clock cycles to ms for convince
    constant CLOCK_PULSE_PER_MS           : integer := 1 ms / CLK_PERIOD;
    constant LENGTH_OF_CLOCK_PULSE_PER_MS : integer := 15;
  begin
  end architecture;
