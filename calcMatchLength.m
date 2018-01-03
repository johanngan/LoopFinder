function l = calcMatchLength(obj, specDiff, ds, left, right, cutoff)
% Calculates "wastage" of a specDiff vector in seconds, or the time spent
% with a spectrum MSE greater than <cutoff> that is outside the cutoff
% region

%     l = sum(ds(left:right) / obj.Fs);

    l = sum(ds(specDiff <= cutoff) / obj.Fs); % TO TRY

%     inLoop = left:right;
%     l = sum(ds( inLoop(specDiff(inLoop) <= cutoff) )/obj.Fs);
end