--
-- EELE - 467 Final project
-- Montana State University Fall 2024
-- Created 12/7/24 Drew Currie
-- License : GPL
-- This code will create a 10 bit register to interface
-- with the 16x2 LCD Module 1602A - 1.
--
--

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
    write_register : in std_logic_vector(8 downto 0);
    --Write enable 
    write_enable    : in std_logic;
    output_register : out std_logic_vector(7 downto 0);
    rs              : out std_logic;
    latch           : out std_logic;
    busy_flag       : out std_logic
  );
end entity;

architecture lcd_arch of lcd_controller is

  --Tell system about the timed counter 
  component clock_divider
    port (
      --Basic signals 
      clk    : in std_logic;
      count  : in integer;
      enable : in boolean;
      --Output done signal
      done : out boolean
    );
  end component;
  --Internal ready flag for writing, and enable for starting timing
  signal enable_delay : boolean := false;
  signal done_delay   : boolean;
  signal ready_flag   : std_logic := '1';
  --Unit conversion constant
  --Timing specs in the datasheet for the LCD are all in ms 
  --Converting clock cycles to ms for convince
  constant CLOCK_PULSE_PER_MS : integer := 1 ms / CLK_PERIOD;

  -- in general it will take 0.037 ms per instruction.
  -- The clear and return home take 1.52 ms per instruction
  -- Declaring some constants to calculate this based on the clock input
  --
  constant SHORT_INSTRUCTION_DELAY : integer := 185000;
  constant LONG_INSTRUCTION_DELAY  : integer := 76000000;
  signal delay_time                : integer := SHORT_INSTRUCTION_DELAY;

  -- Need a second clock divider for an enable latch system
  -- Timing is 100 ns per write to the LCD
  --
  constant ENABLE_LATCH_TIME : integer := 5;
  signal enable_latch_delay  : boolean := false;
  signal done_latch          : boolean;
begin
  --Busy timer
  busy_timer : clock_divider

  port map(
    clk    => clk,
    count  => delay_time,
    enable => enable_delay,
    done   => done_delay
  );
  --Enable latch timer
  latch_timer : clock_divider
  port map(
    clk    => clk,
    count  => ENABLE_LATCH_TIME,
    enable => enable_latch_delay,
    done   => done_latch
  );
  proc_lcd_write : process (clk, reset, done_delay)
  begin
    if reset = '1' then
      output_register <= "00000000";
      rs              <= '0';
      latch           <= '0';
      busy_flag       <= '0';
      ---------------------
    elsif write_enable = '1' then
      if (ready_flag = '1' and done_latch) then
        --Set flags
        busy_flag <= '1';
        if rising_edge(clk) then
          --Set Ready flag 
          ready_flag <= '0';
          --Output LCD data
          rs              <= write_register(8);
          output_register <= write_register(7 downto 0);
          --Disable enable pin latch
          enable_latch_delay <= false;
          latch              <= '0';
          --Start write delay 
          enable_delay <= true;
        end if;
        --Already requires write_enable = 1
      elsif (ready_flag = '1' and enable_latch_delay = false) then
        enable_latch_delay <= true;
        latch              <= '1';
        busy_flag          <= '1';

        --Already requires write_enable = 1
      elsif (done_delay) then
        --Done writing, ready to disable system
        --Reset flags
        busy_flag  <= '0';
        ready_flag <= '1';
      end if; --End of section requiring write_enable = 1
    end if; --If not write_enable = 1 then do nothing. 
  end process;

end architecture;