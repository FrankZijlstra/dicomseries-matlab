function [value, found] = getDicomAttribute(info, name, frame)
% getDicomAttribute is an utility function to access dicom tags in a
% consistent manner from both classic and enhanced dicom files.
%
% In case of classic dicom: the return value is info{frame}.<name> or
% info.<name> if info is not a cell array.
%
% In case of enhanced dicom: a translation table is used to find out where
% the requested tag can be found in an enhanced dicom structure for the
% given frame number (usually
% info.PerFrameFunctionalGroupsSequence.Item_<frame>. etc.). The
% translation table contains locations mostly for MR-related dicom tags, if
% you find some that are missing, please let me know).
%
% If the frame number is not specified, it defaults to 1.
%
% If the requested dicom tag is not found, the found return value is set to
% false, and the return value will be [].



persistent enhancedLookup

if (isempty(enhancedLookup))
    % In the lookup, %d gets replaced by frame number
    enhancedLookup = struct();
    % Private
    enhancedLookup.EchoTime = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PrivatePerFrameSq', 'Item_1', 'EchoTime'}; %info.PerFrameFunctionalGroupsSequence.Item_1.MREchoSequence.Item_1.EffectiveEchoTime ?
    enhancedLookup.EchoNumber = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PrivatePerFrameSq', 'Item_1', 'EchoNumber'};
    enhancedLookup.ImageType = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PrivatePerFrameSq', 'Item_1', 'ImageType'};
    enhancedLookup.TemporalPositionIdentifier = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PrivatePerFrameSq', 'Item_1', 'TemporalPositionIdentifier'};
    enhancedLookup.ScanningSequence = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PrivatePerFrameSq', 'Item_1', 'ScanningSequence'};
    enhancedLookup.SequenceVariant = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PrivatePerFrameSq', 'Item_1', 'SequenceVariant'};

    enhancedLookup.ImagePositionPatient = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PlanePositionSequence', 'Item_1', 'ImagePositionPatient'};
    
    enhancedLookup.ImageOrientationPatient = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PlaneOrientationSequence', 'Item_1', 'ImageOrientationPatient'};
    
    enhancedLookup.SliceThickness = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PixelMeasuresSequence', 'Item_1', 'SliceThickness'};
    enhancedLookup.SpacingBetweenSlices = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PixelMeasuresSequence', 'Item_1', 'SpacingBetweenSlices'};
    enhancedLookup.PixelSpacing = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PixelMeasuresSequence', 'Item_1', 'PixelSpacing'};
    
    enhancedLookup.RescaleIntercept = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PixelValueTransformationSequence', 'Item_1', 'RescaleIntercept'};
    enhancedLookup.RescaleSlope = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'PixelValueTransformationSequence', 'Item_1', 'RescaleSlope'};
    
    enhancedLookup.StackID = {'PerFrameFunctionalGroupsSequence', 'Item_%d', 'FrameContentSequence', 'Item_1', 'StackID'};
    
    % Shared
    enhancedLookup.RepetitionTime = {'SharedFunctionalGroupsSequence', 'Item_1', 'MRTimingAndRelatedParametersSequence', 'Item_1', 'RepetitionTime'};
    enhancedLookup.FlipAngle = {'SharedFunctionalGroupsSequence', 'Item_1', 'MRTimingAndRelatedParametersSequence', 'Item_1', 'FlipAngle'};
    
    enhancedLookup.NumberOfAverages = {'SharedFunctionalGroupsSequence', 'Item_1', 'MRAveragesSequence', 'Item_1', 'NumberOfAverages'};

    enhancedLookup.PercentPhaseFieldOfView = {'SharedFunctionalGroupsSequence', 'Item_1', 'MRFOVGeometrySequence', 'Item_1', 'PercentPhaseFieldOfView'};
    enhancedLookup.InPlanePhaseEncodingDirection = {'SharedFunctionalGroupsSequence', 'Item_1', 'MRFOVGeometrySequence', 'Item_1', 'InPlanePhaseEncodingDirection'};
end

if (nargin < 3 || isempty(frame))
    frame = 1;
end

found = false;

if (iscell(info))
    % Cell array of info is always classic dicom
    if (isfield(info{frame}, name))
        value = info{frame}.(name);
        found = true;
    else
        value = [];
    end
elseif (~isEnhancedDicomInfo(info))
    % Single classic dicom dicominfo (ignores frame number)
    if (isfield(info, name))
        value = info.(name);
        found = true;
    else
        value = [];
    end
else
    % Enhanced dicom
    if (isfield(enhancedLookup, name))
        % Try-catch is easier than checking whether each sub-name is a
        % field..
        try
            lookup = enhancedLookup.(name);
            lookup = cellfun(@(x)sprintf(x,frame), lookup, 'UniformOutput', false);
            S = struct('subs', lookup, 'type', '.');        
            value = subsref(info, S);
            found = true;
            return
        catch
        end
    end
    
    if (isfield(info, name))
        value = info.(name);
        found = true;
    else
        value = [];
    end
end

end

