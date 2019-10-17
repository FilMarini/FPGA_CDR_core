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

#write checkpoint
write_checkpoint -force $outputDir/post_synth.dcp



