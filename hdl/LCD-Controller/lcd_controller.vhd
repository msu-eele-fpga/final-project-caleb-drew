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
end entity;

architecture lcd_arch of lcd_controller is

  --Tell system about the timed counter 
  component clock_divider
    generic (
      C_PERIOD : integer := 32
    );
    port (
      --Basic signals 
      clk    : in std_logic;
      reset  : in std_logic;
      enable : in std_logic;
      --Duration count
      count : in unsigned(C_PERIOD - 1 downto 0);
      --Output done signal
      ready : out std_logic
    );
  end component;
  --Internal ready flag for writing, and enable for starting timing
  signal ready_flag  : std_logic;
  signal start_delay : std_logic := '0';
  --Unit conversion constant
  --Timing specs in the datasheet for the LCD are all in ms 
  --Converting clock cycles to ms for convince
  constant CLOCK_PULSE_PER_MS           : integer := 1 ms / CLK_PERIOD;
  constant LENGTH_OF_CLOCK_PULSE_PER_MS : integer := 15;
  /*
  * in general it will take 0.037 ms per instruction.
  * The clear and return home take 1.52 ms per instruction
  * Declaring some constants to calculate this based on the clock input
  */ --
  constant SHORT_INSTRUCTION_DELAY : integer               := 185000;
  constant LONG_INSTRUCTION_DELAY  : integer               := 76000000;
  signal delay_time                : unsigned(31 downto 0) := (to_unsigned(SHORT_INSTRUCTION_DELAY, 27), others => '0');

begin
  --Busy timer
  busy_timer : clock_divider
  generic map(
    C_PERIOD => 32
  )
  port map(
    clk    => clk,
    reset  => reset,
    count  => delay_time,
    enable => start_delay,
    ready  => ready_flag
  );

  proc_lcd_write : process (clk, reset, ready_flag)
  begin
    if reset = '1' then
      output_register <= "00000000";
      rs              <= '0';
    elsif rising_edge(clk) then
      --ready_flag is active high
      if ready_flag = '1' then
        --LCD is ready for the next write
        rs              <= write_register(8);
        output_register <= write_register(7 downto 0);
      else
        --Really do nothing, the LCD isn't ready for another instruction 
      end if;
    end if;
  end process;
end architecture;
