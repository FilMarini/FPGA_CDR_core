========
Abstract
========

| The capability to extract timing informations out of a serial data stream to decode the incoming informations has become a very common requirement.
| To sample the incoming data, the receiver usually relies on a Clock and Data Recovery (CDR) chip, which generates a clock signal at the corresponding sampling frequency, phase-aligned to the data.

Modern physics experiment have often this same requirement, where perhaps thousands of boards receive uncorrelated data and it's up to them to decode the messages. For that reason, the presence of a CDR on-board is usually mandatory.

Present readout systems in physics experiments usually rely on FPGAs to receive and transmit data at high rate to high capaicity DAQ systems; exploting FPGAs to recover timing information from streamed data is therefore beneficial for a number of reasons, including power consumption and cost reduction.

| The design is based on two components: a Numerically-Controlled Oscillator (NCO), in order to create a controlled frequency clock signal, and a digital Phase Detector (PD) to match the clock frequency with the data rate.
| NCOs are often coupled with a Digital to Analog Converter (DAC) to create Direct Digital Synthesizers (DDS), which are able to produce analog waveforms of any desired frequency. In the presented case, the NCO generates a digital clock signal of an arbitrary frequence, while the PD manages this frequency by intercepting any shifting on the relative phase between the clock and the data. 

The paper presents the implemented CDR design, the limitations and the challenges involved, possible fields of application in actual physics experiments and, finally, some results.
