library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pwm_controller is
  generic (
    CLK_PERIOD   : time    := 20 ns;
    W_PERIOD     : integer := 30;
    W_DUTY_CYCLE : integer := 19
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- PWM repetition period in milliseconds;
    -- datatype (W.F) is individually assigned
    period : in unsigned(W_PERIOD - 1 downto 0);
    -- PWM duty cycle between [0 1]; out-of-range values are hard limited
    -- datatype (W.F) is individually assigned;
    duty_cycle : in std_logic_vector(W_DUTY_CYCLE - 1 downto 0);
    output     : out std_logic
  );
end entity pwm_controller;

architecture pwm_controller_arch of pwm_controller is
  constant counts_per_ms          : integer := 1 ms / clk_period; -- clock cycles / ms
  signal duty_cycle_time          : unsigned(48 downto 0); -- W.F format = 49.42
  signal PERIOD_LIMIT_TOTAL       : unsigned(45 downto 0);
  signal PERIOD_LIMIT_TOTAL_INT   : integer := 0;
  signal DUTY_CYCLE_LIMIT_TOT     : unsigned(64 downto 0);
  signal DUTY_CYCLE_LIMIT_TOT_INT : integer := 0;
  signal count                    : integer := 0;
begin

  process (clk, period, duty_cycle)
  begin
    PERIOD_LIMIT_TOTAL       <= period * to_unsigned(counts_per_ms, 16);
    PERIOD_LIMIT_TOTAL_INT   <= to_integer(PERIOD_LIMIT_TOTAL(45 downto 23));
    DUTY_CYCLE_LIMIT_TOT     <= period * unsigned(duty_cycle) * to_unsigned(counts_per_ms, 16);
    DUTY_CYCLE_LIMIT_TOT_INT <= to_integer(DUTY_CYCLE_LIMIT_TOT(64 downto 42));
  end process;

  process (clk, rst)
  begin
    if rst = '1' then
      count  <= 0;
      output <= '0';
    elsif (rising_edge(clk)) then
      count <= count + 1;
      if (duty_cycle(18) = '1') then
        output       <= '1';
      elsif (count <= DUTY_CYCLE_LIMIT_TOT_INT) then
        output       <= '1';
      else
        output <= '0';
      end if;
      if (count = PERIOD_LIMIT_TOTAL_INT) then
        count <= 0;
      else
      end if;
    end if;
  end process;
end architecture;