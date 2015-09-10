#ifndef CFG_CONTROLLER_H /* prevent circular inclusions */
#define CFG_CONTROLLER_H /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

#include "xil_io.h"

// ADDRESS MAP REGISTER OFFSETS
#define CONFIG_CONTROLLER_DATA_REG_OFFSET 0x00
#define CONFIG_CONTROLLER_CONTROL_REG_OFFSET 0x04
#define CONFIG_CONTROLLER_STATUS_REG_OFFSET 0x08
#define CONFIG_CONTROLLER_ABORT_STATUS_REG_OFFSET 0x0C
#define CONFIG_CONTROLLER_BITSTREAM_LENGTH_REG_OFFSET 0x10
#define CONFIG_CONTROLLER_BITS_SENT_REG_OFFSET 0x14
#define CONFIG_CONTROLLER_CHAIN_ID_REG_OFFSET 0x18
#define CONFIG_CONTROLLER_SOFTWARE_RESET_REG_OFFSET 0x1C

// STATUS REGISTER BIT MASKS
#define CONFIG_CONTROLLER_STATUS_DONE_MASK 0x01
#define CONFIG_CONTROLLER_STATUS_RUNNING_MASK 0x02
#define CONFIG_CONTROLLER_STATUS_ERROR_MASK 0x04
#define CONFIG_CONTROLLER_STATUS_ABORTED_MASK 0x08
#define CONFIG_CONTROLLER_STATUS_DATA_FIFO_FULL_MASK 0x10
#define CONFIG_CONTROLLER_STATUS_DATA_FIFO_ALMOST_FULL_MASK 0x20
#define CONFIG_CONTROLLER_STATUS_DATA_FIFO_EMPTY_MASK 0x40

// CONTROL REGISTER BIT MASKS
#define CONFIG_CONTROLLER_CONTROL_GO_MASK 0x01
#define CONFIG_CONTROLLER_CONTROL_ABORT_MASK 0x02


// Struct definitions
typedef struct {
	int BaseAddress;
	int Config_Clk_Freq_Hz;
	int Config_Data_Width;
	int AES_secure_config;
	int config_data_is_bitswapped;
	int number_of_FPGAs_in_chain;
} CFG_Controller;

typedef struct {
	u16 DeviceId;		/**< Unique ID  of device */
	u32 RegBaseAddr;	/**< Register base address */
	u32 Config_Clk_Freq_Hz;		/**< Configuration clock rate */
	u8  Config_Data_Width;		/**< Configuration Data Width */
	u8  AES_secure_config;		/**< Configuration security mode */
	u8  config_data_is_bitswapped;		/**< Configuration data format */
	u8  number_of_FPGAs_in_chain;		/**< Number of configuration FPGAs */
} CFG_Controller_Config;


// Function prototypes
int config_controller_Initialize(CFG_Controller *InstancePtr, u16 DeviceId);
int config_controller_CfgInitialize(CFG_Controller *InstancePtr, CFG_Controller_Config *Config, u32 EffectiveAddr);
void config_controller_set_register(CFG_Controller *InstancePtr, int offset, int value);
int config_controller_get_register(CFG_Controller *InstancePtr, int offset);
void config_controller_write_control_reg(CFG_Controller *InstancePtr, int value);
void config_controller_write_reset_reg(CFG_Controller *InstancePtr, int value);
int config_controller_read_control_reg(CFG_Controller *InstancePtr);
int config_controller_read_status_reg(CFG_Controller *InstancePtr);
void config_controller_start_configuration(CFG_Controller *InstancePtr);
void config_controller_abort_configuration(CFG_Controller *InstancePtr);
int config_controller_is_idle(CFG_Controller *InstancePtr);
int config_controller_is_done(CFG_Controller *InstancePtr);
int config_controller_is_error(CFG_Controller *InstancePtr);
int config_controller_is_aborted(CFG_Controller *InstancePtr);
int config_controller_is_fifo_full(CFG_Controller *InstancePtr);
int config_controller_is_fifo_almost_full(CFG_Controller *InstancePtr);
int config_controller_is_fifo_empty(CFG_Controller *InstancePtr);
void config_controller_write_data_fifo(CFG_Controller *InstancePtr, int value);
void config_controller_reset(CFG_Controller *InstancePtr);
int config_controller_get_abort_status(CFG_Controller *InstancePtr);


#ifdef __cplusplus
}
#endif

#endif			/* end of protection macro */
