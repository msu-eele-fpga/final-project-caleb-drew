--
-- EELE - 467 Final project
-- Montana State University Fall 2024
-- Created 12/10/24 Drew Currie
-- License : GPL
-- This code will create a 10 bit register to interface
-- with the 16x2 LCD Module 1602A - 1.
--
-- This is an incredibly simple component that directly maps pins
-- to inputs from an external source. 
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_passthrough is
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
end entity;

architecture lcd_arch of lcd_passthrough is
begin
  latch           <= write_register(9);
  rs              <= write_register(8);
  output_register <= write_register(7 downto 0);
end architecture lcd_arch;