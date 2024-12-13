# Motor_interface with avalon Interface 

This repository contains two main components : the **motor_interface** and the **motor_interface_avelon**. The motor interface cointains the encoder counter and the pwm generator. The motor interface avelon provides the write capability to the pwm output and direction pin and read capability of for the encoder counts. 

## Project Overview

The goal of this project is to create a simple hardware interface between the HPS and a DC motor driver. 

The design is structured into two primary components:
1. **Motor Interface**: Directly maps Avalon data to control the output pwm, direction pin and counts encoder pulses. 
2. **Avalon Interface**: Provides the interface for Avalon bus read and write operations, driving the motor interfacemodule.

## Key Features:
- **Avalon Bus Interface**: Supports standard Avalon read and write operations as well as sets the direction output pin
- **Motor Interface**: Wraps the pwm generator and encoder counter in to one device.
- **Encoder Counter**: Interacts with a quadrature encoder and stores the counts to track the position of the motor. 
- **Direction Control**: Implement direction pin output to drive a typical motor driver. 
  
## VHDL Code

### Motor Interface

This Component is intended to interface the fpga with a dc motor driver and the encoder mounted to a DC Motor. 

LCD Pass-Through Module:
- clk: Input clock signal that synchronizes the operation of the module.
- rst: Input reset signal to initialize the module.
- encoder_input: input signal for the A and B channel of a quadrature encoder
- period : input signal that sets the period of the pwm output 
- duty_cycle : This signal sets the duty cycle of the pwm output 
- pwm_output : This is a pwm output signal
- encoder_counts : This is an output signal that contains the number of counts of the encoder
```vhdl
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
```

### Avalon Component 
- clk: Input clock signal.
- reset: Input reset signal.
- avs_read: Avalon bus read signal.
- avs_write: Avalon bus write signal.
- avs_address: Avalon bus address signal (2 bits).
- avs_readdata: Avalon bus data read signal (32 bits).
- avs_writedata: Avalon bus data write signal (32 bits).
- pwm_direction: Direction pin output 

```vhdl
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
```



