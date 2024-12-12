# Device Driver for the RGB controller 
This device is reponsible for outputing pwm to the rgb led. 

## Building
The Makefile in this directory cross-compiles the driver. Update the `KDIR` variable to point to your linux-socfpga repository directory.

Run `make` in this directory to build to kernel module.


## Device tree node

Use the following device tree node:
```devicetree
  //Hardware RGB controller
    //Connected to pins GPIO_0[0] through GPIO_0[2]
    rgb_controller: rgb_controller@ff20000{
        compatible = "Binfet,rgb_controller";
        reg = <0xff200000 16>;
    };
```


## Notes / bugs


## Register map
| Offset | Name             | R/W | Purpose                               |
| ------ | --------------   | --- | ------------------------------------- |
| 0x0    | Period           | R/W | Period of the PWM Outputs             |
| 0x4    | Red Duty Cycle   | R/W | Duty Cycle of Red PWM                 |
| 0x8    | Green Duty Cycle | R/W | Duty Cycle of Green PWM               |
| 0xC    | Blue Duty Cycle  | R/W | Duty Cycle of Blue PWM                |


