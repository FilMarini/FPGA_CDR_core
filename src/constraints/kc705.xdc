# PART is xc7k325tffg900-2
set_property PACKAGE_PIN AB8 [get_ports led_o]
set_property IOSTANDARD LVCMOS15 [get_ports led_o]
set_property PACKAGE_PIN AA8 [get_ports led1_o]
set_property IOSTANDARD LVCMOS15 [get_ports led1_o]

#set_property IOSTANDARD LVCMOS25  [get_ports xc7k_coax_n_o]
#set_property PACKAGE_PIN Y24 [get_ports xc7k_coax_n_o]
set_property IOSTANDARD LVCMOS25 [get_ports cdrclk_o]
set_property PACKAGE_PIN AF26 [get_ports cdrclk_o]

set_property PACKAGE_PIN AD12 [get_ports sysclk_p_i]
set_property IOSTANDARD LVDS [get_ports sysclk_p_i]

############################################################
# TX Clock period Constraints                              #
############################################################
create_clock -period 5.000 -name sysclk [get_ports sysclk_p_i]


