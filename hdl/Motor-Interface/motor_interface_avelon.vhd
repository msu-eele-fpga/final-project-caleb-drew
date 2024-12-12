library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity led_patterns_avalon is
  port (
    clk   : in std_ulogic;
    reset : in std_ulogic;
    -- avalon memory-mapped slave interface
    avs_read      : in std_logic;
    avs_write     : in std_logic;
    avs_address   : in std_logic_vector(1 downto 0);
    avs_readdata  : out std_logic_vector(31 downto 0);
    avs_writedata : in std_logic_vector(31 downto 0);
    -- external I/O; export to top-level
    encoder_input : in std_logic_vector(1 downto 0);
    pwm_output    : out std_logic;
    pwm_direction : out std_logic
  );
end entity led_patterns_avalon;

architecture led_patterns_avalon_arch of led_patterns_avalon is
  signal pwm_period      : unsigned(31 downto 0)         := "00000001000000000000000000000000"; -- default to 1ms
  signal duty_cycle      : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
  signal encoder_counts  : integer                       := 0;
  signal period_unsigned : unsigned(31 downto 0);
  component motor_interface is
    port (
      clk            : in std_logic;
      rst            : in std_logic;
      encoder_input  : in std_logic_vector(1 downto 0); -- "AB" input wiring
      period         : in unsigned(29 downto 0);
      duty_cycle     : in std_logic_vector(18 downto 0);
      pwm_output     : out std_logic;
      encoder_counts : out integer := 0
    );
  end component;

begin
  motor_driver_and_encoder : motor_interface
  port map(
    clk            => clk,
    rst            => reset,
    encoder_input  => encoder_input,
    encoder_counts => encoder_counts,
    period         => pwm_period(29 downto 0),
    duty_cycle     => duty_cycle(18 downto 0),
    pwm_output     => pwm_output
  );

  avalon_register_read : process (clk)
  begin
    if rising_edge(clk) and avs_read = '1' then
      case avs_address is
        when "00" =>
          avs_readdata <= std_logic_vector(pwm_period);
        when "01" =>
          avs_readdata <= duty_cycle;
        when "10" =>
          avs_readdata <= std_logic_vector(to_unsigned(encoder_counts, 32));
        when others             =>
          avs_readdata <= (others => '0');
      end case;
    end if;
  end process avalon_register_read;

  avalon_register_write : process (clk, reset)
  begin
    if reset = '1' then
      pwm_period <= "00000001000000000000000000000000";
      duty_cycle <= "00000000000000000000000000000000";
    elsif rising_edge(clk) and avs_write = '1' then
      case avs_address is
        when "00" =>
          pwm_period <= unsigned(avs_writedata);
        when "01" =>
          duty_cycle    <= avs_writedata;
          pwm_direction <= avs_writedata(31);
        when others =>
          null;

      end case;
    end if;
  end process avalon_register_write;

end architecture;