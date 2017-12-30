function [lag, L] = refineLag(obj, lag, sLeft, sRight)
% Redoes the MSres comparison using the found loop region only, and looks
% within obj.minTDiff/2 of the original lag value
%
% Normalize by overlap length, but not by average power anymore, which
% shouldn't matter too much.

    addpath('wavematch/cxcorr_fft');
    
    msRes = zeros(1, 2*(sRight-sLeft+1)-1);
    
    for c = 1:obj.nChannels
        a = obj.audio(sLeft+lag:sRight+lag, c);
        b = obj.audio(sLeft:sRight, c);
        overlapLengths = [1:sRight-sLeft+1, sRight-sLeft:-1:1];
        msRes = msRes + ssres_fft(a, b) .* avgPwrWeights(a, b) ./ overlapLengths;
    end
    
    sRad = min(sRight-sLeft, round(obj.minTDiff/2 * obj.Fs));
    zeroOffset = sRight-sLeft+1;
    [L, lagOffset] = min(msRes(zeroOffset-sRad:zeroOffset+sRad));
    lagOffset = lagOffset-1 - sRad;
    
    lag = lag + lagOffset;
end

function weights = avgPwrWeights(a, b)
% Vector of average power of overlap region of a crosscorrelation

    pows1 = (a.^2 + flip(b.^2))';
    weights1 = (1:length(pows1)) ./ cumsum(pows1);
    
    pows2 = (b.^2 + flip(a.^2))';
    pows2 = pows2(1:end-1);
    weights2 = flip( (1:length(pows2)) ./ cumsum(pows2) );
    
    weights = [weights1, weights2];
    weights(isinf(weights)) = 0;
end