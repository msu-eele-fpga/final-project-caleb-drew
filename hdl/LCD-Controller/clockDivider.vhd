library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity clock_divider is
  generic (
    C_PERIOD                     : integer;
    LENGTH_OF_CLOCK_PULSE_PER_MS : integer := 15
  );
  port (
    count : in unsigned(C_PERIOD - 1 downto 0);
    clk   : in std_ulogic;
    rst   : in std_logic;
    done  : out std_logic
  );

end entity clock_divider;

architecture counter_arch of clock_divider is
  -- Know that 1ms in clock cycles is always 16 bits long
  signal counter : unsigned(C_PERIOD + LENGTH_OF_CLOCK_PULSE_PER_MS downto 0);

begin
  proc_clock_divider : process (clk, rst)
  begin
    if (rst = '0') then
      if rising_edge(clk) then
        -- If counter has exceeded or is equal to the COUNTER_LIMIT
        -- stop counting and assert done and reset counter
        -- If enable is still true this will continue to count
        if counter >= count then
          done    <= '1';
          counter <= (others => '0');
        else
          -- If still counting assert done as false
          counter <= counter + 1;
          done    <= '0';
        end if;
      end if;
    else
      counter <= (others => '0');
      done    <= '0';
    end if;
  end process;
end architecture counter_arch;
