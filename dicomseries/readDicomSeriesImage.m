function [image, info] = readDicomSeriesImage (directory, partitions, matchStruct, index)
% readDicomSeriesImage reads a dicom image (and optional dicominfo) from a
% dicom series partition that was found with the readDicomSeries function.
%
% This function can be used in two ways:
% [image, info] = readDicomSeriesImage(directory, partition):
% Reads a partition specified by the caller. partition should be one
% element of the imagePartitions structure returned by readDicomSeries.
% directory should be the same directory that was provided to
% readDicomSeries.
%
% [image, info] = readDicomSeriesImage(directory, partitions, matchStruct, index):
% Reads a partition that matches the dicom tags specified in matchStruct.
% partitions is the imagePartitions structure returned by readDicomSeries.
% matchStruct should be a structure where each element is a dicom tag that
% should match the information in partitions(x).partitionStruct (this is
% both type-sensitive and case-sensitive!). In case of multiple matches,
% the index parameter can specify which result to use (default: 1).
%
% The image return value will contain only the frames specified in the
% partition, typically in a 3D matrix. The type is the same as returned
% from dicomread (usually int16).
%
% The info return value is either a dicominfo structure in case of an
% enhanced dicom file, or a cell array containing dicominfo structures in
% case of a series of classic dicom files.


needInfo = (nargout == 2);

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



if (isfield(partition, 'frames') && ~isempty(partition.frames))
    % Enhanced DICOM
    image = dicomread(fullfile(directory, partition.filenames{1}), 'Frames', partition.frames);
    
    % Hack to deal with 3D data stored as size [x,y,1,z]
    image = squeeze(image);
    
    if needInfo
        info = dicominfo(fullfile(directory, partition.filenames{1}));
        
        % Remove dicominfo from frames that are not in this partition
        info = filterDicomFrames(info, partition.frames);
    end
else
    % Classic DICOM
    info = {};
    
    for I=1:length(partition.filenames)
        img = dicomread(fullfile(directory, partition.filenames{I}));
        if needInfo
            info{I} = dicominfo(fullfile(directory, partition.filenames{I}));
        end
        
        if (I == 1)
            sz = size(img);

            % Pre-allocate size for 3D/4D volume
            if (numel(sz) == 2)
                image = zeros(sz(1), sz(2), length(partition.filenames), class(img));
            elseif (numel(sz) == 3)
                image = zeros(sz(1), sz(2), sz(3), length(partition.filenames), class(img));
            else
                error('>4D images not implemented');
            end
        end

        if (numel(sz) == 2)
            image(:,:,I) = img;
        elseif (numel(sz) == 3)
            image(:,:,:,I) = img;
        end
    end
end

end
