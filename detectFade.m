function fadeLength = detectFade(obj, audio, Fs)
    fadeLength = 0;
    
    minFadeLength = 4;  % In seconds
    maxFadeLength = 15;
    proportion = .975;   % Proportion that has to be decreasing
    chunkSize = 0.25;    % In seconds
    
    minS = round(minFadeLength * Fs);
    chunkS = round(chunkSize * Fs);
    
    nChunks = round(maxFadeLength / chunkSize);
    
    avgPow = mean(sum(audio.^2, 2));
    nEff = find(audio(:, 1).^2 > avgPow*1e-6 | audio(:, 2).^2 > avgPow*1e-6, 1, 'last');
    totChunks = floor(nEff / chunkS);
    
    nChunks = min(nChunks, totChunks);
    lastPows = zeros(nChunks, 1);
    for i = 1:length(lastPows)
        lastPows(end-i+1) = mean(sum(audio(nEff-i*chunkS+1:nEff-(i-1)*chunkS, :).^2, 2));
    end
    if(lastPows(end) > avgPow/20)
        return;
    end
    r = round(.4*minFadeLength/chunkSize);
    lastPows = obj.smoothen(lastPows, r);
    
    decreasing = diff(lastPows) < 0;
    for s = 1:floor(nChunks - minS/chunkS)
        if(mean(decreasing(s:end)) >= proportion)
            fadeLength = (nChunks-s)*chunkS + length(audio)-nEff;
            return;
        end
    end
end