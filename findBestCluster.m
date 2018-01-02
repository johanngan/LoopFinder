function [left, right, cutoff] = findBestCluster(obj, specDiff, ds)
% Finds the region of time with the smallest values of specDiff, where a
% region must be at least obj.minLoopLength seconds long
%
% dt is a vector of equal length to specDiff corresponding to the time
% duration of each difference region

    dt = ds/obj.Fs;

    % EXPERIMENTAL - keep taking the next best specDiff until a long enough
    % interval is found
    [sortSD, i] = sort(specDiff, 'ascend');
    minSD = sortSD(1);
%     k = 2;
    k = round(obj.minLoopLength / obj.stride);
%     bestk = i(1:min(k, length(specDiff)));
%     left = min(bestk);
%     right = max(bestk);

    m = 2;  % Median multiplier
    cutoff = m*(median(sortSD(1:k))-minSD) + minSD;
    left = find(specDiff <= cutoff, 1, 'first');
    right = find(specDiff <= cutoff, 1, 'last');
    
    while(sum(dt(left:right)) < obj.minLoopLength)
        
        if(k < length(specDiff))
            k = k+1;
            cutoff = m*(median(sortSD(1:k))-minSD) + minSD;
        else
            % Continue in the case of failure by slowly raising the bar
            cutoff = sortSD(find(sortSD > cutoff, 1, 'first'));
        end
        
        left = find(specDiff <= cutoff, 1, 'first');
        right = find(specDiff <= cutoff, 1, 'last');
        
%         left = min(left, i(k));
%         right = max(right, i(k));
    end
    
    
    % This has trouble with songs like Pokemon Square
%     % EXPERIMENTAL - find the interval of length obj.minLoopLength with the
%     % lowest mean specDiff
%     minSize = ceil(obj.minLoopLength / dt(1));
%     left = 1;
%     right = left + minSize - 1;
%     meanSpecDiff = mean(specDiff(left:right));
%     for left_new = 2:length(specDiff) - minSize + 1
%         right_new = left_new + minSize - 1;
%         meanSpecDiff_new = mean(specDiff(left_new:right_new));
%         if(sum(dt(left_new:right_new)) >= obj.minLoopLength && ...
%                 meanSpecDiff_new < meanSpecDiff)
%             left = left_new;
%             right = right_new;
%             meanSpecDiff = meanSpecDiff_new;
%         end
%     end

%     left = 0; right = 0;
%     left_new = 1; right_new = length(specDiff);
%     
%     % While the new interval is non-empty and shrinking on both sides
%     % (which means the new better_cutoff got looser)
%     while(~isempty(left_new) && ~(left_new <= left && right_new >= right))
%         left = left_new; right = right_new;
%         specDiffRed = specDiff(left:right);
%         left_new = []; right_new = [];
%         cutoff = obj.minRangeCutoff;
%         while(isempty(left_new) && cutoff <= obj.maxRangeCutoff)
%             belowCutoff = specDiffRed(specDiffRed-min(specDiffRed) <= cutoff*range(specDiffRed));
%             r = median(belowCutoff) - min(belowCutoff);
%             betterCutoff = obj.cutoffRad*r;
% 
%             left_new = find(specDiff-min(specDiff) <= betterCutoff, 1, 'first');
%             right_new = find(specDiff-min(specDiff) <= betterCutoff, 1, 'last');
%             % Make sure loop region is large enough
%             if(sum(dt(left_new:right_new)) < obj.minLoopLength)
%                 % Attempt to fall back to the preliminary range cutoff
%                 
%                 left_new = find(specDiff-min(specDiffRed) <= cutoff*range(specDiffRed), 1, 'first');  % Notice specDiff and specDiffRed are used here
%                 right_new = find(specDiff-min(specDiffRed) <= cutoff*range(specDiffRed), 1, 'last');
%                 
%                 % If this still doesn't work, then just give up and set to empty
%                 if(sum(dt(left_new:right_new)) < obj.minLoopLength)
%                     left_new = []; right_new = [];
%                 end
%             end
% 
%             cutoff = cutoff + obj.incRangeCutoff;   % Try raising the initial bar by an increment
%         end
%     end
end