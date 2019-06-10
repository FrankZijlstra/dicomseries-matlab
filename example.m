clear all
close all

addpath('./dicomseries');
dirName = './testdata';
options = struct('recursive', true, 'verbose', true, 'loadCache', false);

dicomdict('set', 'dicom-dict-philips.txt');

[partitions, meta] = readDicomSeries(dirName, options);

% Read image by partition index
[image, info] = readDicomSeriesImage(dirName, partitions(1));
image = rescaleDicomImage(image, info);

figure
imagesc(image(:,:,1))

% Read image by matching a specific partition
% Note: StackID is not commonly used, you usually want to match on
% description and ImageType.
seriesDescription = 'm Survey';
[image, info] = readDicomSeriesImage(dirName, partitions, struct('SeriesDescription', seriesDescription, 'StackID', '3'));
image = rescaleDicomImage(image, info);

figure
imagesc(image)

% List matching partitions
parts = findMatchingPartitions(partitions, struct('SeriesDescription', seriesDescription));
for I=1:length(parts)
    fprintf('ImageType: %s, Stack ID %s\n', parts(I).partitionStruct.ImageType, parts(I).partitionStruct.StackID);
end
