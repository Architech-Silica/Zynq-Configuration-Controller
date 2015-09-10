@echo off
set xv_path=C:\\Xilinx\\Vivado\\2015.2\\bin
call %xv_path%/xelab  -wto fadb2babf8654758940791c4d219aec3 -m64 --debug typical --relax --mt 6 -L fifo_generator_v12_0 -L xil_defaultlib -L axi_FPGA_configuration_controller -L work -L secureip --snapshot axi_FPGA_configuration_controller_testbench_behav work.axi_FPGA_configuration_controller_testbench -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
