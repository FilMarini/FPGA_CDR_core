ip_cores:
	$(MAKE) -C src/ip_cores

all_kc705: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream_kc705.tcl

all_gcu: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream_gcu.tcl

clean:
	rm -rf results vivado*.jou vivado*.log usage*

ip_cores_clean: clean
	$(MAKE) -C src/ip_cores clean
