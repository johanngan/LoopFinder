function l = calcMatchLength(obj, specDiff, sSize, left, right, cutoff)
% Calculates "wastage" of a specDiff vector in seconds, or the time spent
% with a spectrum MSE greater than <cutoff> that is outside the cutoff
% region

    l = sum(sSize(specDiff <= cutoff) / obj.Fs);

%     % TO TRY: use the NEW cutoff to determine left and right for the region
%     left = find(specDiff <= cutoff, 1, 'first');
%     right = find(specDiff <= cutoff, 1, 'last');
%     l = sum(sSize(left:right) / obj.Fs);
end