************************************
Phase and Frequency Detector Manager
************************************

Instance: *i_pfd_manager_1*, file: *pfd_manager.vhd*

The frequency manager module's job is to make sure the NCO clock freuqency is as close as possible to the data rate. Since its impossible for the two to be an exact match, due to the finite resolution of the clock frequency and real-world conditions (i.e., jitter, setup/hold time violation ... ), the Frequency Manager exploits a counter filtering method (similar to the *phase_shift_filter* module) with several different threshold to get to the closest wanted frequency. Also, when this condition is met, the *locked_o* flag is asserted high and will be deasserted if the input data stops or the data rate mismatches the NCO clock frequency.

.. _pfd_manager:
.. figure:: frequency_detector_manager/pfd_manager_ink.png
   :width: 100%
   :align: center

   Block diagram for the pfd_manager module

As said, the counter mechanism (+1 when frequency increase request, -1 when frequency decrease request) employs different threshold in order to detect whether the CDR is locked:

* *lock threshold* (around 10% of the maximum possible value): if counter ends up inside this range, the CDR is locked
* *activate threshold* (around 50%) when CDR is locked, outside this range a frequency change request is forwarded to te NCO
* *unlock threshold* (around 90%) if exceeded, the CDR locked is deasserted

A Set/Reset Flip-Flop manages the lock and unlock flags.

Together with the M-change requests, a control signal is sent out, to comply with the CDC that will happen when passing this signal to the NCO.

.. _waves_2:
.. figure:: frequency_detector_manager/wavedrom_2.png
   :width: 60%
   :align: center

   Timing diagram for the M-change request to be passed to the NCO

Lock Manager
############

Instance: *i_lock_manager_1*, file: *lock_manager.vhd*

The *lock_manager* module monitors the *locked_o* signal from the Frequency Manager to decide whether the CDR is locked to the data or not.

.. _lock_manager:
.. figure:: lock_manager/lock_manager_ink.png
   :width: 100%
   :align: center

   Block diagram for the lock manager module

Basically, if the *locked_o* stays up for a certain number of periods, than the CDR is locked. On the other hand, if *locked_o* stays low for the same certain number of period, than the CDR is not locked.

**Watch out for aliases!!**
