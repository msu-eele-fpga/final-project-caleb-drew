#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

// RGB Controller offsets
#define GLOBAL_PERIOD_OFFSET 0x0
#define RED_DUTY_CYCLE_OFFSET 0x4
#define GREEN_DUTY_CYCLE_OFFSET 0x08
#define BLUE_DUTY_CYCLE_OFFSET 0X0C

// ADC offsets
#define CHANNEL_0_OFFSET 0x0
#define CHANNEL_1_OFFSET 0X4
#define CHANNEL_2_OFFSET 0x8

// LCD Offsets
#define LCD_OUT_OFFSET 0x0

// Motor Controller offsets
#define PEROID_OFFSET 0x0
#define DUTY_CYCLE_OFFSET 0x4
#define COUNTS_OFFSET 0x8

#define MAX_DUTY_CYCLE 0x40000
#define MAX_ADC_READING 0xFFF

int main()
{
        // Open all the relevant files
        FILE *adc;
        FILE *rgb_controller;
        FILE *lcd_controller;
        FILE *motor_interface;

        uint32_t lcd_write = 0;
        size_t ret;
        uint32_t val;

        uint32_t red_raw = 0;
        uint32_t blue_raw = 0;
        uint32_t green_raw = 0;

        float red_duty_cycle = 0;
        float green_duty_cycle = 0;
        float blue_duty_cycle = 0;

        uint32_t red_duty_cycle_int = 0;
        uint32_t green_duty_cycle_int = 0;
        uint32_t blue_duty_cycle_int = 0;

        // Open ADC
        adc = fopen("/dev/adc", "rb+");
        if (adc == NULL)
        {
                printf("failed to open file at /dev/adc\n");
                exit(1);
        }
        // Open RGB
        rgb_controller = fopen("/dev/rgb_controller", "rb+");
        if (rgb_controller == NULL)
        {
                printf("failed to open file /dev/rgb_controller\n");
                exit(1);
        }
        // Open LCD
        lcd_controller = fopen("/dev/lcd_controller", "rb+");
        if (rgb_controller == NULL)
        {
                printf("failed to open lcd_controller at /dev/lcd_controller\n");
                exit(1);
        }
        // Open motor interface
        motor_interface = fopen("/dev/motor_interface", "rb+");
        if (rgb_controller == NULL)
        {
                printf("failed to open lcd_controller at /dev/motor_interface\n");
                exit(1);
        }

        // Good ol' infinite while loop
        while (1)
        {
                //--------------------- ADC RGB CONTROLLER ----------------------------------
                // -- Get Raw ADC Values
                ret = fread(&red_raw, 4, 1, adc);
                ret = fread(&green_raw, 4, 1, adc);
                ret = fread(&blue_raw, 4, 1, adc);
                ret = fseek(adc, 0, SEEK_SET);

                // -- Calculate Duty Cycle Percentage
                red_duty_cycle = (float)red_raw / MAX_ADC_READING;
                green_duty_cycle = (float)green_raw / MAX_ADC_READING;
                blue_duty_cycle = (float)blue_raw / MAX_ADC_READING;
                printf("RGB Values: %d, %d, %d\n\r", red_raw, green_raw, blue_raw);
                // -- Convert to integer for Hardware Computation
                red_duty_cycle_int = (uint32_t)(red_duty_cycle * MAX_DUTY_CYCLE);
                green_duty_cycle_int = (uint32_t)(green_duty_cycle * MAX_DUTY_CYCLE);
                blue_duty_cycle_int = (uint32_t)(blue_duty_cycle * MAX_DUTY_CYCLE);
                printf("RGB Duty Cycle Values: %d, %d, %d\n\r", red_duty_cycle_int, green_duty_cycle_int, blue_duty_cycle_int);
                // -- Write Values to pwmgen file
                ret = fseek(rgb_controller, RED_DUTY_CYCLE_OFFSET, SEEK_SET);
                ret = fwrite(&red_duty_cycle_int, 4, 1, rgb_controller);
                fflush(rgb_controller);

                ret = fseek(rgb_controller, GREEN_DUTY_CYCLE_OFFSET, SEEK_SET);
                ret = fwrite(&green_duty_cycle_int, 4, 1, rgb_controller);
                fflush(rgb_controller);

                ret = fseek(rgb_controller, BLUE_DUTY_CYCLE_OFFSET, SEEK_SET);
                ret = fwrite(&blue_duty_cycle_int, 4, 1, rgb_controller);
                fflush(rgb_controller);
                sleep(0.25);

                //---LCD Tests
                ret = fread(&lcd_write, 4, 1, lcd_controller);
                printf("LCD Value: %d\n", lcd_write);

                //--------------------- ADC RGB CONTROLLER ----------------------------------
        }

        return 0;
}
