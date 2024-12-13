# Device tree
This folder contians the device tree source file. 


## Additions to the device tree

    'rgb_controller: rgb_controller@ff20000{
        compatible = "Binfet,rgb_controller";
        reg = <0xff200000 20>;
    };
    
    de10nano_adc: de10nano_adc@ff200020{
        compatible = "Binfet,de10nano_adc";
        reg = <0xff200020 32>;
    };'
    
    The Code adds the listed devices to the device tree such that the compiled kernal modules can be used to interact with the added devices. 