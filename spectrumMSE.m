function [lag, L, s1, sDiff, spectrograms, F, S, left, right, oldlag, specDiff] = spectrumMSE(obj, lag)
% Analyzes the spectrum MSE of a given lag value and returns the MSE, and
% the estimated loop start point and its sample difference
    
    spectrograms = cell(2, obj.nChannels);
    [P1, F, S, ds] = obj.calcSpectrogram(obj.audio(1+lag:end, 1));
    P2 = obj.calcSpectrogram(obj.audio(1:end-lag, 1));
    
    spectrograms{1, 1} = P1;
    spectrograms{2, 1} = P2;
    specDiff = obj.diffSpectrogram(P1, P2);
    for c = 2:obj.nChannels
        
        P1 = obj.calcSpectrogram(obj.audio(1+lag:end, c));
        P2 = obj.calcSpectrogram(obj.audio(1:end-lag, c));
        spectrograms{1, c} = P1;
        spectrograms{2, c} = P2;
%         specDiff = specDiff + ...
%             obj.diffSpectrogram(...
%                 obj.calcSpectrogram(obj.audio(1+lag:end, c)), ...
%                 obj.calcSpectrogram(obj.audio(1:end-lag, c)) ...
%             );
        specDiff = specDiff + obj.diffSpectrogram(P1, P2);
    end
    
    [left, right] = obj.findBestCluster(specDiff, ds);
    oldlag = lag;
    lag = obj.refineLag(lag, S(left), S(right)+ds(right)-1);
    [lag, s1, sDiff] = obj.findLoopPoint(lag, specDiff, left, right, S, ds);
    L = mean(specDiff(left:right));
end