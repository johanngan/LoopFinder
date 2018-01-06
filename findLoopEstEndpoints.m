function [t1, t2, c] = findLoopEstEndpoints(obj)
    
    pFor = .9;  % Of the obj.minLoopLength clip, 90% of it should be forward from the estimated time

    sFor = round(obj.Fs*obj.minLoopLength * pFor);
    sBack = round(obj.Fs*obj.minLoopLength * (1-pFor));
    
    if(~isempty(obj.t1_est))
        sStart1 = caps(obj.s1_est-sBack, 1, obj.l);
        sEnd1 = caps(obj.s1_est+sFor, 1, obj.l);
    end
    
    if(~isempty(obj.t2_est))
        sStart2 = caps(obj.s2_est-sBack, 1, obj.l);
        sEnd2 = caps(obj.s2_est+sFor, 1, obj.l);
    end
    
    % If only one loop point is estimated, use most of the audio track for
    % the other clip
    if(obj.loopMode == 2)       % t1 given
        sStart2 = sEnd1+1;
        sEnd2 = obj.l;
    elseif(obj.loopMode == 3)   % t2 given
        sStart1 = 1;
        sEnd1 = sStart2 - 1;
    end
    
    
    msres = obj.MSresNotAuto(obj.audio( sStart2:sEnd2 , :), obj.audio( sStart1:sEnd1 , :));
    lags = sStart2-sEnd1:sEnd2-sStart1;
    
    % Calculate minimum and maximum lag values
    sLeftIgnore = round(obj.leftIgnore*obj.Fs);
    sRightIgnore = round(obj.rightIgnore*obj.Fs);
    
    if(~isempty(obj.tauLims))
        % Don't use lags(1)+sLeftIgnore+1 and lags(end)-1-sRightIgnore, 
        % because if both endpoints are guessed, the overlap lengths of the 
        % msres will probably remain reasonably large for all valid lag
        % values, anyway. And if leftIgnore + rightIgnore > minLoopLength
        % (it is by default), this will compress the lag range to an empty
        % range.
        lag_min = max(ceil(obj.tauLims(1)*obj.Fs), sLeftIgnore);
        lag_max = min(floor(obj.tauLims(2)*obj.Fs), obj.l-1-sRightIgnore);
    else
        lag_min = lags(1)+sLeftIgnore;
        lag_max = lags(end)-sRightIgnore;
    end
    
    % Restrict lag values as specified
    msres = msres(lags >= lag_min & lags <= lag_max);
    lags = lags(lags >= lag_min & lags <= lag_max);
    
    % Weighting by distance
    if(~isempty(obj.tauLims) && obj.p_tau ~= 1 && obj.p_tau ~= 0)    % Won't work for 1, unnecessary for 0
        weights = 1 + obj.m_tau*abs(lags/obj.Fs - obj.tau_est);
        msres = msres .* weights;
    end
    
%     [loss, i] = sort(msres, 'ascend');
    
    % Take the nBest lag values
    [obj.nMSres, i] = obj.nMinCluster(msres);
    lags = lags(i);
    obj.lags = lags;
%     obj.nMSres = loss(1:obj.nBest);
%     lags = lags(i(1:obj.nBest));
    
    obj.s1s = zeros(size(lags));
    obj.sDiffs = zeros(size(lags));
    
    for j = 1:length(lags)
        lagVal = lags(j);
        s1s = caps(obj.findSample(max(obj.t2Lims(1)-lagVal/obj.Fs, obj.t1Lims(1))), ...
            1, obj.l) : caps(obj.findSample(min(obj.t1Lims(2), obj.t2Lims(2)-lagVal/obj.Fs)), 1, obj.l);
        [obj.lags(j), obj.s1s(j), obj.sDiffs(j)] = obj.findLoopPoint(lagVal, s1s);  % MODIFY findLoopPoint() to account for m_t1 and m_t2!
    end
    
    
    obj.s2s = obj.s1s + obj.lags;

    t1 = obj.findTime(obj.s1s);
    t2 = obj.findTime(obj.s2s);
    obj.confs = obj.calcConfidence(obj.nMSres, 0.1);    % Mess with regularization here
    c = obj.confs;
end

function y = caps(x, low, high)
    y = min(max(x, low), high);
end