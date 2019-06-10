function [image] = rescaleDicomImage(image, info)
% Rescales a dicom image according to its rescale slope and intercept
% values specified in its dicominfo.

% Convert image to floating point type if necessary
if (~isa(image, 'single') && ~isa(image, 'double'))
    image = single(image);
end

warn = 0;

for I=1:size(image,3)
    [slope, foundSlope] = getDicomAttribute(info, 'RescaleSlope', I);
    if ~foundSlope
        [slope, foundSlope] = getDicomAttribute(info, 'RescaleSlopeOriginal', I);
    end
    [intercept, foundIntercept] = getDicomAttribute(info, 'RescaleIntercept', I);
    if ~foundIntercept
        [intercept, foundIntercept] = getDicomAttribute(info, 'RescaleInterceptOriginal', I);
    end
    
    if ~foundSlope || ~foundIntercept
        warn = warn + 1;
    else
        image(:,:,I) = image(:,:,I) * slope + intercept;
    end
end

if (warn > 0)
    warning('No rescale information found in %d slices', warn);
end

end
