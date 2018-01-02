function w = calcWastage(obj, specDiff, ds, left, right, cutoff)
% Calculates "wastage" of a specDiff vector in seconds, or the time spent
% with a spectrum MSE greater than <cutoff> that is outside the cutoff
% region

    outOfLoop = [1:left-1, right+1:length(specDiff)];
    w = sum(ds( outOfLoop(specDiff(outOfLoop) > cutoff) )/obj.Fs);
    
%     w = sum(specDiff > cutoff) .* obj.stride;
end