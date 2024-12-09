library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity led_patterns_avalon is
  port (
    clk : in std_ulogic;
    rst : in std_ulogic;
    -- avalon memory-mapped slave interface
    avs_read      : in std_logic;
    avs_write     : in std_logic;
    avs_address   : in std_logic_vector(1 downto 0);
    avs_readdata  : out std_logic_vector(31 downto 0);
    avs_writedata : in std_logic_vector(31 downto 0);
    -- external I/O; export to top-level
    red_output   : out std_logic := '0';
    green_output : out std_logic := '0';
    blue_output  : out std_logic := '0'
  );
end entity led_patterns_avalon;

architecture led_patterns_avalon_arch of led_patterns_avalon is
  signal global_period          : unsigned(31 downto 0)         := "00000001000000000000000000000000"; -- default to 1ms
  signal red_duty_cycle         : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
  signal green_duty_cycle       : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
  signal blue_duty_cycle        : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
  signal global_period_unsigned : unsigned(31 downto 0);
  component pwm_controller is
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
  end component pwm_controller;

begin
  red_controller : pwm_controller
  generic map(
    CLK_PERIOD => 20 ns
  )
  port map(
    clk        => clk,
    rst        => rst,
    period     => global_period(29 downto 0),
    duty_cycle => red_duty_cycle(18 downto 0),
    output     => red_output
  );

  green_controller : pwm_controller
  generic map(
    CLK_PERIOD => 20 ns
  )
  port map(
    clk        => clk,
    rst        => rst,
    period     => global_period(29 downto 0),
    duty_cycle => green_duty_cycle(18 downto 0),
    output     => green_output
  );

  blue_controller : pwm_controller
  generic map(
    CLK_PERIOD => 20 ns
  )
  port map(
    clk        => clk,
    rst        => rst,
    period     => global_period(29 downto 0),
    duty_cycle => blue_duty_cycle(18 downto 0),
    output     => blue_output
  );

  avalon_register_read : process (clk)
  begin
    if rising_edge(clk) and avs_read = '1' then
      case avs_address is
        when "00" =>
          avs_readdata <= std_logic_vector(global_period);
        when "01" =>
          avs_readdata <= red_duty_cycle;
        when "10" =>
          avs_readdata <= green_duty_cycle;
        when "11" =>
          avs_readdata <= blue_duty_cycle;
        when others             =>
          avs_readdata <= (others => '0');
      end case;
    end if;
  end process avalon_register_read;

  avalon_register_write : process (clk, rst)
  begin
    if rst = '1' then
      global_period    <= "00000001000000000000000000000000";
      red_duty_cycle   <= "00000000000000000000000000000000";
      green_duty_cycle <= "00000000000000000000000000000000";
      blue_duty_cycle  <= "00000000000000000000000000000000";

    elsif rising_edge(clk) and avs_write = '1' then
      case avs_address is
        when "00" =>
          global_period <= unsigned(avs_writedata);
        when "01" =>
          red_duty_cycle <= avs_writedata;
        when "10" =>
          green_duty_cycle <= avs_writedata;
        when "11" =>
          blue_duty_cycle <= avs_writedata;
        when others =>
          null;
      end case;
    end if;
  end process avalon_register_write;

end architecture;