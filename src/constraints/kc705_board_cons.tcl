# PART is xc7k325tffg900-2
set_property PACKAGE_PIN AB8 [get_ports led_o]
set_property IOSTANDARD LVCMOS15 [get_ports led_o]

set_property PACKAGE_PIN AA8 [get_ports led1_o]
set_property IOSTANDARD LVCMOS15 [get_ports led1_o]

#set_property IOSTANDARD LVCMOS25 [get_ports cdrclk_o]
#set_property PACKAGE_PIN AB29 [get_ports cdrclk_o]
#set_property IOSTANDARD LVDS_25 [get_ports cdrclk_p_o]
#set_property PACKAGE_PIN AG27 [get_ports cdrclk_p_o]
set_property IOSTANDARD LVDS_25 [get_ports cdrclk_p_o]
set_property PACKAGE_PIN Y23 [get_ports cdrclk_p_o]
#set_property IOSTANDARD LVCMOS25 [get_ports cdrclk_o]
#set_property PACKAGE_PIN Y23 [get_ports cdrclk_o]

#set_property IOSTANDARD LVCMOS25 [get_ports cdrclk_i]
#set_property PACKAGE_PIN AD27 [get_ports cdrclk_i]
#set_property IOSTANDARD LVDS_25 [get_ports cdrclk_p_i]
#set_property PACKAGE_PIN AD27 [get_ports cdrclk_p_i]
set_property IOSTANDARD LVDS_25 [get_ports cdrclk_p_i]
set_property PACKAGE_PIN L25 [get_ports cdrclk_p_i]

set_property IOSTANDARD LVCMOS25 [get_ports cdrclk_jc_o]
set_property PACKAGE_PIN AB29 [get_ports cdrclk_jc_o]

set_property PACKAGE_PIN AD12 [get_ports sysclk_p_i]
set_property IOSTANDARD LVDS [get_ports sysclk_p_i]

############################################################
# TX Clock period Constraints                              #
############################################################
create_clock -period 5.000 -name sysclk [get_ports sysclk_p_i]


