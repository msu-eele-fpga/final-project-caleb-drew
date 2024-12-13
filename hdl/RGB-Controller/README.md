# RGB LED 

This repository contains a PWM Controller implemented in VHDL for an RGB LED. This directory also contains a PWM controller to generate a PWM signal with a configurable period and duty cycle. It can be used in FPGA to control devices such as motors, LEDs, or other peripherals that require PWM signals for operation.

## Project Overview

### PWM Generator
The PWM Controller generates a PWM signal based on the input period and duty cycle. It uses the system clock as a reference and produces a square wave output, where the duty cycle determines how long the signal stays high during each period.

The **PWM Controller** is parameterized with:
- **Clock period**: The period of the system clock used to generate PWM signals.
- **PWM period**: The period of the PWM signal in clock cycles.
- **Duty cycle**: The proportion of the period during which the output signal is high.

#### Key Features:
- Configurable PWM **period** and **duty cycle**.
- Outputs a PWM signal based on the provided parameters.
- **Duty cycle limiting**: Ensures the duty cycle is within the valid range.
- Simple, low-latency PWM signal generation suitable for embedded systems.

### VHDL Code

#### Entity Declaration

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_controller is
  generic (
    CLK_PERIOD   : time    := 20 ns;     -- Clock period in nanoseconds
    W_PERIOD     : integer := 30;        -- Width of period in clock cycles
    W_DUTY_CYCLE : integer := 19         -- Width of duty cycle in clock cycles
  );
  port (
    clk : in std_logic;                     -- Input clock signal
    rst : in std_logic;                     -- Input reset signal
    period : in unsigned(W_PERIOD - 1 downto 0);  -- PWM period in clock cycles
    duty_cycle : in std_logic_vector(W_DUTY_CYCLE - 1 downto 0);  -- Duty cycle in percentage (0 to 100%)
    output : out std_logic                   -- PWM output signal
  );
end entity pwm_controller;
```

Inputs and Outputs:
Inputs:
- clk: System clock input.
- rst: Reset input. When active ('1'), the counter is reset, and the output is set to '0'.
- period: PWM period (in clock cycles). This value determines how often the PWM signal repeats.
- duty_cycle: PWM duty cycle. This value determines the percentage of the period that the PWM signal remains high. The duty cycle is represented in a 19-bit vector, where the range is from 0 to 100% (limited by the number of bits).
  
Outputs:
- output: PWM output signal. This is the generated PWM waveform, which will be '1' for a portion of the period defined by the duty cycle and '0' for the rest of the period.


### RGB Controller

This project implements an RGB Controller in VHDL, designed to control the red, green, and blue channels of an RGB LED. The module uses Pulse Width Modulation (PWM) to control the intensity of each color channel, allowing for a full range of color mixing and brightness adjustment.

### Project Overview

The **RGB Controller** interfaces with the Avalon memory-mapped interface for communication with the HPS. It allows you to set the **global period** (time duration of the PWM signal) and the **duty cycle** for each color channel (red, green, blue) through register reads and writes.

The controller outputs PWM signals for the red, green, and blue channels, which are typically connected to the respective pins of an RGB LED.

#### Key Features:
- Configurable **global period** for PWM signals.
- Independent duty cycle control for **red**, **green**, and **blue** channels.
- Avalon memory-mapped interface for easy integration with processors.
- Outputs PWM signals to control the brightness of each color channel.

### VHDL Code

#### Entity Declaration

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rgb_controller is
  port (
    clk : in std_ulogic;
    rst : in std_ulogic;
    -- Avalon memory-mapped slave interface
    avs_read      : in std_logic;
    avs_write     : in std_logic;
    avs_address   : in std_logic_vector(1 downto 0);
    avs_readdata  : out std_logic_vector(31 downto 0);
    avs_writedata : in std_logic_vector(31 downto 0);
    -- External I/O; export to top-level
    red_output   : out std_logic := '0';
    green_output : out std_logic := '0';
    blue_output  : out std_logic := '0'
  );
end entity rgb_controller;
```

Inputs and Outputs
Inputs:

- clk: System clock signal.
- rst: Reset signal to initialize the controller.
- avs_read: Avalon read signal for memory-mapped communication.
- avs_write: Avalon write signal for memory-mapped communication.
- avs_address: Address for accessing different control registers.
- avs_writedata: Data to be written to the registers.

Outputs:

- red_output: PWM signal controlling the red channel of the RGB LED.
- green_output: PWM signal controlling the green channel of the RGB LED.
- blue_output: PWM signal controlling the blue channel of the RGB LED.
- avs_readdata: Data read from the controller's registers.