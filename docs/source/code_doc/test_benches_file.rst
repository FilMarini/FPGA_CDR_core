************
Test Benches
************

Included in the "src" folder, several test benches are available to test different modules of the project. The test files are distinguishable from the syntesizable files as they are contained in folders ending with the "_tb" suffix.

The test are ment to be run with GHDL software (Tested with GHDL 0.37-dev, llvm version).

| In order to generate the test bench executionable file, run the "Makefile" with the "make" command.
| Remember to dump the wave file, as there is no automatic test or assertion.

For the GHDL user guide on how to run a test bench, dump the wave file and define its time lenght, refer to [1]_.

.. [1] https://ghdl.readthedocs.io/en/latest/ 
