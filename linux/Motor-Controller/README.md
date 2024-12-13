# Pololu Motor Driver G2 High-Power motor driver

Connected to the FPGA on pins 2 and 3 is the Pololu 2991. This motor driver requires a pwm output and a direction pin that switches which output lead is the ground. 

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
 The encoder counts seems to work intermittantly I am unsure of if this is a current limitting issue of the source or a logic level problem.

## Register map


| Offset | Name           | R/W | Purpose                               |
| ------ | -------------- | --- | ------------------------------------- |
| 0x0    | Period         | R/W | Period of the PWM Output              |
| 0x4    | Duty cycle     | R/W | Duty cycle of motor PWM and direction |
| 0x8    | Encoder Counts | R   | Read encoder counts                   |


## Documentation

- [Pololu G2 High-Power Motor Driver Product Listing](https://www.pololu.com/product/2991)

