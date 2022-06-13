# Fiji macro: compare signal in nucleus and cytoplasm

This Fiji/ImageJ macro is intended to be used to measure the flurescent signal in the nucleus and the cytoplasm and allow a quantitative comparison.

The input images have 3 channels.

1. The signal of interest
2. a global marker that describes the cell shape
3. DAPI for nucleus segmentation

The macro extracts the background signal and the fluorecent signal in channel on in the whole cell, the nucleus and the cytoplasm.

It also extracts each individual cell so it is possible to check each cell in case some of the results are inconsistent in order to exclude results manually.
