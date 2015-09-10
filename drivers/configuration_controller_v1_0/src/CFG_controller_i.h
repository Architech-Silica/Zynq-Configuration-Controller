#ifndef CFG_CONTROLLER_I_H /* prevent circular inclusions */
#define CFG_CONTROLLER_I_H /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files ********************************/

#include "CFG_controller.h"
#include "xuartlite_l.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/* the configuration table */
extern CFG_Controller_Config CFG_Controller_ConfigTable[];

/************************** Function Prototypes *****************************/

#ifdef __cplusplus
}
#endif

#endif		/* end of protection macro */

