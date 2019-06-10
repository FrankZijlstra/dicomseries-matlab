function [info] = readDicomSeriesInfo (directory, partitions, matchStruct, index)
% readDicomSeriesInfo reads the dicominfo from a dicom series partition
% that was found with the readDicomSeries function. See
% readDicomSeriesImage for more details on the parameters to this function.
%
% The info return value is either a dicominfo structure in case of an
% enhanced dicom file, or a cell array containing dicominfo structures in
% case of a series of classic dicom files.


if nargin<3 || isempty(matchStruct)
    matchStruct = struct();
end

if nargin<4 || isempty(index)
    index = 1;
end

if (nargin < 3)
    partition = partitions;
else
    partition = findMatchingPartitions(partitions, matchStruct);
    
    if isempty(partition)
        error('No matching partitions found');
    end
    
    if (index > length(partition))
        error('Partition index is larger than number of matched partitions');
    end
    
    partition = partition(index);
end


if (isfield(partition, 'frames'))
    % Enhanced DICOM
    info = dicominfo(fullfile(directory, partition.filenames{1}));
    
    % Remove dicominfo from frames that are not in this partition
    info = filterDicomFrames(info, partition.frames);
else
    % Classic DICOM
    for I=1:length(partition.filenames)
        dcminfo = dicominfo(fullfile(directory, partition.filenames{I}));
        info{I} = dcminfo;
    end
end

end
