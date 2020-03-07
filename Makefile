all: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream.tcl

ip_cores:
	$(MAKE) -C src/ip_cores

clean: clean_vivado
	rm -rf results .Xil .cache

ip_cores_clean: clean
	$(MAKE) -C src/ip_cores clean

dummy_hw:
	$(MAKE) -C dummy_data_sender all

dummy_hw_clean:
	$(MAKE) -C dummy_data_sender clean

clean_vivado:
	rm vivado* usage_statistics* webtalk*
