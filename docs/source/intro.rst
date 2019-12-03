============
Introduction
============

The DDS based CDR is a project to implement a fully digital CDR in FPGA. This would be useful when data must be recovered on-board with no synch clock (Eg. JUNO).
The project is expected to work with a data frequency of 125 Mbps, extracting a clock of 62.5 MHz for sampling.

The very basic idea is to create a clock signal using a Direct Digital Synthesis (DDS) based Numerical Controlled Oscillator (NCO). DDS are often used to create arbitrary waveform out a reference clock. The aim is not to create an arbitrary waveform (frequency and form), but a clock signal (digital 1 and 0) of an arbitrary frequency, relying on the same technique.

After this arbitrary clock is created, it must be confronted with the digital data entering the FPGA (for now the digital data is another clock) in order to match its frequency. This will be obtained by a digital Phase Detector (PD), in order to re-create in FPGA a Phase-Locked Loop (PLL). The PD will dynamically detect the phase shifting of data vs. clock, and will tell the NCO to increase or decrease the frequency accordingly.

Since it's impossible (or maybe just not trivial) for an FPGA to detect phase shifting with an infinite resolution (like an analog phase detector), a finite resolution on the phase shifting must be taken into account. This means that, even though is possible for the NCO to match very closely the data frequency, the clock will always "walk", up to the phase shifting resolution, before getting re-adjusted (and walking on the other direction, keeping going back and forth).

Unfortunately, the phase detector implemented is strongly non-linear since

* its operation consists on the generation of fixed length pulses every time the counter meets the threshold
* it does not collect any data about the phase-difference amount or the time between phase-shifts
