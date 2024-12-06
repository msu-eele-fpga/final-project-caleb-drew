library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder_counter is
  port (
    clk    : in std_logic;
    rst    : in std_logic;
    input  : in std_logic_vector(1 downto 0); -- "AB" input wiring
    counts : out integer := 0
  );
end entity;

architecture encoder_counter_arch of encoder_counter is
  signal previous_input : std_logic_vector(1 downto 0) := "00"; -- "AB" input wiring

begin

  Counting : process (clk, rst, input)
  begin
    if (rst = '1') then
      counts <= 0;
    elsif (rising_edge(clk)) then
      case previous_input is
        when "00" =>
          if (input = "10") then
            counts <= counts + 1;
          elsif (input = "01") then
            counts <= counts - 1;
          else
            counts <= counts;
          end if;
        when "10" =>
          if (input = "11") then
            counts <= counts + 1;
          elsif (input = "00") then
            counts <= counts - 1;
          else
            counts <= counts;
          end if;
        when "11" =>
          if (input = "01") then
            counts <= counts + 1;
          elsif (input = "10") then
            counts <= counts - 1;
          else
            counts <= counts;
          end if;
        when "01" =>
          if (input = "00") then
            counts <= counts + 1;
          elsif (input = "11") then
            counts <= counts - 1;
          else
            counts <= counts;
          end if;
        when others =>
          counts <= counts;
      end case;
      previous_input <= input;
    end if;
  end process;
end architecture;