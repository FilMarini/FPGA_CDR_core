ip_cores:
	$(MAKE) -C src/ip_cores

all: ip_cores
	vivado -nolog -nojournal -mode batch -source create_bitstream.tcl

clean:
	rm -rf results vivado*.jou vivado*.log usage*

ip_cores_clean: clean
	$(MAKE) -C src/ip_cores clean
