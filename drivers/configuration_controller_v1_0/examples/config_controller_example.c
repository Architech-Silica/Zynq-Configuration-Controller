#include <stdio.h>
#include "CFG_controller.h"
#include "xparameters.h"
#include "xuartlite.h"
#include "ff.h"

// Set up the maximum permitted size of the bitstream here, in megabytes
#define FILE_SIZE_MB 3




#ifdef __ICCARM__
#pragma data_alignment = 32
u8 BitstreamDataBuffer[FILE_SIZE_MB*1024*1024];
u8 WriteDataAddress[FILE_SIZE_MB*1024*1024];
#pragma data_alignment = 4
#else
u8 BitstreamDataBuffer[FILE_SIZE_MB*1024*1024] __attribute__ ((aligned(32)));
u8 WriteDataAddress[FILE_SIZE_MB*1024*1024] __attribute__ ((aligned(32)));
#endif


// Function Prototypes
FRESULT scan_and_list_files (char* Path);


int main()
{
	static FIL fil;		/* File object */
	static FATFS fatfs;
	static char FileName[32] = "chip_f~1.bin";  // Observe 8.3 filename length rules!
	static char *SD_File;

	FRESULT Res;
	FILINFO file_info;

#if _USE_LFN
	static char lfn[_MAX_LFN + 1];   /* Buffer to store the LFN */
	fno.lfname = lfn;
	fno.lfsize = sizeof lfn;
#endif


	UINT NumBitstreamBytesRead;
	u32 FileSize = (FILE_SIZE_MB*1024*1024);
	TCHAR *Path = "0:/";

	int Bitstream_read_progress_bytes = 0;

	CFG_Controller my_CFG_controller;
	int temp = 0xDA7ADA7A;
	int temp_bitstream_data_word;


	// Initialise the CFG Controller instance.
	temp = config_controller_Initialize(&my_CFG_controller, XPAR_AXI_FPGA_CONFIGURATION_CONTROLLER_0_DEVICE_ID);

	// Welcome message
	printf("Hello TMC 2015!\n\r");
	printf("this is a github demo\n\r");

	// Reset the controller.  Any active status flags should de-assert
	printf("Resetting the CFG Controller\n\r");
	config_controller_reset(&my_CFG_controller);

	// Wait here until the CFG controller is in an idle state
	while (!config_controller_is_idle(&my_CFG_controller));


	// Register SD card volume work area, initialise device
	Res = f_mount(&fatfs, Path, 0);
	if (Res != FR_OK)
	{
		printf("ERROR:  Cannot mount SD card\n\r");
		return XST_FAILURE;
	}

	// Open a file with the required permissions
	// In this case we are creating new file with read/write permissions.
	SD_File = (char *)FileName;

	// List the contents of the SD card
	scan_and_list_files("0:/");

	// Check that the size of the bitstream is not larger than the buffer
	Res = f_stat(FileName, &file_info);
	if (Res != FR_OK)
	{
		printf("ERROR:  Cannot read file statistics\n\r");
		return XST_FAILURE;
	}

	// Print the size of the Bitstream file
	printf("File size = %d bytes\n\r", (int)file_info.fsize);

	if ((int)file_info.fsize > sizeof(BitstreamDataBuffer))
	{
		printf("ERROR:  Bitstream is too large!!\n\r");
		return (XST_FAILURE);
	}

	//	Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
	Res = f_open(&fil, SD_File, FA_OPEN_ALWAYS | FA_READ);
	if (Res)
	{
		switch (Res)
		{
		case FR_DISK_ERR			: printf("\n\r\n\r** f_open error (FR_DISK_ERR, A hard error occurred in the low level disk I/O layer)\n\r"); break;
		case FR_INT_ERR				: printf("\n\r\n\r** f_open error (FR_INT_ERR, Assertion failed)\n\r"); break;
		case FR_NOT_READY			: printf("\n\r\n\r** f_open error (FR_NOT_READY, The physical drive cannot work)\n\r"); break;
		case FR_NO_FILE				: printf("\n\r\n\r** f_open error (FR_NO_FILE, Could not find the file)\n\r"); break;
		case FR_NO_PATH				: printf("\n\r\n\r** f_open error (FR_NO_PATH, Could not find the path )\n\r"); break;
		case FR_INVALID_NAME		: printf("\n\r\n\r** f_open error (FR_INVALID_NAME, The path name format is invalid)\n\r"); break;
		case FR_DENIED				: printf("\n\r\n\r** f_open error (FR_DENIED, Access denied due to prohibited access or directory full)\n\r"); break;
		case FR_EXIST				: printf("\n\r\n\r** f_open error (FR_EXIST, Access denied due to prohibited access)\n\r"); break;
		case FR_INVALID_OBJECT		: printf("\n\r\n\r** f_open error (FR_INVALID_OBJECT, The file/directory object is invalid)\n\r"); break;
		case FR_WRITE_PROTECTED 	: printf("\n\r\n\r** f_open error (FR_WRITE_PROTECTED, The physical drive is write protected)\n\r"); break;
		case FR_INVALID_DRIVE		: printf("\n\r\n\r** f_open error (FR_INVALID_DRIVE, The logical drive number is invalid)\n\r"); break;
		case FR_NOT_ENABLED			: printf("\n\r\n\r** f_open error (FR_NOT_ENABLED, The volume has no work area)\n\r"); break;
		case FR_NO_FILESYSTEM		: printf("\n\r\n\r** f_open error (FR_NO_FILESYSTEM, There is no valid FAT volume)\n\r"); break;
		case FR_MKFS_ABORTED		: printf("\n\r\n\r** f_open error (FR_MKFS_ABORTED, The f_mkfs() aborted due to any parameter error)\n\r"); break;
		case FR_TIMEOUT				: printf("\n\r\n\r** f_open error (FR_TIMEOUT, Could not get a grant to access the volume within defined period)\n\r"); break;
		case FR_LOCKED				: printf("\n\r\n\r** f_open error (FR_LOCKED, The operation is rejected according to the file sharing policy)\n\r"); break;
		case FR_NOT_ENOUGH_CORE 	: printf("\n\r\n\r** f_open error (FR_NOT_ENOUGH_CORE, LFN working buffer could not be allocated)\n\r"); break;
		case FR_TOO_MANY_OPEN_FILES : printf("\n\r\n\r** f_open error (FR_TOO_MANY_OPEN_FILES, Number of open files > _FS_SHARE)\n\r"); break;
		case FR_INVALID_PARAMETER	: printf("\n\r\n\r** f_open error (FR_INVALID_PARAMETER, Given parameter is invalid)\n\r"); break;
		default						: printf("\n\r\n\r** f_open error (God knows what!!  It's something inexplicable! [error value = %d])\n\r", Res); break;
		}
		while(1);
	}


	// Move the pointer to the beginning of the file
	Res = f_lseek(&fil, 0);
	if (Res)
	{
		return XST_FAILURE;
	}


	// Read data from the file
	Res = f_read(&fil, (void*)BitstreamDataBuffer, FileSize, &NumBitstreamBytesRead);
	if (Res)
	{
		return XST_FAILURE;
	}

	printf("Before we start to push data into the FIFO...\n\r");
	printf("Control Reg = 0x%08X\n\r", config_controller_read_control_reg(&my_CFG_controller));
	printf("Status Reg = 0x%08X\n\r", config_controller_read_status_reg(&my_CFG_controller));


	// work through the entire bitstream
	while (Bitstream_read_progress_bytes < NumBitstreamBytesRead)
	{
		// If there is room in the config controller's FIFO, move data from the file buffer
		if (!config_controller_is_fifo_almost_full(&my_CFG_controller))
		{
			// Read four bytes from the buffer and assemble them into a word.
			temp_bitstream_data_word = 0;
			for (temp = 0; temp < 4; temp++)
			{
				// Do some data shifting to place the buffer data in the right byte of the word
				temp_bitstream_data_word = temp_bitstream_data_word | (int)BitstreamDataBuffer[Bitstream_read_progress_bytes+3-temp] << 8*temp;
			}
			config_controller_write_data_fifo(&my_CFG_controller, temp_bitstream_data_word);
			Bitstream_read_progress_bytes +=4;
		}
		else
		{
			// Once the FIFO is almost full, check that the controller is idle and start the configuration process
			if (config_controller_is_idle(&my_CFG_controller));
			{
				// Start the configuration controller
				printf("Before we start the configuration controller...\n\r");
				printf("Control Reg = 0x%08X\n\r", config_controller_read_control_reg(&my_CFG_controller));
				printf("Status Reg = 0x%08X\n\r", config_controller_read_status_reg(&my_CFG_controller));
				config_controller_start_configuration(&my_CFG_controller);
				printf("After we start the configuration controller...\n\r");
				printf("Control Reg = 0x%08X\n\r", config_controller_read_control_reg(&my_CFG_controller));
				printf("Status Reg = 0x%08X\n\r", config_controller_read_status_reg(&my_CFG_controller));
			}
		}
	}

	printf("Finished sending data to the FIFO!\n\r");

	// Close the file
	Res = f_close(&fil);
	if (Res) return XST_FAILURE;

	printf("Status Reg = 0x%08X\n\r", config_controller_read_status_reg(&my_CFG_controller));


	// Wait for the configuration controller to finish up
	temp = 0;
	while (!config_controller_is_done(&my_CFG_controller))
	{
		if (config_controller_is_error(&my_CFG_controller))
		{
			print("Configuration Controller reports ERROR\n\r");
		}
		// Create a timeout, just in case the controller doesn't complete
		if (temp > 100000)
		{
			printf("We got bored waiting.  Abort abort abort!...\n\r");
			// Generate a configuration abort
			config_controller_abort_configuration(&my_CFG_controller);

			// Wait until the controller aborts
			while (!(config_controller_is_aborted(&my_CFG_controller)))
			{
				printf("Status Reg = 0x%08X\n\r", config_controller_read_status_reg(&my_CFG_controller));
			}

			// Read back the abort status
			temp  = config_controller_get_abort_status(&my_CFG_controller);
			printf("Abort status = 0x%08X\n\r", temp);
		}
		temp++;
	}

	if (config_controller_is_done(&my_CFG_controller))
	{
		print("Configuration Controller reports DONE\n\r");
	}

	printf("Finished!\n\r");

	return 0;
}


FRESULT scan_and_list_files (char* Path)         /* path = Start node to be scanned (also used as work area) */
{
	FRESULT FileResult;
	FILINFO FileInfo;
	DIR Directory;
	int i;
	char *Filename;   /* This function assumes non-Unicode configuration */
#if _USE_LFN
	static char lfn[_MAX_LFN + 1];   /* Buffer to store the LFN */
	FileInfo.lfname = lfn;
	FileInfo.lfsize = sizeof lfn;
#endif


	FileResult = f_opendir(&Directory, Path);                       /* Open the directory */
	if (FileResult == FR_OK)
	{
		i = strlen(Path);
		for (;;)
		{
			FileResult = f_readdir(&Directory, &FileInfo);				/* Read a directory item */
			if (FileResult != FR_OK || FileInfo.fname[0] == 0) break;	/* Break on error or end of dir */
			if (FileInfo.fname[0] == '.') continue;             		/* Ignore dot entries */
#if _USE_LFN
			Filename = *FileInfo.lfname ? FileInfo.lfname : FileInfo.fname;
#else
			Filename = FileInfo.fname;
#endif
			if (FileInfo.fattrib & AM_DIR)  // Test to see whether this item is a directory
			{
				/* It is a directory */
				sprintf(&Path[i], "/%s", Filename);
				FileResult = scan_and_list_files(Path);  // Recursively call this function to list the contents of the directory.
				Path[i] = 0;
				if (FileResult != FR_OK) break;
			}
			else
			{
				/* It is a file. */
				printf("%s/%s\n", Path, Filename);
			}
		}
		f_closedir(&Directory);
	}

	return FileResult;
}
