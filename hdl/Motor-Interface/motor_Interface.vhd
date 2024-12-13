--
-- EELE - 467 Final project
-- Montana State University Fall 2024
-- Created 12/10/24 Caleb Binfet
-- License : GPL
-- This compoennt will control a motor driver to drive a DC Motor as well as interpret the signals from a quadrature encoder
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity motor_interface is
  port (
    clk            : in std_logic;
    rst            : in std_logic;
    encoder_input  : in std_logic_vector(1 downto 0); -- "AB" input wiring
    period         : in unsigned(29 downto 0);
    duty_cycle     : in std_logic_vector(18 downto 0);
    pwm_output     : out std_logic;
    encoder_counts : out integer := 0
  );
end entity motor_interface;

architecture motor_interface_arch of motor_interface is

  component pwm_controller is
    generic (
      CLK_PERIOD   : time    := 20 ns;
      W_PERIOD     : integer := 30;
      W_DUTY_CYCLE : integer := 19
    );
    port (
      clk        : in std_logic;
      rst        : in std_logic;
      period     : in unsigned(W_PERIOD - 1 downto 0);
      duty_cycle : in std_logic_vector(W_DUTY_CYCLE - 1 downto 0);
      output     : out std_logic
    );
  end component;

  component encoder_counter is
    port (
      clk    : in std_logic;
      rst    : in std_logic;
      input  : in std_logic_vector(1 downto 0);
      counts : out integer := 0
    );
  end component encoder_counter;
begin

  pwm_driver : pwm_controller
  generic map(
    CLK_PERIOD   => 20 ns,
    W_PERIOD     => 30,
    W_DUTY_CYCLE => 19
  )
  port map(
    clk        => clk,
    rst        => rst,
    period     => period,
    duty_cycle => duty_cycle,
    output     => pwm_output
  );

  position_feedback : encoder_counter
  port map(
    clk    => clk,
    rst    => rst,
    input  => encoder_input,
    counts => encoder_counts
  );

end architecture;