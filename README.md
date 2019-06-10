# Matlab dicomseries reader
## 1. Introduction
This small MATLAB toolbox provides the functionality of reading one or more DICOM series from a directory containing many DICOM files. The DICOM files are automatically matched together into partitions (each usually a 2D or 3D volume). Using these partitions the DICOM series can be conveniently read into MATLAB. The code handles both classic and enhanced DICOM files and provides utilities for reading them and accessing DICOM tags in a consistent manner.

**Important note**: We know from experience that there is a lot of variation in DICOM files and the code may not deal with all DICOM files properly. We heavily rely on this code in our research and will improve the code as necessary to deal with new data. If you find bugs or errors with your DICOM files, you can help improve this toolbox by looking for a fix, or by letting me know!

**Important note 2**: This code is meant solely for research purposes. Please do NOT rely on it for any clinical implementations! I do not accept any responsibility for damage caused by the use of this software.

## 2. Usage
Analyze your DICOM directory using:
`partitions = readDicomSeries(directory, options)`
The partitions structure contains all information on the DICOM series present in your directory, and what is necessary to read them in properly. The `options` structure provides some additional control over the reading and partitioning (see `readDicomSeries.m` for more details). By default `readDicomSeries` will cache its results by saving a `partitions.mat` file in `directory`. This ensures that the next time you access the DICOM series it does not need to reprocess all files.

DICOM images can then be read by manually selecting a partition:
`[image, info] = readDicomSeriesImage(directory, partitions(1))`
Or by matching a partition based on DICOM tags:
`[image, info] = readDicomSeriesImage(directory, partitions, struct('SeriesDescription', 'test'))`
Note that matching can only be done on DICOM tags that were used during partitioning (see `readDicomSeries.m` for a full list of default DICOM tags).

[example.m] contains an example of usage of this toolbox.

Other utility functions:
* `findMatchingPartitions`: Search for partitions matching given DICOM tags (identical to how `readDicomSeriesImage` matches).
* `getDicomAttribute`: Access DICOM attributes in both classic and enhanced DICOM info structures.
* `isEnhancedDicomInfo`: Check whether a DICOM info structure is from an enhanced DICOM file.
* `rescaleDicomImage`: Rescale a DICOM image according to its rescale slope and intercept values (should work on both classic and enhanced DICOM, even when rescale values are different per slice).

## 3. Known issues (or: how can you help!)
* This code has been tested mostly on Philips MR DICOM files. Compatibility of this code with other vendors is a big unknown (do they even use enhanced DICOM files?). If you use this code and run into issues, let me know!
* The cache saved by `readDicomSeries` is used even if the processing options are different (e.g. different DICOM tags used in partitioning). You need to turn off cache loading, or manually remove the `partitions.mat` file in order for it to be overwritten when new processing options are used.
* `readDicomSeries` sorts frames by ImagePositionPatient, but this is not tested well and might fail. Sorting according to other DICOM tags is completely untested.

## 4. Author
Frank Zijlstra, 2019
