# LCD Pass-Through Module with Avalon Interface

This repository contains two main components: the **LCD pass-through Avalon interface**. The combination of these components enables communication between an external 16x2 LCD Module (1602A-1) 
via the Avalon bus. The Avalon interface provides read/write capabilities, while the LCD pass-through module handles the actual data transmission to the LCD.

## Project Overview

The goal of this project is to create a simple hardware interface between the HPS and the LCD module through the Avalon Bus. The **Avalon interface** provides a standard mechanism to read from and write to an Avalon bus. The **LCD pass-through module** takes this data and directly transmits it to the LCD.

The design is structured into two primary components:
1. **LCD Pass-Through Module**: Directly maps Avalon data to the LCD’s 8-bit data bus and control lines (RS).
2. **Avalon Interface**: Provides the interface for Avalon bus read and write operations, driving the LCD pass-through module.

## Key Features:
- **Avalon Bus Interface**: Supports standard Avalon read and write operations.
- **LCD Pass-Through**: Maps the input data directly to the LCD.
- **Simple Design**: Minimal processing with direct data transmission to the LCD, ensuring quick and efficient operation.
- **Latch Control**: Implements a latch mechanism to control data timing for the LCD.
  
## VHDL Code

### LCD Pass-Through Module

This module directly maps input signals from an external source to the LCD, providing the necessary control signals and data output.

LCD Pass-Through Module:
- clk: Input clock signal that synchronizes the operation of the module.
- reset: Input reset signal to initialize the module.
- write_register: A 9-bit input register, where:
- write_register(7 downto 0) is the 8-bit data to be written to the LCD.
- write_register(8) controls the RS (Register Select) pin of the LCD.
- output_register: A 8-bit output register connected to the LCD data bus.
- rs: Output signal to the LCD to select the command or data register.
```vhdl
-- EELE - 467 Final project
-- Montana State University Fall 2024
-- Created 12/10/24 Drew Currie
-- License : GPL
-- This code will create a 10-bit register to interface
-- with the 16x2 LCD Module 1602A - 1.
--
-- This is an incredibly simple component that directly maps pins
-- to inputs from an external source.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_passthrough is
  port (
    -- Basic clock and reset input
    clk   : in std_logic;
    reset : in std_logic;
    
    -- LCD Specific inputs
    write_register : in std_logic_vector(8 downto 0);
    
    -- LCD Specific outputs
    output_register : out std_logic_vector(7 downto 0);
    rs              : out std_logic
  );
end entity;

architecture lcd_arch of lcd_passthrough is
begin
  rs              <= write_register(8);
  output_register <= write_register(7 downto 0);
end architecture lcd_arch;
```

### Avalon Component 

```vhdllibrary ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_avalon_passthrough is
  port (
    -- Basic inputs
    clk   : in std_logic;
    reset : in std_logic;
    
    -- Avalon interface flags
    avs_read  : in std_logic;
    avs_write : in std_logic;
    
    -- Avalon interface registers
    avs_address   : in std_logic_vector(1 downto 0);
    avs_readdata  : out std_logic_vector(31 downto 0);
    avs_writedata : in std_logic_vector(31 downto 0);
    
    -- External IO
    -- This combines the databits, RS, and Enable bits all into one output register
    lcd_output : out std_logic_vector(9 downto 0)
  );
end entity lcd_avalon_passthrough;
```


#### Avalon Interface Module
- clk: Input clock signal.
- reset: Input reset signal.
- avs_read: Avalon bus read signal.
- avs_write: Avalon bus write signal.
- avs_address: Avalon bus address signal (2 bits).
- avs_readdata: Avalon bus data read signal (32 bits).
- avs_writedata: Avalon bus data write signal (32 bits).
- lcd_output: Combined 10-bit output for data, RS, and enable control signals.


