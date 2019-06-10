function [info] = filterDicomFrames(info, frames)
% Internal function to filter out certain frames from an enhanced dicominfo
% structure.

result = struct();
for I=1:length(frames)
    result.(sprintf('Item_%d', I)) = info.PerFrameFunctionalGroupsSequence.(sprintf('Item_%d', frames(I)));
end

info.PerFrameFunctionalGroupsSequence = result;

end
