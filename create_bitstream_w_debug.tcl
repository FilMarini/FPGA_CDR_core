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
read_vhdl -library usrDefLib [glob src/hdl/phase_detector/*.vhd]

#include pre-synthesized ip_cores
set_part $partNum

read_checkpoint src/ip_cores/vio_0/vio_0.dcp
#Run Synthesis
synth_design -top $topentityname -part $partNum

#add ILA
create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_clock_generator_cdr/clk_out0 ]]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[0]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[1]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[2]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[3]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[4]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[5]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[6]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[7]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[8]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[9]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[10]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[11]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[12]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[13]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[14]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle[15]} ]]
create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_DMTD/i_locker_monitoring_1/s_state[0]} {i_DMTD/i_locker_monitoring_1/s_state[1]} {i_DMTD/i_locker_monitoring_1/s_state[2]} ]]
create_debug_port u_ila_0 probe
set_property port_width 16 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[0]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[1]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[2]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[3]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[4]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[5]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[6]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[7]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[8]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[9]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[10]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[11]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[12]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[13]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[14]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_diff[15]} ]]
create_debug_port u_ila_0 probe
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[0]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[1]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[2]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[3]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[4]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[5]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[6]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[7]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[8]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[9]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[10]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[11]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[12]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[13]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[14]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_fixed[15]} ]]
create_debug_port u_ila_0 probe
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[0]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[1]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[2]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[3]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[4]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[5]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[6]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[7]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[8]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[9]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[10]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[11]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[12]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[13]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[14]} {i_DMTD/i_locker_monitoring_1/sgn_n_cycle_opt[15]} ]]
create_debug_port u_ila_0 probe
set_property port_width 16 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[0]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[1]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[2]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[3]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[4]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[5]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[6]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[7]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[8]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[9]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[10]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[11]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[12]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[13]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[14]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift[15]} ]]
create_debug_port u_ila_0 probe
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[0]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[1]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[2]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[3]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[4]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[5]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[6]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[7]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[8]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[9]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[10]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[11]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[12]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[13]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[14]} {i_DMTD/i_locker_monitoring_1/sgn_phase_shift_counter[15]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list i_DMTD/i_locker_monitoring_1/s_change_freq_en ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list i_DMTD/i_locker_monitoring_1/s_incr_freq ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list i_DMTD/i_locker_monitoring_1/s_n_cycle_ready ]]

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


