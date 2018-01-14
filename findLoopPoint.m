function [lag, s1, sDiff] = findLoopPoint(obj, lag, s1s)
% <s1s> is the range of s1 values to scan through for a given lag value

    % Case where outcome is determined
    noVar = obj.loopMode == 1 && obj.p_t1 == 1 && obj.p_t2 == 1;
    if(noVar)
        s1 = obj.s1_est;
        lag = obj.s2_est - s1;
        s1s = s1-1:s1+1;
    end
    
    sampleDiffs = calcSampleDiffs(obj.audio, s1s, lag);
    
    % Return when outcome is already determined
    if(noVar)
        sDiff = sampleDiffs(2);
        return;
    end
    
%     % Determine s1 (and s2) and sDiff
%     if(~isempty(obj.t1_est) && obj.p_t1 == 1)
%         s1 = obj.s1_est;
%         sDiff = sampleDiffs(s1s == s1);
%     elseif(~isempty(obj.t2_est) && obj.p_t2 == 1)
%         s1 = obj.s2_est - lag;
%         sDiff = sampleDiffs(s1s == s1);
%     else
%         % Do deviation penalties if necessary
%         toMin = sampleDiffs;
%         
%         if(~isempty(obj.t1_est) && obj.p_t1 ~= 0)
%             weights1 = 1 + obj.m_t1*abs(s1s/obj.Fs - obj.t1_est);
%             toMin = toMin .* weights1;
%         end
%         
%         if(~isempty(obj.t2_est) && obj.p_t2 ~= 0)
%             weights2 = 1 + obj.m_t2*abs((s1s + lag)/obj.Fs - obj.t2_est);
%             toMin = toMin .* weights2;
%         end
%         
%         [~, s1_idx] = min(toMin);
%         
%         sDiff = sampleDiffs(s1_idx);
%         s1 = s1s(s1_idx);
%     end

    % Get the best possible sample difference out of s1s, accounting for
    % any weighting
    [s1, sDiff] = getMinSampleDiffs(obj, s1s, lag, sampleDiffs);

    % If enough of them work, or there is no lag variance, return. If not, use another method
    ogS1 = s1(1);
    ogSDiff = sDiff(1);
    ogLag = lag;
    
    s1 = s1(sDiff <= obj.sDiffTol);
    lag = repelem(lag, length(s1));
%     if(sDiff <= obj.sDiffTol || obj.p_tau == 1)
%         return;
%     end
    if(length(s1) >= obj.nBestPairs)
        return;
    end
        
    negFlag = false;    % Flag for only decrementing dlag
    posFlag = false;    % Flag for only incrementing dlag
    dlag = 1;
%     while(sDiff > obj.sDiffTol && abs(dlag) <= obj.minTDiff*obj.Fs/2)
    while(length(s1) < obj.nBestPairs && abs(dlag) <= obj.minTDiff*obj.Fs/2)
        newLag = ogLag + dlag;
        
        % Change s1
        sampleDiffs1 = calcSampleDiffs(obj.audio, s1s-dlag, newLag);
        if(~isempty(obj.t1_est))
            sampleDiffs1 = sampleDiffs1(...
                obj.Fs*(s1s-dlag) >= obj.t1Lims(1) & obj.Fs*(s1s-dlag) <= obj.t1Lims(2));
        end
        
        % Change s2
        sampleDiffs2 = calcSampleDiffs(obj.audio, s1s, newLag);
        if(~isempty(obj.t2_est))
            sampleDiffs2 = sampleDiffs2(...
                obj.Fs*(s1s+newLag) >= obj.t2Lims(1) & obj.Fs*(s1s+newLag) <= obj.t2Lims(2));
        end

        % Get the best possible sample difference out of s1s, accounting for
        % any weighting
        s1Add = [];
        sDiffAdd = [];
        [s1_1, sDiff1] = getMinSampleDiffs(obj, s1s-dlag, newLag, sampleDiffs1);
        [s1_2, sDiff2] = getMinSampleDiffs(obj, s1s, newLag, sampleDiffs2);
    
%         [~, s1_idx1] = min(sampleDiffs1);
%         [~, s1_idx2] = min(sampleDiffs2);        
%         sDiff1 = sampleDiffs1(s1_idx1);
%         sDiff2 = sampleDiffs2(s1_idx2);

%         if(~isempty(sDiff1) && (isempty(sDiff2) || sDiff1 < sDiff2))
%             sDiff = sDiff1;
% %             s1 = s1s(s1_idx1)-dlag;
%             s1 = s1_1;
%         elseif(~isempty(sDiff2))
%             sDiff = sDiff2;
% %             s1 = s1s(s1_idx2);
%             s1 = s1_2;

        if(~isempty(sDiff1))
            toAdd = find(sDiff1 <= obj.sDiffTol);
            s1Add = [s1Add, s1_1(toAdd)];
            sDiffAdd = [sDiffAdd, sDiff1(toAdd)];
        end
        if(~isempty(sDiff2))
            toAdd = find(sDiff2 <= obj.sDiffTol);
            s1Add = [s1Add, s1_2(toAdd)];
            sDiffAdd = [sDiffAdd, sDiff2(toAdd)];
        end
        
        if(isempty(sDiff1) && isempty(sDiff2))
            % Both empty
            break;
        end
        
        
        nLeft = obj.nBestPairs - length(s1);
        if(length(sDiffAdd) > nLeft)
            [sDiffAdd, addIdx] = sort(sDiffAdd, 'ascend');
            sDiffAdd(1:nLeft);
            s1Add = s1Add(addIdx(1:nLeft));
        end
        
        if(~isempty(s1Add))
            s1 = [s1, s1Add];
            sDiff = [sDiff, sDiffAdd];
            lag = [lag, repelem(newLag, length(s1Add))];
        end
            
        % If dlag is nonpositive, increment the absolute value by one. If
        % dlag is positive, try the negative of it. If either flag is
        % active, instead increment accordingly.
        if(~isempty(obj.tauLims) && posFlag)
            dlag = dlag + 1;
        elseif(~isempty(obj.tauLims) && negFlag)
            dlag = dlag - 1;
        elseif(dlag <= 0)
            dlag = abs(dlag) + 1;
        else
            dlag = -dlag;
        end
        
        % Extra conditions for manually estimated lag behavior to turn on 
        % posFlag or negFlag, and break if necessary
        if(~isempty(obj.tauLims))
%             if(ogLag+dlag < obj.Fs*obj.tauLims(1))    % Lag is too small
            if(newLag < obj.Fs*obj.tauLims(1))    % Lag is too small
                posFlag = true;
                dlag = abs(dlag) + 1;
            end
            
%             if(ogLag+dlag > obj.Fs*obj.tauLims(2))    % Lag is too big
            if(newLag > obj.Fs*obj.tauLims(2))    % Lag is too big
                negFlag = true;
                dlag = -abs(dlag) - 1;
            end
            
            % If both flags are active, break, because lag is out of range
            if(posFlag && negFlag)
                break;
            end
        end
    end
    
%     if(sDiff <= obj.sDiffTol)   % Succeeded
%         lag = newLag;   % Perturbed lag
%     else    % Failed
    if(isempty(s1))     % Failed
        sDiff = ogSDiff;
        s1 = ogS1;
        lag = ogLag;
    end
end


function sampDiffs = calcSampleDiffs(x, s1s, lag)
    % The max difference of both channels between +-r of each point is 
    % taken as the total difference
%     r = round(.0005*44100/2);
    r = 1;
    
    first = find(s1s >= 1, 1, 'first');
    last = find(s1s+lag <= length(x), 1, 'last');
%     sampDiffs0 = [inf(first-1, 1); ...
%         max( abs(x(s1s(first:last), :) - x(s1s(first:last)+lag, :)) , [], 2); ...
%         inf(length(x)-last, 1)];
    sampDiffs0 = [inf(first-1, 1); ...
        max( abs(x(s1s(first:last), :) - x(s1s(first:last)+lag, :)) , [], 2); ...
        inf(length(s1s)-last, 1)];
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
    
    % Make into a row vector, like s1s
    sampDiffs = sampDiffs';
end

function [s1, sDiff] = getMinSampleDiffs(obj, s1s, lag, sampleDiffs)
% Determine s1 (and s2) and sDiff, accounting for manual estimation if
% necessary

    if(~isempty(obj.t1_est) && obj.p_t1 == 1)
        s1 = obj.s1_est;
        sDiff = sampleDiffs(s1s == s1);
    elseif(~isempty(obj.t2_est) && obj.p_t2 == 1)
        s1 = obj.s2_est - lag;
        sDiff = sampleDiffs(s1s == s1);
    else
        % Do deviation penalties if necessary
        toMin = sampleDiffs;
        
        if(~isempty(obj.t1_est) && obj.p_t1 ~= 0)
            weights1 = 1 + obj.m_t1*abs(s1s/obj.Fs - obj.t1_est);
            toMin = toMin .* weights1;
        end
        
        if(~isempty(obj.t2_est) && obj.p_t2 ~= 0)
            weights2 = 1 + obj.m_t2*abs((s1s + lag)/obj.Fs - obj.t2_est);
            toMin = toMin .* weights2;
        end
        
        [~, s1_idx] = obj.nMinCluster(toMin, obj.nBestPairs);
%         [~, minIs] = sort(toMin, 'ascend');
%         s1_idx = minIs(1:obj.nBestPairs);
%         [~, s1_idx] = min(toMin);
        
        sDiff = sampleDiffs(s1_idx);
        s1 = s1s(s1_idx);
    end
end