#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

// TODO: update these offsets if your address are different
#define GLOBAL_PERIOD_OFFSET 0x0
#define RED_DUTY_CYCLE_OFFSET 0x4
#define GREEN_DUTY_CYCLE_OFFSET 0x08
#define BLUE_DUTY_CYCLE_OFFSET 0X0C

#define CHANNEL_0_OFFSET 0x0
#define CHANNEL_1_OFFSET 0X4
#define CHANNEL_2_OFFSET 0x8

#define MAX_DUTY_CYCLE 0x40000
#define MAX_ADC_READING 0xFFF

int main()
{
    FILE *adc;
    FILE *rgb_controller;
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


    adc = fopen("/dev/adc", "rb+");
    if (adc == NULL)
    {
        printf("failed to open file\n");
        exit(1);
    }

    rgb_controller = fopen("/dev/rgb_controller", "rb+");
    if (rgb_controller == NULL)
    {
        printf("failed to open file\n");
        exit(1);
    }

   
   // -- Get Raw ADC Values
    ret = fread(&red_raw, 4, 1, adc);

    ret = fread(&green_raw, 4, 1, adc);
    //printf("Channel 2 = 0x%x\n", green_raw);

    ret = fread(&blue_raw, 4, 1, adc);
    //printf("Channel 3 = 0x%x\n", blue_raw);


    // -- Calculate Duty Cycle Percentage
    red_duty_cycle = (float) red_raw / MAX_ADC_READING;
    green_duty_cycle = (float) green_raw / MAX_ADC_READING;
    blue_duty_cycle = (float) blue_raw / MAX_ADC_READING;

    // -- Convert to integer for Harware Computation
    red_duty_cycle_int =  (uint32_t)(red_duty_cycle * MAX_DUTY_CYCLE);
    green_duty_cycle_int = (uint32_t) (green_duty_cycle * MAX_DUTY_CYCLE);
    blue_duty_cycle_int = (uint32_t) (blue_duty_cycle * MAX_DUTY_CYCLE);


    // -- Write Values to pwmgen file
    ret = fseek(rgb_controller, RED_DUTY_CYCLE_OFFSET, SEEK_SET);
    ret = fwrite(&red_duty_cycle_int, 4, 1, rgb_controller);
    fflush(rgb_controller);
    sleep(1);

    ret = fseek(rgb_controller, GREEN_DUTY_CYCLE_OFFSET, SEEK_SET);
    ret = fwrite(&green_duty_cycle_int, 4, 1, rgb_controller);
    fflush(rgb_controller);
    sleep(1);

    ret = fseek(rgb_controller, BLUE_DUTY_CYCLE_OFFSET, SEEK_SET);
    ret = fwrite(&blue_duty_cycle_int, 4, 1, rgb_controller);
    fflush(rgb_controller);
    sleep(1);

    //-- Close Files
    fclose(adc);
    fclose(rgb_controller);
    return 0;
}
