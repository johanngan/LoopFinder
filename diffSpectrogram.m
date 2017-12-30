function specDiffs = diffSpectrogram(obj, P1, P2)
% Calculates the mean spectrum difference between corresponding columns of
% P1 and P2, and assembles the differences in a row vector

    specDiffs = zeros(1, size(P1, 2));
    
    for t = 1:length(specDiffs)
        specDiffs(t) = obj.diffSpectra(P1(:, t), P2(:, t));
    end
end