===============================
Numerical Controlled Oscillator
===============================

To generate a waveform, the design of a NCO [1]_ consists of two parts:

* A phase accumulator (PA), which is basically a counter incremented by a reference clock
* A phase-to-amplitude converter, which associates a waveform Look-Up Table (LUT) to every possible PA output value, using it as an index.

| To better understand the mechanism, we can think of a phase-wheel (:numref:`phase_wheel`). This phase-wheel is equally divided in a certain number of sections, bounded by phase-points and for each phase-point we associate the correspondant sine value.
| As a vector rotates around the wheel, by taking these sine values, a digital sine waveform is generated. A complete revolution around the phase-circle corresponds to a complete period of the sine wave.

Let's imagine now that the vector skips a few (fixed) points for each jump, the revolution is completed in a much shorter time: the frequency of the output waveform has increased!

.. _phase_wheel:
.. figure:: nco/phase_wheel.png
   :scale: 100%

   The phase wheel

The correlation between the jump size, the reference clock and the output waveform frequency is

:math:`f_{OUT} = \frac{M \times f_C}{2^n}`

where:

* :math:`M` is the jump size
* :math:`f_{OUT}` is the NCO output waveform frequency
* :math:`f_C` in the reference clock frequency
* :math:`n` is the length of the phase accumulator, in bits

| For the actual implementation, the phase-point touched by the vector are defined by the PA: for each rising edge of the reference clock, the counter skips an arbitrary number of points, therefore obtaining the arbitrary frequency.
| The phase-to-amplitude converter is actually very simple: since we are only interested in creating a digital clock signal, we just associate to half of the circle the digital value 0, and to the other half the digital value 1.

The design presents two main limitations:

* The first is the maximum frequency limit, which is given by Nyquist, and corresponds to half of the reference clock
* The second is the phase resolution. Since the output signal is digital, the time domain is discrete, and it corresponds to the reference clock period. This implies that the positive (and negative) fraction of the output clock signal can only be a multiple of this time domain resolution, making the output frequency only on average determined by the jump size of the accumulator. 

While the first limitation is known and impossible to overcome, the second is design based, and must be resolved in order to be able to use this clock for CDR operations.

Phase resolution increase 
=========================

| As said, the NCO output can change its value only when the phase accumulator jumps from one phase-point to another (i.e. at the rising edge of the reference clock).
| To improve the phase resolution, the parallelism capability of the FPGA is exploited.

| Briefly, to reduce the NCO phase changing period, the trivial way is to increase the reference clock frequency.
| To obtain the same result, without any frequency change, we can compute multiple points between one phase jump, and then serialize the results. This way, for each rising edge of the reference clock, multiple values of the output waveform are computed, increasing the resolution.

The NCO output clock will still present offset between the average frequency value and the istantaneous frequency value (the time domain is still descrete, we just reduced its period), but this can be filtered out feeding the signal to an FPGA's MMCM/PLL, in jitter filter mode. 

.. [1] https://www.analog.com/en/analog-dialogue/articles/all-about-direct-digital-synthesis.html
