library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.print_pkg.all;
use work.assert_pkg.all;
use work.tb_pkg.all;

entity motor_interface_tb is
end entity motor_interface_tb;

architecture motor_interface_tb_arch of motor_interface_tb is

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

  signal clk_tb        : std_logic := '0';
  signal rst_tb        : std_logic := '0';
  signal input_tb      : std_logic_vector(1 downto 0);
  signal counts_tb     : integer                       := 0;
  signal period_tb     : unsigned(29 downto 0)         := "000001000000000000000000000000";
  signal duty_cycle_tb : std_logic_vector(18 downto 0) := "0110000000000000000";
  signal output_tb     : std_logic                     := '0';
begin

  dut : motor_interface
  port map(
    clk            => clk_tb,
    rst            => rst_tb,
    encoder_input  => input_tb,
    encoder_counts => counts_tb,
    period         => period_tb,
    duty_cycle     => duty_cycle_tb,
    pwm_output     => output_tb
  );

  clk_tb <= not clk_tb after CLK_PERIOD / 2;

  testing : process is
  begin
    input_tb <= "00";
    wait_for_clock_edges(clk_tb, 100);
    input_tb <= "10";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "11";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "01";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "00";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "01";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "11";
    wait_for_clock_edges(clk_tb, 50);

    wait_for_clock_edges(clk_tb, 210000);
    rst_tb <= '1';
    wait_for_clock_edges(clk_tb, 1000);
    period_tb(29 downto 24) <= to_unsigned(5, 6);
    period_tb(23 downto 0)  <= to_unsigned(0, 24);
    rst_tb                  <= '0';

    wait_for_clock_edges(clk_tb, 500000);
    duty_cycle_tb <= "0001000000000000000";
    wait_for_clock_edges(clk_tb, 1000000);
    std.env.finish;
  end process;
end architecture;
