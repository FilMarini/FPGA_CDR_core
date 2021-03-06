#Define target part and create output directory
set partNum xc7k325tffg900-2
set outputDir ./results
set topentityname top_level
set bitstreamname firmware.bit
set probefilename firmware.ltx
set flash_bitstreamname firmware.mcs
file mkdir $outputDir

#read hdl files
read_vhdl -library usrDefLib [glob src/hdl/*.vhd]

#include pre-synthesized ip_cores
set_part $partNum

#Run Synthesis
synth_design -top $topentityname -part $partNum

#write checkpoint
write_checkpoint -force $outputDir/post_synth.dcp

#report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
#report_utilization -file $outputDir/post_synth_util.rpt

#read constraints file
source src/constraints/board_cons.tcl

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

# genderate a smaller bitstream
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force $outputDir/$bitstreamname
# Write Flash configuration file
#write_cfgmem -format mcs -size 128 -interface SPIx1 -loadbit {up 0x00000000 $outputDir/$bitstreamname} -file $outputDir/$flash_bitstreamnam
write_debug_probes -force $outputDir/$probefilename


