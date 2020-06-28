all: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream.tcl

prbs_check: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream_w_debug.tcl

ip_cores:
	$(MAKE) -C src/ip_cores

clean:
	rm -rf results .Xil .cache vivado* usage_statistics* webtalk*

ip_cores_clean:
	$(MAKE) -C src/ip_cores clean

dummy_hw:
	$(MAKE) -C dummy_data_sender all

dummy_hw_clean:
	$(MAKE) -C dummy_data_sender clean

