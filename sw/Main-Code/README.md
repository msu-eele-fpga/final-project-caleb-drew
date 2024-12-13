# main-loop 

main-loop is the compiled version of main.c for the arm processor on the DE10nano board.


## Overview

This infinite loop is reponsible for reading the adc values and outputing pwm values to the RGB LED as well as reading the adc value from the potentiometer that was used to set the targer angle of the motor then setting the pwm to the motor. The loop also read the positional feedback from the encoder. 


## Code Explanations


### fopen() Example
    // Open ADC
        adc = fopen("/dev/adc", "rb+");
        if (adc == NULL)
        {
                printf("failed to open file at /dev/adc\n");
                exit(1);
        }

The C function fopen() was used to open each individual file for the devices used 

### fseek() and fwrite() Examples 
     ret = fseek(lcd_controller, LCD_OUT_OFFSET, SEEK_SET);
        ret = fwrite(&lcd_function_set, 4, 1, lcd_controller);
        fflush(lcd_controller);
        sleep(0.5);


This is the process for writing to a register of a specific device. The file has to be flushed to force the write to be processed. 


