# Device Driver for the RGB controller 
This device is reponsible for outputing pwm to the rgb led. 

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
 

## Notes / bugs


## Register map
