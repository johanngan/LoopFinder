function L = MSresNotAuto(obj, audio1, audio2)
% Normalized residual mean square error over lags for unidentical audio
% clips

%     addpath('wavematch/cxcorr_fft');
    
    m = length(audio1);
    n = length(audio2);
    L = zeros(1, m+n-1);
    overlaps = overlapLengths(m, n);
    for c = 1:obj.nChannels
        x1 = audio1(:, c);
        x2 = audio2(:, c);
        L = L + ssres_fft(x1, x2) .* avgPwrWeights(x1, x2) ./ overlaps;
    end
end

function overlaps = overlapLengths(m, n)
    overlaps = [1:min(m, n)-1, ...
                repmat(min(m, n), 1, m+n-1 - 2*(min(m, n)-1)), ...
                min(m, n)-1:-1:1];
end

function weights = avgPwrWeights(x1, x2, reg)
% Vector of average power of overlap region of the cross-ssres

    if(nargin < 3)
        reg = 5e-3; % Regularization so that weights don't blow up for very low power levels (aka silence)
    end

    if(length(x1) <= length(x2))
        pShort = torow(x1.^2);
        pLong = torow(x2.^2);
        flipFlag = false;
        
    else
        pShort = torow(x2.^2);
        pLong = torow(x1.^2);
        flipFlag = true;    % Power level calculations will be in reverse order, and must be flipped back later
    end
    
    m = length(pShort);
    n = length(pLong);
    
    totPowsShort = cumsum(pShort(1:end-1));
    totPowsShort = [totPowsShort, ...
                    repmat(totPowsShort(end)+pShort(end), 1, n-m+1), ...
                    flip(cumsum(flip(pShort(2:end))))];
    
    totPowsLong = zeros(1, m+n-1);
    totPowsLong(1:m) = cumsum(flip(pLong(end-(m-1):end)));    % (m+n-1) - (m-1) == n
    totPowsLong(end-(m-2):end) = flip(cumsum(pLong(1:m-1)));  % (m+n-1) - (m-2) == n+1
    
    for i = m+1:n     % (m+n-1) - (m-1) == n
        totPowsLong(i) = totPowsLong(i-1) - pLong(m+n+1-i) + pLong(n+1-i);
    end
    
    weights = 1 ./ ((totPowsShort + totPowsLong) ./ overlapLengths(m, n) + reg);
    weights(isinf(weights)) = 0;
    
    if(flipFlag)
        weights = flip(weights);
    end
end

function r = torow(v)
% Convert to row vector
    if(size(v, 1) > size(v, 2))
        r = v';
    else
        r = v;
    end
end