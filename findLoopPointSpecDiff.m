function [lag, s1, sDiff] = findLoopPointSpecDiff(obj, lag, specDiff, left, right, S, ds)
% Finds the best sample at which to loop for a given lag value, and the
% sample difference between the loop start and end points. Requires that
% the sample difference is at most sDiffTol

    % EXPERIMENTAL: if nothing below tolerance is found, try perturbing the
    % lag value until a good sample pair is found

    % EXPERIMENTAL - goes with new findBestCluster (moved to findLoopPoint) scheme
%     [left, right] = obj.findBestCluster(specDiff, ds);
    [~, minidx] = min(specDiff(left:right));
    s1s = max(1, S(minidx+left-1)):...
        min(obj.l, S(minidx+left-1) + ds(minidx+left-1)-1);
    
    [lag, s1, sDiff] = obj.findLoopPoint(lag, s1s);


%     [~, minidx] = sort(specDiff, 'ascend');
%     
%     k = 1;
%     s1s = max(1, S(minidx(k))):min(obj.l, S(minidx(k)) + ds(minidx(k))-1);
%     sampleDiffs = calcSampleDiffs(obj.audio, s1s, lag);
%     
%     [sDiff, s1_idx] = min(sampleDiffs);
%     s1 = s1s(s1_idx);
%     
%     % If the best chunk doesn't meet the tolerance limit, iteratively try
%     % the next best chunk.
%     while(k <= length(minidx) && sDiff > obj.sDiffTol)
%         k = k+1;
%         
%         % If nothing works, just go back to the original s1
%         if(k > length(minidx))
%             s1 = ogS1;
%             sDiff = ogSDiff;
%             break;
%         end
%         
%         s1s = max(1, S(minidx(k))):min(obj.l, S(minidx(k)) + ds(minidx(k))-1);
%         sampleDiffs = calcSampleDiffs(obj.audio, s1s, lag);
% 
%         [sDiff, s1_idx] = min(sampleDiffs);
%         s1 = s1s(s1_idx);
%     end
end