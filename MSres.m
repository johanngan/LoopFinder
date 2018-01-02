function L = MSres(obj)
% Normalized residual mean square error over lags

%     addpath('wavematch/cxcorr_fft');
    
    L = zeros(1, obj.l);
    for c = 1:obj.nChannels
        x = obj.audio(:, c);
        L = L + auto_ssres_fft(x) .* avgPwrWeights(x) ./ (length(x):-1:1);
    end
end

function weights = avgPwrWeights(audio)
% Vector of average power of overlap region of an autocorrelation

    pows = (audio.^2)';
    pows = pows + flip(pows);
    weights = flip((1:length(pows)) ./ cumsum(pows));
    weights(isinf(weights)) = 0;
end