function [lag, L, s1, sDiff] = spectrumMSE(obj, lag)
% Analyzes the spectrum MSE of a given lag value and returns the MSE, and
% the estimated loop start point and its sample difference
    
    [P1, ~, S, ds] = obj.calcSpectrogram(obj.audio(1+lag:end, 1));
    P2 = obj.calcSpectrogram(obj.audio(1:end-lag, 1));
    
    specDiff = obj.diffSpectrogram(P1, P2);
    for c = 2:obj.nChannels
        specDiff = specDiff + ...
            obj.diffSpectrogram(...
                obj.calcSpectrogram(obj.audio(1+lag:end, c)), ...
                obj.calcSpectrogram(obj.audio(1:end-lag, c)) ...
            );
    end
    
    [left, right] = obj.findBestCluster(specDiff, ds);
    lag = obj.refineLag(lag, S(left), S(right)+ds(right)-1);
    [lag, s1, sDiff] = obj.findLoopPoint(lag, specDiff, left, right, S, ds);
    L = mean(specDiff(left:right));
end