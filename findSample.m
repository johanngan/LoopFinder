function sample = findSample(obj, time)
% Finds the sample number corresponding to a given time
    sample = 1 + round(time*obj.Fs);
end