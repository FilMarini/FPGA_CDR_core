set_property PACKAGE_PIN AD23 [get_ports clk_i]
set_property IOSTANDARD LVCMOS25 [get_ports clk_i]
set_property PACKAGE_PIN Y18 [get_ports led_o]
set_property IOSTANDARD LVCMOS18 [get_ports led_o]
set_property PACKAGE_PIN AB17 [get_ports led1_o]
set_property IOSTANDARD LVCMOS18 [get_ports led1_o]

set_property IOSTANDARD LVCMOS18  [get_ports clk1_o]
set_property PACKAGE_PIN AD16 [get_ports clk1_o]
set_property IOSTANDARD LVCMOS18  [get_ports clk_o]
set_property PACKAGE_PIN AD17 [get_ports clk_o]


create_clock -period 8.000 -name clk_base_xc7k_i [get_ports clk_i]
