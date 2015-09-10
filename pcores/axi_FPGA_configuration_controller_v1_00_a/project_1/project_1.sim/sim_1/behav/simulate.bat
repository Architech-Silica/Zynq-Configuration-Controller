@echo off
set xv_path=C:\\Xilinx\\Vivado\\2015.2\\bin
call %xv_path%/xsim axi_FPGA_configuration_controller_testbench_behav -key {Behavioral:sim_1:Functional:axi_FPGA_configuration_controller_testbench} -tclbatch axi_FPGA_configuration_controller_testbench.tcl -view C:/custom_xilinx_ip/MyProcessorIPLib/pcores/axi_FPGA_configuration_controller_v1_00_a/project_1/downstream_FPGA_model_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
