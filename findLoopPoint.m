function [lag, s1, sDiff] = findLoopPoint(obj, lag, specDiff, left, right, S, ds)
% Finds the best sample at which to loop for a given lag value, and the
% sample difference between the loop start and end points. Requires that
% the sample difference is at most sDiffTol

    % EXPERIMENTAL: if nothing below tolerance is found, try perturbing the
    % lag value until a good sample pair is found

    % EXPERIMENTAL - goes with new findBestCluster scheme
%     [left, right] = obj.findBestCluster(specDiff, ds);
    [~, minidx] = min(specDiff(left:right));
    s1s = max(1, S(minidx+left-1)):...
        min(obj.l, S(minidx+left-1) + ds(minidx+left-1)-1);
    sampleDiffs = calcSampleDiffs(obj.audio, s1s, lag);
    [sDiff, s1_idx] = min(sampleDiffs);
    s1 = s1s(s1_idx);
    
    % If this works, return. If not, use another method
    if(sDiff <= obj.sDiffTol)
        return;
    end
    
    ogS1 = s1;
    ogSDiff = sDiff;

    dlag = 1;
    while(sDiff > obj.sDiffTol && abs(dlag) <= obj.minTDiff*obj.Fs/2)
        newLag = lag + dlag;
        sampleDiffs1 = calcSampleDiffs(obj.audio, s1s-dlag, newLag);
        sampleDiffs2 = calcSampleDiffs(obj.audio, s1s, newLag);
        [sDiff1, s1_idx1] = min(sampleDiffs1);
        [sDiff2, s1_idx2] = min(sampleDiffs2);
        if(sDiff1 < sDiff2)
            sDiff = sDiff1;
            s1 = s1s(s1_idx1)-dlag;
        else
            sDiff = sDiff2;
            s1 = s1s(s1_idx2);
        end
        
        % If dlag is nonpositive, increment the absolute value by one. If
        % dlag is positive, try the negative of it.
        if(dlag <= 0)
            dlag = abs(dlag) + 1;
        else
            dlag = -dlag;
        end
    end
    
    if(sDiff <= obj.sDiffTol)   % Succeeded
        lag = newLag;   % Perturbed lag
    else    % Failed
        sDiff = ogSDiff;
        s1 = ogS1;
    end
    % end experimental

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


function sampDiffs = calcSampleDiffs(x, s1s, lag)
    % The max difference of both channels between +-r of each point is 
    % taken as the total difference
%     r = round(.0005*44100/2);
    r = 1;
    
    first = find(s1s >= 1, 1, 'first');
    last = find(s1s+lag <= length(x), 1, 'last');
    sampDiffs0 = [inf(first-1, 1); ...
        max( abs(x(s1s(first:last), :) - x(s1s(first:last)+lag, :)) , [], 2); ...
        inf(length(x)-last, 1)];
%     sampDiffs = max( abs(x(max(1, s1s)) - x(min(length(x), s1s+lag))) , [], 2);

    if(r == 0)
        sampDiffs = sampDiffs0;
    else
        sampDiffs = inf(size(sampDiffs0));
        for i = first:last
            left = max(first, i-r);
            right = min(last, i+r);
            sampDiffs(i) = max(sampDiffs0(left:right));
        end
    end
end