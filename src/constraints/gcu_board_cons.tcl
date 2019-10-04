# PART is xc7k325tffg900-2
set_property PACKAGE_PIN Y18 [get_ports led_o]
set_property IOSTANDARD LVCMOS18 [get_ports led_o]
#set_property PACKAGE_PIN AB17 [get_ports xc7k_led1_o]
#set_property IOSTANDARD LVCMOS18 [get_ports xc7k_led1_o]

#set_property IOSTANDARD LVCMOS25  [get_ports xc7k_coax_n_o]
#set_property PACKAGE_PIN D18 [get_ports xc7k_coax_n_o]
set_property IOSTANDARD LVCMOS18 [get_ports cdrclk_o]
set_property PACKAGE_PIN AD17 [get_ports cdrclk_o]

set_property PACKAGE_PIN AD23 [get_ports sysclk_i]
set_property IOSTANDARD LVCMOS25 [get_ports sysclk_i]

############################################################
# TX Clock period Constraints                              #
############################################################
create_clock -period 8.000 -name sysclk [get_ports sysclk_i]


