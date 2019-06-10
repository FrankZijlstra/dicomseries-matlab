function [ matchedPartitions ] = findMatchingPartitions(partitions, matchStruct)
% Finds all partition that match the dicom tags specified in matchStruct.
% partitions is the imagePartitions structure returned by readDicomSeries.
% matchStruct should be a structure where each element is a dicom tag that
% should match the information in partitions(x).partitionStruct (this is
% both type-sensitive and case-sensitive!).
%
% Returns matchedPartitions, a subset of partitions that match matchStruct.

K = 0;
for I=1:length(partitions)
    f = fieldnames(matchStruct);
    
    allEqual = true;
    for J=1:length(f)
        if (~isequal(partitions(I).partitionStruct.(f{J}), matchStruct.(f{J})))
            allEqual = false;
            break;
        end
    end
    
    if (allEqual)
        K = K + 1;
        matchedPartitions(K) = partitions(I);
    end
end

if (K == 0)
    matchedPartitions = [];
end

end

