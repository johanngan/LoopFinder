function time = findTime(obj, sample)
% Finds the time corresponding to sample number
    time = (sample-1)/obj.Fs;
end