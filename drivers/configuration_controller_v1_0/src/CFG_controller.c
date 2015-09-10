#include "CFG_controller.h"
#include "xil_io.h"
//#include "xil_assert.h"
#include "xstatus.h"


int config_controller_CfgInitialize(CFG_Controller *InstancePtr, CFG_Controller_Config *Config, u32 EffectiveAddr)
{
	(void) Config;
	/*
	 * Assert validates the input arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);

	InstancePtr->Config_Clk_Freq_Hz = Config->Config_Clk_Freq_Hz;
	InstancePtr->Config_Data_Width = Config->Config_Data_Width;
	InstancePtr->AES_secure_config = Config->AES_secure_config;
	InstancePtr->config_data_is_bitswapped = Config->config_data_is_bitswapped;
	InstancePtr->number_of_FPGAs_in_chain = Config->number_of_FPGAs_in_chain;
	InstancePtr->BaseAddress = EffectiveAddr;
	return XST_SUCCESS;
}

void config_controller_set_register(CFG_Controller *InstancePtr, int offset, int value)
{
	Xil_Out32(InstancePtr->BaseAddress + offset, value);
}

int config_controller_get_register(CFG_Controller *InstancePtr, int offset)
{
	int temp = 0;
	temp = Xil_In32(InstancePtr->BaseAddress + offset);
	return (temp);
}

void config_controller_write_control_reg(CFG_Controller *InstancePtr, int value)
{
	config_controller_set_register(InstancePtr, CONFIG_CONTROLLER_CONTROL_REG_OFFSET, value);
}

void config_controller_write_reset_reg(CFG_Controller *InstancePtr, int value)
{
	config_controller_set_register(InstancePtr, CONFIG_CONTROLLER_SOFTWARE_RESET_REG_OFFSET, value);
}

void config_controller_write_data_fifo(CFG_Controller *InstancePtr, int value)
{
	config_controller_set_register(InstancePtr, CONFIG_CONTROLLER_DATA_REG_OFFSET, value);
}

int config_controller_read_control_reg(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_get_register(InstancePtr, CONFIG_CONTROLLER_CONTROL_REG_OFFSET);
	return (temp);
}

int config_controller_read_status_reg(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_get_register(InstancePtr, CONFIG_CONTROLLER_STATUS_REG_OFFSET);
	return (temp);
}

int config_controller_get_abort_status(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_get_register(InstancePtr, CONFIG_CONTROLLER_ABORT_STATUS_REG_OFFSET);
	return (temp);
}

void config_controller_start_configuration(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_control_reg(InstancePtr);
	temp = temp | CONFIG_CONTROLLER_CONTROL_GO_MASK;
	config_controller_write_control_reg(InstancePtr, temp);
}

void config_controller_reset(CFG_Controller *InstancePtr)
{
	// It doesn't matter what we write to the register, as long as we write something
	config_controller_write_reset_reg(InstancePtr, 0xDEADBEEF);
}

void config_controller_abort_configuration(CFG_Controller *InstancePtr)
{
	int temp = 0;
	config_controller_get_register(InstancePtr, CONFIG_CONTROLLER_CONTROL_REG_OFFSET);
	temp = temp | CONFIG_CONTROLLER_CONTROL_ABORT_MASK;
	config_controller_set_register(InstancePtr, CONFIG_CONTROLLER_CONTROL_REG_OFFSET, temp);
}

int config_controller_is_idle(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_status_reg(InstancePtr);
	temp = temp & CONFIG_CONTROLLER_STATUS_RUNNING_MASK;
	if (temp) return(0);
	else return (1);
}

int config_controller_is_done(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_status_reg(InstancePtr);
	temp = temp & CONFIG_CONTROLLER_STATUS_DONE_MASK;
	if (temp) return(1);
	else return (0);
}

int config_controller_is_error(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_status_reg(InstancePtr);
	temp = temp & CONFIG_CONTROLLER_STATUS_ERROR_MASK;
	if (temp) return(1);
	else return (0);
}

int config_controller_is_aborted(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_status_reg(InstancePtr);
	temp = temp & CONFIG_CONTROLLER_STATUS_ABORTED_MASK;
	if (temp) return(1);
	else return (0);
}

int config_controller_is_fifo_full(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_status_reg(InstancePtr);
	temp = temp & CONFIG_CONTROLLER_STATUS_DATA_FIFO_FULL_MASK;
	if (temp) return(1);
	else return (0);
}

int config_controller_is_fifo_almost_full(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_status_reg(InstancePtr);
	temp = temp & CONFIG_CONTROLLER_STATUS_DATA_FIFO_ALMOST_FULL_MASK;
	if (temp) return(1);
	else return (0);
}

int config_controller_is_fifo_empty(CFG_Controller *InstancePtr)
{
	int temp = 0;
	temp = config_controller_read_status_reg(InstancePtr);
	temp = temp & CONFIG_CONTROLLER_STATUS_DATA_FIFO_EMPTY_MASK;
	if (temp) return(1);
	else return (0);
}
