# RGB Patterns

This folder contains rgb_patterns.c which is reponsible for reading the raw converted value from the adc component by opening the `dev/adc` folder and then converts that value to an integer and scales the value to be output by writing the interger value to `dev/rgb_controller` file.