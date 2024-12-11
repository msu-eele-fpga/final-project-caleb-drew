# Pololu Motor Driver *MODEL NUMBER HERE*

Connected to the FPGA on pins *PIN NUMBERS HERE* is the Pololu *MODEL NUMBER*. This motor driver requires *.... More details here*

## Building

The Makefile in this directory cross-compiles the driver. Update the `KDIR` variable to point to your linux-socfpga repository directory.

Run `make` in this directory to build to kernel module.

## Device tree node

Use the following device tree node:
```devicetree
    //DC motor 
    motor_interface: motor_interface@ff200010{
        compatible = "Currie,motor_interface";
        reg = <0xff200010 12>;
        };
```

## Notes / bugs :bug:


## Register map


| Offset | Name           | R/W | Purpose                               |
| ------ | -------------- | --- | ------------------------------------- |
| 0x10   | Period         | R/W | Period of the PWM Output              |
| 0x14   | Duty cycle     | R/W | Duty cycle of motor PWM and direction |
| 0x18   | Encoder Counts | R   | Read encoder counts                   |


## Documentation

- [Pololu G2 High-Power Motor Driver Product Listing](https://www.pololu.com/product/2991)

