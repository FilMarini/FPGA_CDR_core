===========
Conclusions
===========

The presented document briefly prensents the still-under-development design for an FPGA implementation of a fully figital CDR.

The design is intended to work with a data rate of 125 Mbps. At such data rate, a possible implementation would be on the Global Control Unit (GCU) board of the JUNO experiment.

| JUNO is a neutrino physics experiment, under development, where a big liquid scintillator detector will be read by about 20'000 large PMTs. Very close to the PMTs, underwater, the analogue signals are digitized, analyzed and stored in the GCU boards.
| Each GCU looks at three PMTs, and elaborating their data, a primitive trigger is generated. The trigger is then sent to the higher lever electronics, via a synchronous link, for a global trigger validation. The same link is used to send back the validation, in form of a timestamp. When received, the GCU sends the related waveform to the DAQ via Ethernet.

A CDR is needed to decode the synchronous link messages, which presents a data rate of 125 Mbps. This would be beneficial in terms of cost reduction. 
