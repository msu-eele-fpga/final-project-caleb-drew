/*
 * DC Motor controller with Pololu G2 motor driver
 * Created by Drew Currie for EELE-467 Fall 2024 Montana State University
 * Designed to work with the DE10nano SoC FPGA Board
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/mod_devicetable.h>

//--------------- Driver Functions --------------------------------------------------

/**
 * motor_interface_probe() - Initialize device when a match is found
 * @pdev: Platform device structure associated with dc motor driver device
 * pdev is automatically created by the driver core based on the
 *  device node
 *
 * When a device that is compatible with this led patterns driver is found, the
 * driver's probe function is called. This probe function gets called by the
 * kernel when a motor_interface device is found in the device tree.
 */
static int motor_interface_probe(struct platform_device *pdev)
{
    pr_info("detected motor_interface\n");

    return 0;
}

/**
 * motor_interface_remove() - Remove a motor_interface device.
 * @pdev: Platform device structure associated with the motor_interface.
 *
 * This function is called when a motor_interface device is removed or
 * the driver is removed.
 */
static int motor_interface_remove(struct platform_device *pdev)
{
    pr_info("motor_interface has gone away\n");

    return 0;
}
//---------------- End driver functions ---------------------------------------------

//---------------- Device compatibility ---------------------------------------------
/*
 * Define the compatible property used for matching devices to this driver,
 * then add motor_interface device id structure to the kernel's device table.
 *  For a device to be matched with this driver, its device tree node must
 * use the same compatible string as defined here.
 */
static const struct of_device_id motor_interface_of_match[] = {
    {
        .compatible = "Currie,motor_interface",
    },
    {}};
MODULE_DEVICE_TABLE(of, motor_interface_of_match);

//------------- End device compatibility -------------------------------------------

//--------------- Device Struct ----------------------------------------------------
/*
 * Struct motor_interface_driver - Platform driver struct for the DC motor driver
 * @probe: Function when device is found
 * @remove: Function call when device is removed
 * @driver.owner: Which module owns this driver
 * @driver.name: Name of the led_patterns driver
 * @driver.of_match_table: Device tree match table
 *
 */

static struct platform_driver motor_interface_driver = {
    .probe = motor_interface_probe,
    .remove = motor_interface_remove,
    .driver = {
        .owner = THIS_MODULE,
        .name = "motor_interface",
        .of_match_table = motor_interface_of_match,
    },
};

//--------------- End Device Struct ----------------------------------------------

//-------------- Create struct and set general info ------------------------------
/*
 * Creating module and setting licensing etc.
 */

module_platform_driver(motor_interface_driver);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Drew Currie");
MODULE_DESCRIPTION("motor_interface driver");