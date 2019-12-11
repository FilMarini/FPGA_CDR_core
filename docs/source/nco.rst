===============================
Numerical Controlled Oscillator
===============================

To know more about NCOs (in DDS designs), go to this link_.

.. _link: https://www.analog.com/en/analog-dialogue/articles/all-about-direct-digital-synthesis.html

To generate a waveform, the design of a NCO consists of two parts:

* A phase accumulator (PA), which is basically a counter incremented by a reference clock
* A phase-to-amplitude converter, which associates a waveform Look-Up Table (LUT) to every possible PA output value, using it as an index.

| To better understand the mechanism, we can think of a phase-circle. This phase-circle is equally divided in a certain number of sections, bounded by phase-points and for each phase-point we associate the correspondant sine value.
| As a vector rotates around the wheel, by taking these sine values, a digital sine waveform is generated. A complete revolution around the phase-circle corresponds to a complete period of the sine wave.

Let's imagine now that the vector skips a few (fixed) points for each jump, the revolution is completed in a much shorter time: the frequency of the output waveform has increased!


| For the actual implementation, the phase-point touched by the vector are defined by the PA: for each rising edge of the reference clock, the counter skips an arbitrary number of points, therefore obtaining the arbitrary frequency.
| The phase-to-amplitude converter is actually very simple: since we are only interested in creating a digital clock signal, we just associate to half of the circle the digital value 0, and to the other half the digital value 1.

The design presents two main limitations:

* The first is the maximum frequency limit, which is given by Nyquist, and corresponds to half of the reference clock
* The second is the phase resolution. Since the output signal is digital, the time domain is discrete, and it corresponds to the reference clock period. This implies that the positive (and negative) fraction of the output clock signal can only be a multiple of this time domain resolution, making the output frequency only on average determined by the jump size of the accumulator. 

While the first limitation is known and impossible to overcome, the second is design based, and must be resolved in order to be able to use this clock for CDR operations.
