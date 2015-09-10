
/***************************** Include Files *********************************/

#include "CFG_controller.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/


/************************** Variable Prototypes ******************************/

/**
 * The configuration table for Config controller devices (taken from canonical definitions)
 */
CFG_Controller_Config CFG_Controller_ConfigTable[] =
{
		{
				XPAR_CFG_CONTROLLER_0_DEVICE_ID,/* Unique ID of device */
				XPAR_CFG_CONTROLLER_0_BASEADDR,	/**< Register base address */
				XPAR_CFG_CONTROLLER_0_CONFIG_CLK_FREQ_HZ,		/**< Configuration clock rate */
				XPAR_CFG_CONTROLLER_0_CONFIG_DATA_WIDTH,		/**< Configuration Data Width */
				XPAR_CFG_CONTROLLER_0_AES_SECURE_CONFIG,		/**< Configuration security mode */
				XPAR_CFG_CONTROLLER_0_CONFIG_DATA_IS_BIT_SWAPPED,		/**< Configuration data format */
				XPAR_CFG_CONTROLLER_0_NUMBER_OF_FPGAS_IN_CHAIN		/**< Number of configuration FPGAs */
		}
};


