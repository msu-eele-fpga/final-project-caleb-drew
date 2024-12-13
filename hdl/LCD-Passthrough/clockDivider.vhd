library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity clock_divider is
  port (
    count  : in integer;
    clk    : in std_ulogic;
    enable : in boolean;
    done   : out boolean
  );

end entity clock_divider;

architecture counter_arch of clock_divider is
  signal counter : integer := 0;

begin
  proc_clock_divider : process (clk, enable)

  begin
    if (enable = true) then
      if rising_edge(clk) then
        -- If counter has exceeded or is equal to the COUNTER_LIMIT
        -- stop counting and assert done and reset counter
        -- If enable is still true this will continue to count
        if counter >= count then
          done    <= true;
          counter <= 0;
        else
          -- If still counting assert done as false
          counter <= counter + 1;
          done    <= false;
        end if;
      end if;
    else
      counter <= 0;
      done    <= false;
    end if;
  end process;

end architecture counter_arch;
