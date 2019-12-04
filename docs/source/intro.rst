========
Abstract
========

| The capability to extract timing informations out of a serial data stream in order to decode all the incoming informations has become a very common requirement. It allows the communication channel to avoid transmitting any clock signal along, increasing the connection efficiency.
| To sample the incoming data, the receiver usually relies on a Clock and Data Recovery (CDR) chip, which generates a clock signal at the corresponding sampling frequency, phase-aligned to the data.

Modern physics experiment have often the same requirement, where perhaps thousands of boards receive uncorrelated data and it's up to them to decode the messages and make new physics discoveries possible. The presence of a CDR on-board is, therefore, usually mandatory.

| Unfortunately it is not so straightforward, especially in physics. First of all, the experiments data rates do not always (rarely) match the rates of commercial mass products, and if we also add the fact that the number of chips needed is relatively small, scouting the market for the supply of suitable components can be tedious.
| Secondly, physics experiments have to always face budget constraints, so electronic's boards only presents chips that are absolutely necessary and getting rid of some of them can sometimes be very convenient.

The computing capability of modern digital systems (experiments are included) often relies on Field Programmable Gate Arrays (FPGA). The proposed paper describes a way to implement a fully digital CDR in FPGA, which can sustain data rates (at least) up to 125 Mbps, which corresponds to a clock frequency of 62.5 MHz.

| The design is based on two components: a Numerically-Controlled Oscillator (NCO), in order to create a controlled frequency clock signal, and a digital Phase Detector (PD) to match the clock frequency with the data rate.
| NCOs are often coupled with a Digital to Analog Converter (DAC) to create Direct Digital Synthesizers (DDS), which are able to produce analog waveforms (e.g. sine waves) by generating a digital time-varying signal to input the DAC. In the presented case, the NCO is not used to create an arbitrary waveform (frequency and form), but a digital clock signal of an arbitrary frequence.
| The PD is needed to manage the NCO output frequency by intercepting any shifting on the relative phase between the clock and the data.

The paper will present the implemented CDR design, the limitations and the (many) challenges involved, possible fields of application in actual physics experiments and, finally, some results.
