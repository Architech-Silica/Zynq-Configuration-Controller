# Zynq Configuration Controller
A configuration controller solution allowing a Zynq device to configure downstream FPGAs.

*__Official releases of this IP can be found in the GitHub "Releases" tab above__*

-----------------------------------

##Overview
This IP is designed to be installed into the Xilinx Vivado / SDK tools, and enables users to create a way for a Zynq device to configure one or more downstream FPGA devices.  This controller is designed for the 7-series devices but, due to the universal nature of the bitstream format, it could also be used to configure older generation FPGAs.  As designs get more complex and require larger numbers of devices, it is often desirable to have one Zynq SoC device act as the configuration controller for the other FPGAs.  This approach also allows the use of a unified storage medium for the various bitstreams throughout the system.

*Note: This controller does not allow downstream Zynq-7000 devices to be configured.  This is because there are no "slave" configuration modes for Zynq-7000 devices, with the exception of the JTAG port.*

This library was created using the the [Xilinx Vivado 2015.2 tools](http://www.xilinx.com/support/download.html), but is likely to be forwards and backwards compatible with other versions.


##Xilinx Configuration Modes
Depending on the board layout, desired configuration speed, and I/O availability, users have a wide range of requirements for their configuration interfaces.  The configuration controller supports the following configuration interfaces:

- Slave Select Map (8 bit mode)
- Slave Select Map (16 bit mode)
- Slave Select Map (32 bit mode)
- Slave Serial mode (including daisy chains of FPGAs)



In all cases the PROG.B and INIT.B lines are monitored / driven automatically by the controller, enabling downstream devices to be configured using a simple API function call.

In Select Map modes, the controller will automatically generate chip select outputs based on the number of downstream FPGAs that the user specifies exists on the board.  In SelectMAP modes the user also has the option to abort a configuration operation.  The abort status data from the downstream device will be captured automatically by the configuration controller for analysis by the host software.

In all cases the controller supports bitstream data sources in both bit-swapped and non-bit-swapped format, and will modify the data automatically without manual user pre-processing.


##Structure based Software API
The configuration controller uses a "struct" based approach to facilitate ease of use.  The configuration options that were set by the HW engineering team are automatically populated in the struct when it is initialised using the supplied API function call.

<pre>
typedef struct {
	int BaseAddress;
	int Config_Clk_Freq_Hz;
	int Config_Data_Width;
	int AES_secure_config;
	int config_data_is_bitswapped;
	int number_of_FPGAs_in_chain;
} CFG_Controller;
</pre>


##Example API Function Calls

<pre>
// Initialisation and setup
int config_controller_Initialize(CFG_Controller *InstancePtr, u16 DeviceId);
int config_controller_CfgInitialize(CFG_Controller *InstancePtr, CFG_Controller_Config *Config, u32 EffectiveAddr);
void config_controller_reset(CFG_Controller *InstancePtr);

// Basic register accesses
void config_controller_set_register(CFG_Controller *InstancePtr, int offset, int value);
int config_controller_get_register(CFG_Controller *InstancePtr, int offset);

// Reset, Control and Status registers
void config_controller_write_control_reg(CFG_Controller *InstancePtr, int value);
int config_controller_read_control_reg(CFG_Controller *InstancePtr);
void config_controller_write_reset_reg(CFG_Controller *InstancePtr, int value);
int config_controller_read_status_reg(CFG_Controller *InstancePtr);

// Configuration control
void config_controller_write_data_fifo(CFG_Controller *InstancePtr, int value);
void config_controller_start_configuration(CFG_Controller *InstancePtr);
void config_controller_abort_configuration(CFG_Controller *InstancePtr);
int config_controller_get_abort_status(CFG_Controller *InstancePtr);

// Current status enquiries
int config_controller_is_idle(CFG_Controller *InstancePtr);
int config_controller_is_done(CFG_Controller *InstancePtr);
int config_controller_is_error(CFG_Controller *InstancePtr);
int config_controller_is_aborted(CFG_Controller *InstancePtr);
int config_controller_is_fifo_full(CFG_Controller *InstancePtr);
int config_controller_is_fifo_almost_full(CFG_Controller *InstancePtr);
int config_controller_is_fifo_empty(CFG_Controller *InstancePtr);
</pre>


## Installing the IP
Installing custom IP in the Xilinx Vivado and SDK tools is a simple task, but the directory structure is critical.  Libraries are often required for use across many different projects, and therefore it is advisable to create a directory on your PC which is accessible by many different Vivado / SDK projects.   If the library is required by multiple users, this folder could be created on a network drive.  In the case of this example, we shall create a custom IP directory at:
<pre>
C:\custom_xilinx_ip\
</pre>

The path beneath that location is the critical piece of the puzzle and must be:

<pre>
\MyProcessorIPLib\pcores\(name_of_the_custom_peripheral)\
\MyProcessorIPLib\drivers\(name_of_the_software_driver)\
</pre>

Therefore, for the supplied configuration controller, the full installation paths would be:

<pre>
C:\custom_xilinx_ip\MyProcessorIPLib\pcores\axi_FPGA_configuration_controller_v1_00_a
C:\custom_xilinx_ip\MyProcessorIPLib\drivers\configuration_controller_v1_0
</pre>

Once the files are in the correct locations, both Vivado and the Xilinx SDK (Eclipse) must be configured to point to these custom IP repositories.  This is achieved as follows:

### Vivado

- Open a Vivado block diagram
- Open the "IP Settings" GUI using the "gears" icon on the left of the block diagram.
- In the "IP Repositories" pane, click the green "+" icon and then browse to the location of your custom IP directory (e.g. `c:\custom_xilinx_ip`).
- Click the "Select" button to accept the browse path.
- The list of the available custom IP will appear in the pane at the bottom of the window.  You will see that this list also contains the "axi_FPGA_configuration_controller_v1_0" IP.
- Press "OK" to close the Project Settings 
*Please see the supplied screenshots for further guidance*

###Vivado IP Repository Settings
![alt tag](https://raw.github.com/Architech-Silica/Zynq-Configuration-Controller/master/Screenshots/Project_settings_IP_Repositories.jpg)

## Vivado Block Diagram
![alt tag](https://raw.github.com/Architech-Silica/Zynq-Configuration-Controller/master/Screenshots/block_diagram.jpg)

###Slave Select Map Mode Configuration
![alt tag](https://raw.github.com/Architech-Silica/Zynq-Configuration-Controller/master/Screenshots/slave_select_map_parameters.jpg)

###Slave Serial Mode Configuration
![alt tag](https://raw.github.com/Architech-Silica/Zynq-Configuration-Controller/master/Screenshots/slave_serial_parameters.jpg)

--------------------------------

## SDK

- Open the SDK Preferences using the menus, "Window -> Preferences".
- Navigate to the "Xilinx SDK -> Repositories" settings.
- In the "Global Repositories" section, click "New..." and then browse to the location of your custom IP directory (e.g. `c:\custom_xilinx_ip`).
- Click the "Apply" button.
- Click the "Rescan Repositories" button.
- Click "OK" to close the preferences window.

*Please see the supplied screenshots for further guidance*


## Including the configuration controller drivers within a BSP
The configuration controller drivers will be automatically selected when an instance of the configuration controller IP is included within an imported Hardware Platform.  Just like any other peripheral, the drivers can be manually selected if necessary: 

- Right click on the BSP in the Project Explorer and choose "Board Support Package Settings".
- In the list of supported peripherals, choose "configuration_controller" from the drop-down box in the driver column.
- Click "OK".
- The BSP will be automatically recompiled and the drivers will be included in the available sources.

![alt tag](https://raw.github.com/Architech-Silica/Zynq-Configuration-Controller/master/Screenshots/BSP_Settings.jpg)

## Using the Configuration Controller within a software application
An example software application project has been provided with this IP, enabling users to quickly and easily get started with this solution in their designs.  To import the application, simply click the "Import Examples" link in the BSP window within SDK.  This will automatically create an application project and BSP in the SDK.  The configuration controller example design uses the "xilffs" library to read the bitstream from a storage device such as an SD card.

*Note: The "xilffs" library is not essential in order to use the configuration controller.  Users might choose to fetch the bitstream data across the network and store it in DDR memory before pushing it into the configuration controller's FIFO.*

--------------------------------------

## Contributions
Code examples and drivers are provided for your use, but if you have created something fantastic then please feel free to contribute your own code back to this repository via a pull request in the usual fashion.  Please fork from this repo, then create a suitably named branch in your fork before submitting back to this repo.  Please don't submit a pull request from your "master" branch.  Each new addition to the code should belong to its own submitted branch.  Thanks. 


