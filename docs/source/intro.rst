============
Introduction
============

| The Clock and Data Recovery job is a relatively simple one: retrieve a clock with the frequency needed to sample each bit of the incoming data stream.
| Its design, unfortunately, is not so trivial.

Usually a CDR architecture is similar to the Phase Locked Loop (PLL) model (:numref:`pll_basic`), where the phase of a reference signal is compared to the phase of an adjustable feedback signal, generally provided by a Voltage Controlled Oscillator (VCO). The output of the Phase Detector (PD) is filtered and used to pilot the VCO frequency. When the phase comparison is in steady state, e.g. the phase and frequency of the reference signal is equal to the phase and frequency of the feeedback signal, we say that the PLL is locked. In the case of a CDR, the steady state is reached when the VCO clock frequency match the reference signal's data rate.

.. _pll_basic:
.. figure:: intro/pll.png
   :scale: 100%

   Basic design of a PLL.
   
Essentially, breaking down the design, for a fully functional CDR, a controlled oscillator and a PD are needed. Needless to say, these components are not natively available in an FPGA.

This paper has the intent to show a possible implementation of a CDR adopting the FPGA technology, in particular the target is a Xilinx Kintex 7 (XC7K325T--2FFG900C), which presents a good balance between performances and cost.

To generate an arbitrary frequency clock signal, a Numerically Controlled Oscillator (NCO) is designed. NCOs are digital signal generators which are able to provide discrete-time-and-values waveforms, with user-defined frequency. To control and compare the frequency of the NCO clock to the reference data stream, a few options are currently being evaluated, and will be presented in the dedicated section.
