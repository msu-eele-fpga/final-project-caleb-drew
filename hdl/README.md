# This Folder Contains all the hdl files for the project


## Files : 

### encoder_counter.vhd
    This Hardware component is reponsible for interfacing with the quadrature encoder mounted to the DC motor. It counts the pulses and outputs a signal named encoder_counts that is either incremented or decremented based on the diretion of rotation of the motor shaft.

### pwm_controller.vhd
    This hardware component is reponsible for generating pwm that will drive the motor driver and in sequece the motor. It has and adjustable duty cycle in order to control the amount of current flowing through the motor. 

### motor_interface.vhd
    This hardware component is reponsible for instantiating the encoder_counter.vhd and the pwm_controller.vhd to condense the ammount of hardware components that are interacted with by the avalon bus.

### motor_interface_avelon.vhd 
    This hardware component instantiates the motor_interface.vhd and is responsible for interfacing with the avelon bus such that the pwm duty cycle and encoder counts can be read by the arm processor. The most significant bit of the duty_cycle register is mapped to the direction pin such that the arm processor can control the direction pin of the motor driver.

### rgb_controller.vhd 
    This component is the same one created previosly in class. It instantiates three pwm controllers with the same period such that the three pwm outputs that drive and RGB LED can be controlled by the arm processor on the board. 
