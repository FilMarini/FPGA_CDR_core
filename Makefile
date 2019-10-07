ip_cores:
	$(MAKE) -C common_src/ip_cores

all_gcu: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream_gcu.tcl

all_kc705: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream_kc705.tcl

clean:
	rm -rf results vivado*.jou vivado*.log usage* .Xil .cache

ip_cores_clean: clean
	$(MAKE) -C common_src/ip_cores clean
