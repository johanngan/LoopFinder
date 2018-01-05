function w = calcWastage(obj, specDiff, sSize, left, right, cutoff)
% Calculates "wastage" of a specDiff vector in seconds, or the time spent
% with a spectrum MSE greater than <cutoff> that is outside the cutoff
% region

%     % TO TRY: use the NEW cutoff to determine left and right for the region
%     left = find(specDiff <= cutoff, 1, 'first');
%     right = find(specDiff <= cutoff, 1, 'last');

    outOfLoop = [1:left-1, right+1:length(specDiff)];
    w = sum(sSize( outOfLoop(specDiff(outOfLoop) > cutoff) )/obj.Fs);

%     w = sum(sSize(outOfLoop) / obj.Fs);
end