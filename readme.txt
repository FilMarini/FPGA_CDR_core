Team number: xohw20_203
Project name: NCO based CDR implementation in FPGA
Date: June 28th 2020
Version of uploaded archive: 1

University name: Universita' degli Studi di Padova
Supervisor Name: Dr. Ing. Marco Bellato
Supervisor email: marco.bellato@pd.infn.it
Partecipant: Filippo Marini
Email: filippo.marini@pd.infn.it

Board Used: Xilinx KC705
Software version: Vivado 2018.3
Brief description of the project: FPGA implementation of a CDR targeting a Xilinx Kintex-7 for data rates up to 250 MHz
Link to project repository: https://github.com/FilMarini/FPGA_CDR_core

Description of the archive:
Files:
* Makefile: run the * 'make all' command to generate the bitstream for the example design * 'make prbs_check' to generate the example design bitstream along with the proble file in order to check the PRBS errors via ILA * 'make dummy_hw_sender' to generate the bitstream for the 'PRBS generator board' * 'make dummy_hw_receiver' to generate the bitstream for the 'Buffer board'
* create_bistream.tcl: Vivado tcl script to generate the bistream
* create_bitstream_w_debug.tcl: Vivado tcl script to generate the bistream for the PRSB error checking with ILA

Folders:
* src: all the sources for the CDR core project. This includes the VHDL source files, the constraint file and the ip cores (VIO) together with the ip cores generation scripts
* docs: Documentation regarding the project and the VHDL files. Currently the documentation includes the submitted documents for the IEEE Real Time conference 2020 and documentation for an easier understanding of the project source files. These docs are available to read at fpga-cdr-core.readthedocs.io 
* report: Xilinx Open Hardware 2020 report source files
* dummy_data_sender: additional FPGA configuration source files, made for a custom board, for the PRBS-7 data stream generation (see the 'CDR Testing' dedicated section in the report)
* dummy_data_receiver: additional FPGA configuration source files, made for a custom board, for the PRBS-7 data stream recovery from CAT5 cable and forward to both the oscilloscope and CDR core board
* results: Only after the bitstream generation script has run, this folder contains the FPGA configuration files for the CDR core example design.

Instructions to build and test project:
Step 1:
Build the CDR core example design running the 'make all' command (or 'make prbs_check' if you wish to check the PRBS error counter via ILA).
The example design needs a 250 Mbps input data stream. To provide that, follow 'Step 2' and 'Step 3' having two extra boards available.
The target board is a Xilinx KC705 evaluation board. If using a different board, the constraints file needs to be adjusted accordingly (src/constraints/kc705_board_cons.tcl).

Step 2:
Build the configuration file for the 'PRBS Generator board' running the 'make dummy_hw_sender' command. In the example design testing setup, this board sends the PRBS-7 250Mbps data to the CAT5 cable.
Important: Keep in mind that, during testing, a custom board was used. The user will probably want to adjust the constraint file (dummy_data_sender/src/constraints/board_cons.tcl) according their board of choice

Step 3:
Build the configuration file for the 'Buffer board' running the 'make dummy_hw_receiver' command. In the example design testing setup, this board takes the data from the CAT5 cable and redirects it to two differential outputs, one for theoscilloscope and one for the CDR core.
Important: Keep in mind that, during testing, a custom board was used. The user will probably want to adjust the constraint file (dummy_data_receiver/src/constraints/board_cons.tcl) according their board of choice

Step 4:
Upload the configuration files to the boards. Check the report to understand what the LEDs of the KC705 means.

Link to youtube video: https://youtu.be/oK15voQDpzQ
