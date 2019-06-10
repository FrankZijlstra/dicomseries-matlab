function [imagePartitions, metaFilenames] = readDicomSeries (directory, options)
% Read all dicom image series from a directory. All dicom files are split
% into partitions that contain one image (i.e. a 2D/3D volume).
%
% Parameters:
%   directory: Directory to process dicom series from.
%   options: Options struct.
%
% Options struct fields:
%   partitionTags [default: {..long list..}]:
%     Cell array of dicom tags that need to be unique for a given partition
%   sortTags [default: {'ImagePositionPatient'}]:
%     Cell array of dicom tags that are used to sort slices within a
%     partition.
%   recursive [default: false]:
%     Whether subdirectories should be included in the search.
%   matchBaseDir [default: true]:
%     Whether dicom files need to be in the same directory to be matched
%     into a partition.
%   verbose [default: false]:
%     Enables console output of progress.
%   loadCache [default: true]:
%     Whether a cache file containing partition results should be loaded.
%   saveCache [default: true]:
%     Whether a cache file containing partition results should be saved
%     after processing is done.
%     The cache file is stored in <directory>/partitions.mat (you need to
%     have write access to the directory).
%
% Return values:
%   imagePartitions: Array of structs containing all partitions found
%   metaFilenames: Cell array of dicom filenames that contain no images
%
% imagePartitions struct fields:
%   filenames: Cell array containing all dicom filenames in this partition
%   partitionStruct: Structure containing all dicom tags listed in
%                    partitionTags
%   frames: For enhanced dicom: Frame numbers for this partition
%
% imagePartitions is an argument to the following functions:
%   findMatchingPartitions, readDicomSeriesImage, readDicomSeriesInfo
%

% Known issues:
% - Sorting doesn't work properly on string fields with varying length
% - Cache does not detect changes in options (will return results with
%   options that were used to generate the cached result).

if (nargin < 2 || ~isfield(options,'partitionTags') || isempty(options.partitionTags))
    options.partitionTags = {'SeriesDescription', 'SeriesDate', 'SeriesTime', 'PatientID', 'Modality', 'SeriesInstanceUID', 'ImageType', 'PixelSpacing', 'SpacingBetweenSlices', 'SliceThickness', 'ImagePlaneOrientation', 'StackID', 'SamplesPerPixel', 'Rows', 'Columns', 'NumberOfFrames', 'TemporalPositionIdentifier', 'BodyPartExamined', 'ScanningSequence', 'MRAcquisitionType', 'EchoTime', 'RepetitionTime', 'InversionTime', 'EchoTrainLength', 'ConvolutionKernel', 'FlipAngle', 'EchoNumber', 'EnergyWindowVector', 'PhaseVector', 'RRIntervalVector', 'RotationVector'};
end
if (nargin < 2 || ~isfield(options,'sortTags') || isempty(options.sortTags))
    options.sortTags = {'ImagePositionPatient'};
end
if (nargin < 2 || ~isfield(options,'recursive') || isempty(options.recursive))
    options.recursive = false;
end
if (nargin < 2 || ~isfield(options,'matchBaseDir') || isempty(options.matchBaseDir))
    options.matchBaseDir = true;
end
if (nargin < 2 || ~isfield(options,'verbose') || isempty(options.verbose))
    options.verbose = false;
end
if (nargin < 2 || ~isfield(options,'loadCache') || isempty(options.loadCache))
    options.loadCache = true;
end
if (nargin < 2 || ~isfield(options,'saveCache') || isempty(options.saveCache))
    options.saveCache = true;
end

directory = fullfile(directory); % Fixes filename separators


%% Load cache (if enabled)
cacheFilename = fullfile(directory, 'partitions.mat');

if (options.loadCache && exist(cacheFilename, 'file'))
    if (options.verbose)
        fprintf('Loading cached partitions from %s...\n', cacheFilename);
    end
    
    load(cacheFilename);
    return
end


%% Traverse directories and look for dicom files
if (options.verbose)
    fprintf('Reading directories...\n');
end

imageIndex = 1;
metaIndex = 1;
info = {};
metaFilenames = {};
filenames = {};

readDir('.');

%% Partition separation
if (options.verbose)
    fprintf('Partitioning dicoms...\n');
end

partitions = struct([]);
enhancedPartitions = struct([]);
P = 1;

% TODO: the matchBaseDir option can be implemented more efficiently by
% creating partitions while recursing through directories

for I=1:length(info)
    if (options.verbose)
        fprintf('  Processing file %d / %d [%d partitions]...\n', I, length(info), length(partitions) + length(enhancedPartitions));
    end

    if (isfield(info{I}, 'PerFrameFunctionalGroupsSequence'))
        % Enhanced dicom (many slices per file) (only matches partitions in the same file)
        enhancedPartition = struct([]);
        PE = 1;
        
        nFrames = length(fieldnames(info{I}.PerFrameFunctionalGroupsSequence));
        for J=1:nFrames
            if (options.verbose)
                fprintf('    Processing frame %d / %d [%d partitions]...\n', J, nFrames, length(enhancedPartition));
            end
            
            tags = struct();
            for K=1:length(options.partitionTags)
                tags.(options.partitionTags{K}) = getDicomAttribute(info{I}, options.partitionTags{K}, J);
            end

            ind = [];
            for K=1:length(enhancedPartition)
                if (isequal(enhancedPartition(K).tags, tags))
                    ind = K;
                    break
                end
            end

            if (isempty(ind))
                enhancedPartition(PE).tags = tags;
                enhancedPartition(PE).images = I;
                enhancedPartition(PE).frames = J;
                PE = PE + 1;
            else
                enhancedPartition(ind).frames = [enhancedPartition(ind).frames J];
            end

        end
        
        enhancedPartitions = [enhancedPartitions enhancedPartition];
    else
        % Classic dicom (one file per slice)
        tags = struct();
        for K=1:length(options.partitionTags)
            if (isfield(info{I}, options.partitionTags{K}))
                v = info{I}.(options.partitionTags{K});
            else
                v = [];
            end

            tags.(options.partitionTags{K}) = v;
        end

        baseDir = fileparts(filenames{I});

        ind = [];
        for J=1:length(partitions)
            if (options.matchBaseDir && ~isequal(partitions(J).baseDir, baseDir))
                continue;
            end
            if (isequal(partitions(J).tags, tags))
                ind = J;
                break
            end
        end

        if (isempty(ind))
            partitions(P).tags = tags;
            partitions(P).images = I;
            if (options.matchBaseDir)
                partitions(P).baseDir = baseDir;
            end
            P = P + 1;
        else
            partitions(ind).images = [partitions(ind).images I];
        end
    end

end

%% Partition sorting
if (options.verbose)
    fprintf('Sorting partitions...\n');
end

imagePartitions = struct([]);

for I=1:length(partitions)
    sortArray = zeros(length(partitions(I).images), length(options.sortTags));

    for J=1:length(partitions(I).images)
        cur = 1;
        for K=1:length(options.sortTags)
            if (isfield(info{partitions(I).images(J)}, options.sortTags{K}))
                tmp = info{partitions(I).images(J)}.(options.sortTags{K});
                sortArray(J,cur:cur+length(tmp)-1) = tmp;
                cur = cur + length(tmp);
            end
        end
    end
    
    [~,inds] = sortrows(-sortArray); % Sorting reversed...

    for J=1:length(inds)
        imagePartitions(I).filenames{J} = filenames{partitions(I).images(inds(J))};
    end

    imagePartitions(I).partitionStruct = partitions(I).tags;
end

for I=1:length(enhancedPartitions)
    sortArray = zeros(length(enhancedPartitions(I).frames), length(options.sortTags));
    
    for J=1:length(enhancedPartitions(I).frames)
        cur = 1;
        for K=1:length(options.sortTags)
            tmp = getDicomAttribute(info{enhancedPartitions(I).images(1)}, options.sortTags{K}, enhancedPartitions(I).frames(J));
            if (isempty(tmp))
                tmp = 0;
            end
            sortArray(J,cur:cur+length(tmp)-1) = tmp;
            cur = cur + length(tmp);
        end
    end

    [~,inds] = sortrows(-sortArray); % Sorting reversed...

    imagePartitions(length(partitions)+I).frames = enhancedPartitions(I).frames(inds);
    imagePartitions(length(partitions)+I).filenames{1} = filenames{enhancedPartitions(I).images(1)};
    imagePartitions(length(partitions)+I).partitionStruct = enhancedPartitions(I).tags;
end

%% Save cache
if (options.saveCache)
    if (options.verbose)
        fprintf('Saving partitions to cache: %s...\n', cacheFilename);
    end
    save(cacheFilename, 'imagePartitions', 'metaFilenames');
end



%% readDir function traverses a directory (with optional recursion) and finds dicom files
function readDir (dirName)

if (options.verbose)
    fprintf('Reading directory: %s\n', dirName);
end

fileList = dir(fullfile(directory, dirName));

for F=1:length(fileList)
    if (strcmp(fileList(F).name,'.') || strcmp(fileList(F).name,'..'))
        continue
    end
    
    filename = fullfile(directory, dirName, fileList(F).name);
    if (isdir(filename))
        if (options.recursive)
            readDir(fullfile(dirName, fileList(F).name));
        end
        continue;
    end

    if (~isdicom(filename))
        if (options.verbose)
        	fprintf('  Other file: %s\n', filename);
        end
        continue
    end

    dcminfo = dicominfo(filename);

    if (isfield(dcminfo, 'ImageType'))
        if (options.verbose)
        	fprintf('  Image dicom found: %s\n', filename);
        end
        
        info{imageIndex} = dcminfo;
        filenames{imageIndex} = fullfile(dirName, fileList(F).name);
        imageIndex = imageIndex + 1;
    else
        if (options.verbose)
            fprintf('  Meta dicom found: %s\n', filename);
        end
        metaFilenames{metaIndex} = fullfile(dirName, fileList(F).name);

        metaIndex = metaIndex + 1;
    end
end

end

end