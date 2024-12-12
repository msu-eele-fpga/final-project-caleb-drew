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
  signal enable_latch_delay  : boolean;
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
  proc_lcd_write : process (clk, reset, ready_flag)
  begin
    if reset = '1' then
      output_register <= "00000000";
      rs              <= '0';
      latch           <= '0';
      busy_flag       <= '0';
    elsif rising_edge(clk) then
      --ready_flag is active high

      if write_enable = '1' then
        if ready_flag = '1' then
          --If a new write is requested
          if done_latch then
            --LCD is ready for the next write
            rs              <= write_register(8);
            output_register <= write_register(7 downto 0);
            enable_delay    <= true;
            --Disable ready flag
            --Disable enable latch
            --Set enable pin low
            ready_flag         <= '0';
            busy_flag          <= '1';
            enable_latch_delay <= false;
            latch              <= '0';
          elsif not enable_latch_delay then --TODO: Fix logic
            enable_latch_delay <= true;
            --Set enable bit
            latch <= '1';
          elsif done_delay then
            ready_flag   <= '1';
            enable_delay <= false;
            busy_flag    <= '0';
          end if;
        else
          --do nothing waiting for latch to complete. 
        end if;

      else
        --Really do nothing, the LCD isn't ready for another instruction 
      end if;
    end process;

  end architecture;
