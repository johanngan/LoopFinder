function specDiff = diffSpectra(obj, X1, X2)
% Mean square difference between two power density spectra X1 and X2 by 
% decibel levels, discarding points where both X1 and X2 are under 
% obj.dBLevel from the mean decibel level of the entire audio track.
%
% X1 and X2 must be column vectors.

    avgVol = obj.powToDB(mean(sum(obj.audio.^2, 2)));

    specDiff = zeros(size(X1));
    loudEnough = avgVol - obj.powToDB(X1) <= obj.dBLevel | avgVol - obj.powToDB(X2) <= obj.dBLevel;  % Difference only frequencies that are sufficiently loud
    specDiff(loudEnough) = (obj.powToDB(X1(loudEnough)) - obj.powToDB(X2(loudEnough))).^2;
    
    specDiff = sum(specDiff) / sum(loudEnough);
%     specDiff = sum(specDiff) / sum(loudEnough) + std(specDiff(loudEnough));     % Further penalize when there's a frequency region with large difference
    % Try using kurtosis of the residual distribution, or skewness of the
    % square-residual distribution?
    
%     k = kurtosis(specDiff(loudEnough));
%     if(isnan(k))
%         k = 1;
%     end
%     specDiff = k * sum(specDiff) / sum(loudEnough);
end