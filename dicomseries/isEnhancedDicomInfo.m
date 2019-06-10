function [v] = isEnhancedDicomInfo(info)
% Checks whether the provided dicominfo is from an enhanced dicom file.

v = ~iscell(info) && isfield(info, 'PerFrameFunctionalGroupsSequence');
end
