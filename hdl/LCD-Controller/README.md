# Final attempt at the LCD Controller in VHDL
Attempting to solve the off by one clock cycle error resulted in code that would simulate properly, compile properly but not function properly. As such this code is being abandoned. This branch will not be continued. A new branch will be created that will focus on a new LCD interface that will provide a direct pass through from the HPS.

> [!CAUTION]
> This code and work is being provided purely for documentation purposes. It does not function and the code would be left on a depreciated branch if documentation was not required. 


## General Functionality
The hardware will take in a write from the Avalon bus and then convert that into an 8-bit parallel transmission the LCD can work with. This involves setting the enable pin for the LCD for the latch cycle, then setting the data bits and holding the data bits for another latch. 

Once the transmission is complete, the system will enter an idle state waiting for another transmission.

## Simulation results of the system as is
This simulation simulates the Avalon bus interactions with the LCD controller and should be a 1 to 1 replication of the final platform designer functionality. However, this does not port to the fabric with the expected results. The screenshots are provided for documentation purposes. 

![](../../docs/assets/LCD-Controller-VHDL/Initial_write_finalattempt.png)
This screenshot shows the initial transmission of the system with all proper signals. The timing of the delays and flags being set is exactly as expected for proper functionality. 
![](../../docs/assets/LCD-Controller-VHDL/Full_transmission.png)
This screenshot shows the full transmission including multiple writes to the 8-bit bus. This shows the system resets properly and allows for multiple writes. The busy_flag is asserted and cleared properly. 

## Failures of the system
During operation, the busy_flag gets stuck either high or low and prevents data from being put on the 8-bit parallel bus. I don't know the source of this error as the system simulates as expected. 