# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Configuration Parameters}]
  ipgui::add_param $IPINST -name "AES_SECURE_CONFIG" -parent ${Page_0} -layout horizontal
  ipgui::add_param $IPINST -name "CONFIG_DATA_IS_BIT_SWAPPED" -parent ${Page_0} -layout horizontal
  ipgui::add_param $IPINST -name "CONFIG_DATA_WIDTH" -parent ${Page_0} -layout horizontal
  ipgui::add_param $IPINST -name "NUMBER_OF_FPGAS_IN_CHAIN" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CONFIG_CLK_FREQ_HZ" -parent ${Page_0}

  #Adding Page
  set AXI_parameters [ipgui::add_page $IPINST -name "AXI parameters"]
  ipgui::add_param $IPINST -name "C_S_AXI_ACLK_FREQ_HZ" -parent ${AXI_parameters}
  ipgui::add_param $IPINST -name "C_S_AXI_ADDR_WIDTH" -parent ${AXI_parameters}
  ipgui::add_param $IPINST -name "C_S_AXI_DATA_WIDTH" -parent ${AXI_parameters}


}

proc update_PARAM_VALUE.AES_SECURE_CONFIG { PARAM_VALUE.AES_SECURE_CONFIG } {
	# Procedure called to update AES_SECURE_CONFIG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AES_SECURE_CONFIG { PARAM_VALUE.AES_SECURE_CONFIG } {
	# Procedure called to validate AES_SECURE_CONFIG
	return true
}

proc update_PARAM_VALUE.CONFIG_CLK_FREQ_HZ { PARAM_VALUE.CONFIG_CLK_FREQ_HZ } {
	# Procedure called to update CONFIG_CLK_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONFIG_CLK_FREQ_HZ { PARAM_VALUE.CONFIG_CLK_FREQ_HZ } {
	# Procedure called to validate CONFIG_CLK_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED { PARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED } {
	# Procedure called to update CONFIG_DATA_IS_BIT_SWAPPED when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED { PARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED } {
	# Procedure called to validate CONFIG_DATA_IS_BIT_SWAPPED
	return true
}

proc update_PARAM_VALUE.CONFIG_DATA_WIDTH { PARAM_VALUE.CONFIG_DATA_WIDTH } {
	# Procedure called to update CONFIG_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONFIG_DATA_WIDTH { PARAM_VALUE.CONFIG_DATA_WIDTH } {
	# Procedure called to validate CONFIG_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ { PARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ } {
	# Procedure called to update C_S_AXI_ACLK_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ { PARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ } {
	# Procedure called to validate C_S_AXI_ACLK_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN { PARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN } {
	# Procedure called to update NUMBER_OF_FPGAS_IN_CHAIN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN { PARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN } {
	# Procedure called to validate NUMBER_OF_FPGAS_IN_CHAIN
	return true
}


proc update_MODELPARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ { MODELPARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ PARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ}] ${MODELPARAM_VALUE.C_S_AXI_ACLK_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.CONFIG_CLK_FREQ_HZ { MODELPARAM_VALUE.CONFIG_CLK_FREQ_HZ PARAM_VALUE.CONFIG_CLK_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONFIG_CLK_FREQ_HZ}] ${MODELPARAM_VALUE.CONFIG_CLK_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.CONFIG_DATA_WIDTH { MODELPARAM_VALUE.CONFIG_DATA_WIDTH PARAM_VALUE.CONFIG_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONFIG_DATA_WIDTH}] ${MODELPARAM_VALUE.CONFIG_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.AES_SECURE_CONFIG { MODELPARAM_VALUE.AES_SECURE_CONFIG PARAM_VALUE.AES_SECURE_CONFIG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AES_SECURE_CONFIG}] ${MODELPARAM_VALUE.AES_SECURE_CONFIG}
}

proc update_MODELPARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED { MODELPARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED PARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED}] ${MODELPARAM_VALUE.CONFIG_DATA_IS_BIT_SWAPPED}
}

proc update_MODELPARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN { MODELPARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN PARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN}] ${MODELPARAM_VALUE.NUMBER_OF_FPGAS_IN_CHAIN}
}

