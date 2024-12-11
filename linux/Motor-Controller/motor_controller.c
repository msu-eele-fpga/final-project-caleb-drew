/*
 * DC Motor controller with Pololu G2 motor driver
 * Created by Drew Currie for EELE-467 Fall 2024 Montana State University
 * Designed to work with the DE10nano SoC FPGA Board
 */

#include <linux/module.h>          //: basic kernel module definitions
#include <linux/platform_device.h> //: platform driver/device definitions
#include <linux/mod_devicetable.h> //: of_device_id, MODULE_DEVICE_TABLE
#include <linux/io.h>              //: iowrite32/ioread32 functions
#include <linux/mutex.h>           // : mutex definitions
#include <linux/miscdevice.h>      /// : miscdevice definitions
#include <linux/types.h>           // : data types like u32, u16 etc.
#include <linux/fs.h>              // : copy_to_user, etc.
#include <linux/kstrtox.h>         //: kstrtouint, etc.

//-------------- Define memory offsets ----------------------------------------------
#define PERIOD_OFFSET 0
#define DUTY_CYCLE_OFFSET 4
#define COUNTS_OFFSET 8
#define SPAN 12

//------------- Motor interface memory mapping
/**
 * struct motor_interface_dev - Private rgb controller device struct.
 * @base_addr: Pointer to the component's base address
 * @global_period: Address of the global_period register
 * @red_duty_cycle: Address of the red_duty_cycle register
 * @green_duty_cycle: Address of the green_duty_cycle register
 * @blue_duty_cycle: Address of the blue_duty_cycle register
 *
 * An motor_interface_dev struct gets created for each rgb controller component.
 */
struct motor_interface_dev
{
    void __iomem *base_addr;
    void __iomem *period;
    void __iomem *duty_cycle;
    void __iomem *counts;
    struct miscdevice miscdev;
    struct mutex lock;
};
//-------- End motor interface memory mapping --------------------------------------

//------- Motor interface read and write functions --------------------------------
/**
 * motor_interface_read() - Read method for the motor_interface char device
 * @file: Pointer to the char device file struct.
 * @buf: User-space buffer to read the value into.
 * @count: The number of bytes being requested.
 * @offset: The byte offset in the file being read from.
 *
 * Return: On success, the number of bytes written is returned and the
 * offset @offset is advanced by this number. On error, a negative error
 * value is returned.
 */
static ssize_t motor_interface_read(struct file *file, char __user *buf, size_t count, loff_t *offset)
{
    size_t ret;
    u32 val;

    /*
     * Get the device's private data from the file struct's private_data
     * field. The private_data field is equal to the miscdev field in the
     * motor_interface_dev struct. container_of returns the
     * motor_interface_dev struct that contains the miscdev in private_data.
     */
    struct motor_interface_dev *priv = container_of(file->private_data, struct motor_interface_dev, miscdev);

    // Check file offset to make sure we are reading from a valid location.
    if (*offset < 0)
    {
        // We can't read from a negative file position.
        return -EINVAL;
    }
    if (*offset >= SPAN)
    {
        // We can't read from a position past the end of our device.
        return 0;
    }
    if ((*offset % 0x4) != 0)
    {
        // Prevent unaligned access.
        pr_warn("motor_interface_read: unaligned access\n");
        return -EFAULT;
    }

    val = ioread32(priv->base_addr + *offset);

    // Copy the value to userspace.
    ret = copy_to_user(buf, &val, sizeof(val));
    if (ret == sizeof(val))
    {
        pr_warn("motor_interface_read: nothing copied\n");
        return -EFAULT;
    }

    // Increment the file offset by the number of bytes we read.
    *offset = *offset + sizeof(val);

    return sizeof(val);
}
/**
 * motor_interface_write() - Write method for the motor_interface char device
 * @file: Pointer to the char device file struct.
 * @buf: User-space buffer to read the value from.
 * @count: The number of bytes being written.
 * @offset: The byte offset in the file being written to.
 *
 * Return: On success, the number of bytes written is returned and the
 * offset @offset is advanced by this number. On error, a negative error
 * value is returned.
 */
static ssize_t motor_interface_write(struct file *file, const char __user *buf, size_t count, loff_t *offset)
{
    size_t ret;
    u32 val;

    struct motor_interface_dev *priv = container_of(file->private_data, struct motor_interface_dev, miscdev);

    if (*offset < 0)
    {
        return -EINVAL;
    }
    if (*offset >= SPAN)
    {
        return 0;
    }
    if ((*offset % 0x4) != 0)
    {
        pr_warn("motor_interface_write: unaligned access\n");
        return -EFAULT;
    }

    mutex_lock(&priv->lock);

    // Get the value from userspace.
    ret = copy_from_user(&val, buf, sizeof(val));
    if (ret != sizeof(val))
    {
        iowrite32(val, priv->base_addr + *offset);

        // Increment the file offset by the number of bytes we wrote.
        *offset = *offset + sizeof(val);

        // Return the number of bytes we wrote.
        ret = sizeof(val);
    }
    else
    {
        pr_warn("motor_interface_write: nothing copied from user space\n");
        ret = -EFAULT;
    }

    mutex_unlock(&priv->lock);
    return ret;
}
//------- End motor interface read and write functions -----------------------------

//------ File operations -----------------------------------------------------------
/**
 * motor_interface_fops - File operations supported by the
 * motor_interface driver
 * @owner: The motor_interface driver owns the file operations; this
 * ensures that the driver can't be removed while the
 * character device is still in use.
 * @read: The read function.
 * @write: The write function.
 * @llseek: We use the kernel's default_llseek() function; this allows
 * users to change what position they are writing/reading to/from.
 */
static const struct file_operations motor_interface_fops = {
    .owner = THIS_MODULE,
    .read = motor_interface_read,
    .write = motor_interface_write,
    .llseek = default_llseek,
};
//----- End file operations -----------------------------------------------------

//--------------- Driver Functions ----------------------------------------------

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
    struct motor_interface_dev *priv;
    size_t ret;

    /*
     * Allocate kernel memory for the rgb patterns device and set it to 0.
     * GFP_KERNEL specifies that we are allocating normal kernel RAM;
     * see the kmalloc documentation for more info. The allocated memory
     * is automatically freed when the device is removed.
     */
    priv = devm_kzalloc(&pdev->dev, sizeof(struct motor_interface_dev), GFP_KERNEL);
    if (!priv)
    {
        pr_err("Failed to allocate memory\n");
        return -ENOMEM;
    }

    /*
     * Request and remap the device's memory region. Requesting the region
     * make sure nobody else can use that memory. The memory is remapped
     * into the kernel's virtual address space because we don't have access
     * to physical memory locations.
     */
    priv->base_addr = devm_platform_ioremap_resource(pdev, 0);
    if (IS_ERR(priv->base_addr))
    {
        pr_err("Failed to request/remap platform device resource\n");
        return PTR_ERR(priv->base_addr);
    }

    // Set the memory addresses for each register.
    priv->period = priv->base_addr + PERIOD_OFFSET;
    priv->duty_cycle = priv->base_addr + DUTY_CYCLE_OFFSET;
    priv->counts = priv->base_addr + COUNTS_OFFSET;

    // Initialize the misc device parameters
    priv->miscdev.minor = MISC_DYNAMIC_MINOR;
    priv->miscdev.name = "motor_interface";
    priv->miscdev.fops = &motor_interface_fops;
    priv->miscdev.parent = &pdev->dev;

    iowrite32(1, priv->period);
    // Register the misc device; this creates a char dev at /dev/motor_interface
    ret = misc_register(&priv->miscdev);

    if (ret)
    {
        pr_err("Failed to register misc device");
        return ret;
    }

    /* Attach the motor_interface's private data to the platform device's struct.
     * This is so we can access our state container in the other functions.
     */
    platform_set_drvdata(pdev, priv);
    pr_info("motor_interface_probe successful\n");

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
    // Get the rgb_controler's private data from the platform device.
    struct motor_interface_dev *priv = platform_get_drvdata(pdev);

    // Disable software-control mode, just for kicks.
    iowrite32(0, priv->period);
    // Deregister the misc device and remove the /dev/motor_interface file.
    misc_deregister(&priv->miscdev);

    pr_info("motor_interface_remove successful\n");

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

//--------------- User space interactions ---------------------------------------
static ssize_t duty_cycle_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    uint32_t duty_cycle;
    struct motor_interface_dev *priv = dev_get_drvdata(dev);

    duty_cycle = ioread32(priv->duty_cycle);

    return scnprintf(buf, PAGE_SIZE, "%u\n", duty_cycle);
}

static ssize_t duty_cycle_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
    uint32_t duty_cycle;
    int ret;
    struct motor_interface_dev *priv = dev_get_drvdata(dev);

    ret = kstrtouint(buf, 0, &duty_cycle);
    if (ret < 0)
        return ret;

    iowrite32(duty_cycle, priv->duty_cycle);

    return size;
}

static ssize_t period_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    uint32_t period;
    struct motor_interface_dev *priv = dev_get_drvdata(dev);

    period = ioread32(priv->period);

    return scnprintf(buf, PAGE_SIZE, "%u\n", period);
}
static ssize_t period_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
    uint32_t period;
    int ret;
    struct motor_interface_dev *priv = dev_get_drvdata(dev);

    ret = kstrtouint(buf, 0, &period);
    if (ret < 0)
        return ret;

    iowrite32(period, priv->period);

    return size;
}
static ssize_t counts_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    uint32_t counts;
    struct motor_interface_dev *priv = dev_get_drvdata(dev);

    counts = ioread32(priv->counts);

    return scnprintf(buf, PAGE_SIZE, "%u\n", counts);
}
static ssize_t counts_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
    uint32_t counts;
    int ret;
    struct motor_interface_dev *priv = dev_get_drvdata(dev);

    ret = kstrtouint(buf, 0, &counts);
    if (ret < 0)
        return ret;

    iowrite32(counts, priv->counts);

    return size;
}

static DEVICE_ATTR_RW(period);
static DEVICE_ATTR_RW(duty_cycle);
static DEVICE_ATTR_RW(counts);
//-------------- Create struct and set general info ------------------------------
static struct attribute *motor_interface_attrs[] = {
    &dev_attr_period.attr,
    &dev_attr_duty_cycle.attr,
    &dev_attr_counts.attr,
    NULL,
};
ATTRIBUTE_GROUPS(motor_interface);
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
        .dev_groups = motor_interface_groups,

    },
};

//--------------- End Device Struct ----------------------------------------------
/*
 * Creating module and setting licensing etc.
 */

module_platform_driver(motor_interface_driver);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Drew Currie");
MODULE_DESCRIPTION("motor_interface driver");