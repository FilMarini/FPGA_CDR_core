#Define target part and create output directory
set partNum xc7k325tffg900-2
set outputDir ./results
set topentityname top_cdr_fpga
set bitstreamname firmware.bit
set probefilename firmware.ltx
set flash_bitstreamname firmware.mcs
file mkdir $outputDir

#read hdl files
read_vhdl -library usrDefLib [glob src/hdl/*.vhd]
read_vhdl -library usrDefLib [glob src/hdl/nco/*.vhd]
read_vhdl -library usrDefLib [glob src/hdl/pfd/*.vhd]
read_vhdl -library usrDefLib [glob src/hdl/pd/*.vhd]
read_vhdl -library usrDefLib [glob src/hdl/pfd/frequency_detector_unit/*.vhd]
read_vhdl -library usrDefLib [glob src/hdl/pfd/phase_detector_unit/*.vhd]

read_vhdl -library extras src/hdl/extras/synchronizing.vhdl

#include pre-synthesized ip_cores
set_part $partNum

read_checkpoint src/ip_cores/vio_0/vio_0.dcp
#Run Synthesis
synth_design -top $topentityname -part $partNum

#add ILA
#create_debug_core u_ila_0 ila
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list i_clock_generator_cdr/clk_out1 ]]
#set_property port_width 8 [get_debug_ports u_ila_0/probe0]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list {DMTD_1/sgn_counter[0]} {DMTD_1/sgn_counter[1]} {DMTD_1/sgn_counter[2]} {DMTD_1/sgn_counter[3]} {DMTD_1/sgn_counter[4]} {DMTD_1/sgn_counter[5]} {DMTD_1/sgn_counter[6]} {DMTD_1/sgn_counter[7]} ]]

#write checkpoint
write_checkpoint -force $outputDir/post_synth.dcp

#report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
#report_utilization -file $outputDir/post_synth_util.rpt

#read constraints file
source src/constraints/kc705_board_cons.tcl

#run optimization
opt_design
#run place
place_design
#report_clock_utilization -file $outputDir/clock_util.rpt

#get timing violations and run optimizations if needed
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
 puts "Found setup timing violations => running physical optimization"
 phys_opt_design
}
write_checkpoint -force $outputDir/post_place.dcp
#report_utilization -file $outputDir/post_place_util.rpt
#report_timing_summary -file $outputDir/post_place_timing_summary.rpt

#Route design and generate bitstream
route_design -directive Explore
write_checkpoint -force $outputDir/post_route.dcp
#report_route_status -file $outputDir/post_route_status.rpt
#report_timing_summary -file $outputDir/post_route_timing_summary.rpt
#report_power -file $outputDir/post_route_power.rpt
#report_drc -file $outputDir/post_imp_drc.rpt
#write_verilog -force $outputDir/cpu_impl_netlist.v -mode timesim -sdf_anno true
# set the MAC address for the current bitstream
# genderate a smaller bitstream
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force $outputDir/$bitstreamname
# Write Flash configuration file
#write_cfgmem -format mcs -size 128 -interface SPIx1 -loadbit {up 0x00000000 $outputDir/$bitstreamname} -file $outputDir/$flash_bitstreamnam
write_debug_probes -force $outputDir/$probefilename


