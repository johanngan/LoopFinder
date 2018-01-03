function [lag, L, s1, sDiff, wastage, matchLength, spectrograms, F, S, left, right, cutoff, oldlag, specDiff] = spectrumMSE(obj, lag)
% Analyzes the spectrum MSE of a given lag value and returns the MSE, and
% the estimated loop start point and its sample difference
    
    spectrograms = cell(2, obj.nChannels);
    [P1, F, S, ds] = obj.calcSpectrogram(obj.audio(1:end-lag, 1));
    P2 = obj.calcSpectrogram(obj.audio(1+lag:end, 1));
    
    spectrograms{1, 1} = P1;
    spectrograms{2, 1} = P2;
    specDiff = obj.diffSpectrogram(P1, P2);
    for c = 2:obj.nChannels
        
        P1 = obj.calcSpectrogram(obj.audio(1:end-lag, c));
        P2 = obj.calcSpectrogram(obj.audio(1+lag:end, c));
        spectrograms{1, c} = P1;
        spectrograms{2, c} = P2;
%         specDiff = specDiff + ...
%             obj.diffSpectrogram(...
%                 obj.calcSpectrogram(obj.audio(1+lag:end, c)), ...
%                 obj.calcSpectrogram(obj.audio(1:end-lag, c)) ...
%             );
        specDiff = specDiff + obj.diffSpectrogram(P1, P2);
    end
    
    [left, right, cutoff] = obj.findBestCluster(specDiff, ds);
%     cutoff = 2*min(median(specDiff(left:right)), mean(specDiff(left:right)));
    % For cutoff, try using a median multiplier of min(10, length(specDiff)/2)
    
    wastage = obj.calcWastage(specDiff, ds, left, right, cutoff);   % TO TRY using a lighter cutoff? 2x?
    matchLength = obj.calcMatchLength(specDiff, ds, left, right, cutoff);   % TO TRY using a lighter cutoff?
    
    
    oldlag = lag;
    lag = obj.refineLag(lag, S(left), S(right)+ds(right)-1);
    [lag, s1, sDiff] = obj.findLoopPoint(lag, specDiff, left, right, S, ds);
    L = mean(specDiff(left:right));
end