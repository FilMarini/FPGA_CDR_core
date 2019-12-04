ip_cores:
	$(MAKE) -C src/ip_cores

all: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream.tcl

clean:
	rm -rf results vivado*.jou vivado*.log usage* .Xil .cache

ip_cores_clean: clean
	$(MAKE) -C src/ip_cores clean

dummy_hw:
	$(MAKE) -C dummy_data_sender all

dummy_hw_clean:
	$(MAKE) -C dummy_data_sender clean

