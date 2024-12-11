#include <linux/module.h>: basic kernel module definitions
#include <linux/platform_device.h>: platform driver/device definitions
#include <linux/mod_devicetable.h>: of_device_id, MODULE_DEVICE_TABLE
#include <linux/io.h>: iowrite32/ioread32 functions
#include <linux/mutex.h> : mutex definitions
#include <linux/miscdevice.h> : miscdevice definitions
#include <linux/types.h> : data types like u32, u16 etc.
#include <linux/fs.h> : copy_to_user, etc.
#include <linux/kstrtox.h> : kstrtouint, etc.

#define GLOBAL_PERIOD_OFFSET 0
#define RED_DUTY_CYCLE_OFFSET 4
#define GREEN_DUTY_CYCLE_OFFSET 8
#define BLUE_DUTY_CYCLE_OFFSET 12
#define SPAN 20

/**
 * struct rgb_controller_dev - Private rgb controller device struct.
 * @base_addr: Pointer to the component's base address
 * @global_period: Address of the global_period register
 * @red_duty_cycle: Address of the red_duty_cycle register
 * @green_duty_cycle: Address of the green_duty_cycle register
 * @blue_duty_cycle: Address of the blue_duty_cycle register
 *
 * An rgb_controller_dev struct gets created for each rgb controller component.
 */
struct rgb_controller_dev
{
    void __iomem *base_addr;
    void __iomem *global_period;
    void __iomem *red_duty_cycle;
    void __iomem *green_duty_cycle;
    void __iomem *blue_duty_cycle;
    struct miscdevice miscdev;
    struct mutex lock;
};

/**
 * rgb_controller_read() - Read method for the rgb_controller char device
 * @file: Pointer to the char device file struct.
 * @buf: User-space buffer to read the value into.
 * @count: The number of bytes being requested.
 * @offset: The byte offset in the file being read from.
 *
 * Return: On success, the number of bytes written is returned and the
 * offset @offset is advanced by this number. On error, a negative error
 * value is returned.
 */
static ssize_t rgb_controller_read(struct file *file, char __user *buf, size_t count, loff_t *offset)
{
    size_t ret;
    u32 val;

    /*
     * Get the device's private data from the file struct's private_data
     * field. The private_data field is equal to the miscdev field in the
     * rgb_controller_dev struct. container_of returns the
     * rgb_controller_dev struct that contains the miscdev in private_data.
     */
    struct rgb_controller_dev *priv = container_of(file->private_data, struct rgb_controller_dev, miscdev);

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
        pr_warn("rgb_controller_read: unaligned access\n");
        return -EFAULT;
    }

    val = ioread32(priv->base_addr + *offset);

    // Copy the value to userspace.
    ret = copy_to_user(buf, &val, sizeof(val));
    if (ret == sizeof(val))
    {
        pr_warn("rgb_controller_read: nothing copied\n");
        return -EFAULT;
    }

    // Increment the file offset by the number of bytes we read.
    *offset = *offset + sizeof(val);

    return sizeof(val);
}
/**
 * rgb_controller_write() - Write method for the rgb_controller char device
 * @file: Pointer to the char device file struct.
 * @buf: User-space buffer to read the value from.
 * @count: The number of bytes being written.
 * @offset: The byte offset in the file being written to.
 *
 * Return: On success, the number of bytes written is returned and the
 * offset @offset is advanced by this number. On error, a negative error
 * value is returned.
 */
static ssize_t rgb_controller_write(struct file *file, const char __user *buf, size_t count, loff_t *offset)
{
    size_t ret;
    u32 val;

    struct rgb_controller_dev *priv = container_of(file->private_data, struct rgb_controller_dev, miscdev);

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
        pr_warn("rgb_controller_write: unaligned access\n");
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
        pr_warn("rgb_controller_write: nothing copied from user space\n");
        ret = -EFAULT;
    }

    mutex_unlock(&priv->lock);
    return ret;
}

/**
 * rgb_controller_fops - File operations supported by the
 * rgb_controller driver
 * @owner: The rgb_controller driver owns the file operations; this
 * ensures that the driver can't be removed while the
 * character device is still in use.
 * @read: The read function.
 * @write: The write function.
 * @llseek: We use the kernel's default_llseek() function; this allows
 * users to change what position they are writing/reading to/from.
 */
static const struct file_operations rgb_controller_fops = {
    .owner = THIS_MODULE,
    .read = rgb_controller_read,
    .write = rgb_controller_write,
    .llseek = default_llseek,
};

static int rgb_controller_probe(struct platform_device *pdev)
{
    struct rgb_controller_dev *priv;
    size_t ret;

    /*
     * Allocate kernel memory for the rgb patterns device and set it to 0.
     * GFP_KERNEL specifies that we are allocating normal kernel RAM;
     * see the kmalloc documentation for more info. The allocated memory
     * is automatically freed when the device is removed.
     */
    priv = devm_kzalloc(&pdev->dev, sizeof(struct rgb_controller_dev), GFP_KERNEL);
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
    priv->global_period = priv->base_addr + GLOBAL_PERIOD_OFFSET;
    priv->red_duty_cycle = priv->base_addr + RED_DUTY_CYCLE_OFFSET;
    priv->green_duty_cycle = priv->base_addr + GREEN_DUTY_CYCLE_OFFSET;
    priv->blue_duty_cycle = priv->base_addr + BLUE_DUTY_CYCLE_OFFSET;

    // Initialize the misc device parameters
    priv->miscdev.minor = MISC_DYNAMIC_MINOR;
    priv->miscdev.name = "rgb_controller";
    priv->miscdev.fops = &rgb_controller_fops;
    priv->miscdev.parent = &pdev->dev;

    iowrite32(1, priv->global_period);
    // Register the misc device; this creates a char dev at /dev/rgb_controller
    ret = misc_register(&priv->miscdev);

    if (ret)
    {
        pr_err("Failed to register misc device");
        return ret;
    }

    /* Attach the rgb_controller's private data to the platform device's struct.
     * This is so we can access our state container in the other functions.
     */
    platform_set_drvdata(pdev, priv);
    pr_info("rgb_controller_probe successful\n");

    return 0;
}

static int rgb_controller_remove(struct platform_device *pdev)
{
    // Get the rgb_controler's private data from the platform device.
    struct rgb_controller_dev *priv = platform_get_drvdata(pdev);

    // Disable software-control mode, just for kicks.
    iowrite32(0, priv->global_period);
    // Deregister the misc device and remove the /dev/rgb_controller file.
    misc_deregister(&priv->miscdev);

    pr_info("rgb_controller_remove successful\n");

    return 0;
}

/*
 * Define the compatible property used for matching devices to this driver,
 * then add our device id structure to the kernel's device table. For a device
 * to be matched with this driver, its device tree node must use the same
 * compatible string as defined here.
 */
static const struct of_device_id rgb_controller_of_match[] = {
    {
        .compatible = "Binfet,rgb_controller",
    },
    {}};
MODULE_DEVICE_TABLE(of, rgb_controller_of_match);

static ssize_t green_duty_cycle_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    uint32_t green_duty_cycle;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    green_duty_cycle = ioread32(priv->green_duty_cycle);

    return scnprintf(buf, PAGE_SIZE, "%u\n", green_duty_cycle);
}

static ssize_t green_duty_cycle_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
    uint32_t green_duty_cycle;
    int ret;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    ret = kstrtouint(buf, 0, &green_duty_cycle);
    if (ret < 0)
        return ret;

    iowrite32(green_duty_cycle, priv->green_duty_cycle);

    return size;
}

static ssize_t global_period_show(struct device *dev,
                                  struct device_attribute *attr, char *buf)
{
    bool hps_control;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    hps_control = ioread32(priv->global_period);

    return scnprintf(buf, PAGE_SIZE, "%u\n", hps_control);
}

static ssize_t global_period_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
    bool hps_control;
    int ret;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    ret = kstrtobool(buf, &hps_control);
    if (ret < 0)
        return ret;

    iowrite32(hps_control, priv->global_period);

    return size;
}

static ssize_t red_duty_cycle_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    uint32_t red_duty_cycle;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    red_duty_cycle = ioread32(priv->red_duty_cycle);

    return scnprintf(buf, PAGE_SIZE, "%u\n", red_duty_cycle);
}

static ssize_t red_duty_cycle_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
    uint32_t red_duty_cycle;
    int ret;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    ret = kstrtouint(buf, 0, &red_duty_cycle);
    if (ret < 0)
        return ret;

    iowrite32(red_duty_cycle, priv->red_duty_cycle);

    return size;
}

static ssize_t blue_duty_cycle_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    uint32_t blue_duty_cycle;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    blue_duty_cycle = ioread32(priv->blue_duty_cycle);

    return scnprintf(buf, PAGE_SIZE, "%u\n", blue_duty_cycle);
}

static ssize_t blue_duty_cycle_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t size)
{
    uint32_t blue_duty_cycle;
    int ret;
    struct rgb_controller_dev *priv = dev_get_drvdata(dev);

    ret = kstrtouint(buf, 0, &blue_duty_cycle);
    if (ret < 0)
        return ret;

    iowrite32(blue_duty_cycle, priv->blue_duty_cycle);

    return size;
}

static DEVICE_ATTR_RW(global_period);
static DEVICE_ATTR_RW(red_duty_cycle);
static DEVICE_ATTR_RW(green_duty_cycle);
static DEVICE_ATTR_RW(blue_duty_cycle);

static struct attribute *rgb_controller_attrs[] = {
    &dev_attr_global_period.attr,
    &dev_attr_red_duty_cycle.attr,
    &dev_attr_green_duty_cycle.attr,
    &dev_attr_blue_duty_cycle.attr,
    NULL,
};
ATTRIBUTE_GROUPS(rgb_controller);

/*
 * struct rgb_controller_driver - Platform driver struct for the rgb_controller driver
 * @probe: Function that's called when a device is found
 * @remove: Function that's called when a device is removed
 * @driver.owner: Which module owns this driver
 * @driver.name: Name of the rgb_controller driver
 * @driver.of_match_table: Device tree match table
 */
static struct platform_driver rgb_controller_driver = {
    .probe = rgb_controller_probe,
    .remove = rgb_controller_remove,
    .driver = {
        .owner = THIS_MODULE,
        .name = "rgb_controller",
        .of_match_table = rgb_controller_of_match,
        .dev_groups = rgb_controller_groups,
    },
};

/*
 * We don't need to do anything special in module init/exit.
 * This macro automatically handles module init/exit.
 */
module_platform_driver(rgb_controller_driver);

MODULE_LICENSE("Dual MIT/GPL");
MODULE_AUTHOR("Caleb Binfet");
MODULE_DESCRIPTION("rgb_controller driver");
