function w = calcWastage(obj, specDiff, cutoff)
% Calculates "wastage" of a specDiff vector in seconds, or the time spent
% with a spectrum MSE greater than <cutoff>

    w = sum(specDiff > cutoff) * obj.tres;
end