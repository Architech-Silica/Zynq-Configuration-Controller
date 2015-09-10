/***************************** Include Files ********************************/

#include "xstatus.h"
#include "CFG_controller_i.h"
#include "CFG_controller.h"


/************************** Constant Definitions ****************************/


/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/

/****************************************************************************
 *
 * Looks up the device configuration based on the unique device ID.  The table
 * CFG_Controller_ConfigTable contains the configuration info for each device in the
 * system.
 *
 * @param	DeviceId is the unique device ID to match on.
 *
 * @return	A pointer to the configuration data for the device, or
 *		NULL if no match was found.
 *
 * @note		None.
 *
 ******************************************************************************/
CFG_Controller_Config *config_controller_LookupConfig(u16 DeviceId)
{
	CFG_Controller_Config *CfgPtr = NULL;
	
        int Index;

	for (Index=0; Index < XPAR_CFG_CONTROLLER_NUM_INSTANCES; Index++) {
		if (CFG_Controller_ConfigTable[Index].DeviceId == DeviceId) {
			CfgPtr = &CFG_Controller_ConfigTable[Index];
			break;
		}
	}

	return CfgPtr;
}

/****************************************************************************/
/**
 *
 * Initialize a CFG_Controller instance.
 *
 * @param	InstancePtr is a pointer to the CFG_Controller instance.
 * @param	DeviceId is the unique id of the device controlled by this
 *		CFG_Controller instance.  Passing in a device id associates the
 *		generic CFG_Controller instance to a specific device, as chosen by
 *		the caller or application developer.
 *
 * @return
 * 		- XST_SUCCESS if everything starts up as expected.
 * 		- XST_DEVICE_NOT_FOUND if the device is not found in the
 *			configuration table.
 *
 * @note		None.
 *
 *****************************************************************************/
int config_controller_Initialize(CFG_Controller *InstancePtr, u16 DeviceId)
{
	CFG_Controller_Config *ConfigPtr;

	/*
	 * Assert validates the input arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * Lookup the device configuration in the configuration table. Use this
	 * configuration info when initializing this component.
	 */
	ConfigPtr = config_controller_LookupConfig(DeviceId);

	if (ConfigPtr == (CFG_Controller_Config *)NULL) {
		return XST_DEVICE_NOT_FOUND;
	}
	return config_controller_CfgInitialize(InstancePtr, ConfigPtr,
			ConfigPtr->RegBaseAddr);
}

