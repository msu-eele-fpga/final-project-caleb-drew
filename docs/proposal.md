# Final project proposal


## Hardware/software proposal 1
<b> Drew Currie </b><br>
For the final project I will be implementing a LCD to display information related to the position of the inverted pendulum. I will be displaying on the 16x2 LCD the current angular position of the pendulum, the target angular positon, and the color of the RGB in RGB values (ie 255, 65, 23). This will provide data logging to the LCD for use with the pendulum. 

The software will interface with a display driver written in VHDL. The display driver will provide a series of registers for writing characters to the display and provide an access for controlling the LCD with special commands. (ie clear display, move cursor, etc).

The software will provide the calculated data to the driver to display on the LCD. This will involve calculating the RGB values being displayed on the LED, and displaying the information used to calculate the control loop for the inverted pendulum motor. 


## Hardware/software proposal 2
<b> Caleb Binfet </b><br>

For the final project I will be implementing VHDL hardware that will take in the encoder feedback from the DC Motor to compute the angular position of the inverted pendulum. 

The software portion will then be doing control calculations based on the feedback from the VHDL encoder counter as well as use feedback from the motor drivers current sensing. This feedback will then be used to determine the dutycycle and direction of the output pwm to the DC Motor. 

The input to the software control portion will be the desired angular position of the inverted pendulum. 

## Division of labor

Drew will be responsible for writing the hardware interface for the LCD and control algorithm for the inverted pendulum in software. 

Caleb will be responsible for the writing of the hardware interface for the motor driver and encoder. Caleb will be responsible for software for the LCD display.
