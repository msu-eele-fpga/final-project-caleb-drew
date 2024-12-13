# Inverted Pendulum and LCD Driver

## Table of Contents
### Custom hardware
- [LCD Custom Component](/hdl/LCD-Passthrough/README)
- [Motor Controller Component](/hdl/Motor-Interface/README.md)
- [RGB Controller Component](/hdl/RGB-Controller/README.md)
### Device tree and drivers
- [Device Tree](/linux/dts)
- [Custom Linux](/linux/Custom-Kernel/)
- [LCD Driver](/linux/LCD-Controller/README.md)
- [Motor Driver](/linux/Motor-Controller/README.md)
- [RGB Controller](linux/RGB-Controller/README.md)
- [ADC](/linux/ADC/README.md)

## System Overview


## LCD Hardware Component
The LCD Component was created twice, once that works purely in software [more details here](../hdl/LCD-Controller/README.md). A finalized version of this hardware component operates as almost a complete direct passthrough. This passthrough module [here](../hdl/LCD-Passthrough/README.md) allows for data from the avalon bus to be directly passed to an 8-bit parallel bus for the LCD to read. 

Please see the full documentation on each readme. 

## Custom Component 2
The Motor Interface component instantiates a encoder counter and a pwm generator component and is responsible for setting a direction pin such that it is easy to interact with a traditional motor driver [more info here](../hdl/Motor-Interface/README.md). The motor interface avalon component allows for control of the pwm output and direction as well as read acces to the counts from the encoder mounted to the dc motor[more info here](../hdl/Motor-Interface/README.md).

Please see the full documentation on each readme. 

## Conclusion
Overall the system was not completely sucessful. This was due to a lack of time to complete integration of the custom hardware components and software into a full working system. The system as it stands, is able to interface with each custom component through the device tree and custom drivers. This provides the basics for interfacing with the system. Given more time, the system can be more flushed out with supporting C code to allow for easier access. The hardware all works as expected when tested in isolation and mostly works when integrated together. 

