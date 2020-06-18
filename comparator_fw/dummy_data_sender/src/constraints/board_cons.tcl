set_property PACKAGE_PIN AD23 [get_ports clk_i]
set_property IOSTANDARD LVCMOS25 [get_ports clk_i]
set_property PACKAGE_PIN Y18 [get_ports led_o]
set_property IOSTANDARD LVCMOS18 [get_ports led_o]
set_property PACKAGE_PIN AB17 [get_ports led1_o]
set_property IOSTANDARD LVCMOS18 [get_ports led1_o]

set_property PACKAGE_PIN AC22 [get_ports prbs_to_cat5_p_o]
set_property IOSTANDARD LVDS_25 [get_ports prbs_to_cat5_p_o]

set_property PACKAGE_PIN AD21 [get_ports clk_to_cat5_p_o]
set_property IOSTANDARD LVDS_25 [get_ports clk_to_cat5_p_o]

#set_property PACKAGE_PIN AA15 [get_ports prbs_to_cat5_p_o]
#set_property IOSTANDARD LVDS [get_ports prbs_to_cat5_p_o]

#set_property IOSTANDARD LVCMOS18  [get_ports coax1_o]
#set_property PACKAGE_PIN AD16 [get_ports coax1_o]
#set_property IOSTANDARD LVCMOS18  [get_ports coax_o]
#set_property PACKAGE_PIN AD17 [get_ports coax_o]


create_clock -period 8.000 -name clk_base_xc7k_i [get_ports clk_i]
