function [P, F, S, ds] = calcSpectrogram(obj, x)
% S is the sample left endpoints, ds is the sample interval length of each chunk

%     [P, F, T] = pspectrum(x, obj.Fs, 'spectrogram', ...
%         'TimeResolution', obj.tres, 'OverlapPercent', obj.overlapPercent);
%     dt = repmat(T(2) - T(1), size(T, 1), size(T, 2));
    
    fmin = 0;
    fmax = 10000;
%     fmax = inf;
    
    stride = round( (1-obj.overlapPercent/100)*obj.tres*obj.Fs );
    nS = ceil( length(x) / stride );
    S = zeros(1, nS);
    ds = zeros(1, length(S));
    interval = 1:min(stride, length(x));
    S(1) = interval(1);
    ds(1) = length(interval);
    kbeta = 20;     % Kaiser beta
    [F, X] = obj.calcSpectrum(...
        kaiser(length(interval), kbeta) .* x(interval), fmin, fmax);
    P = zeros(length(F), length(S));
    P(:, 1) = X;
    
    for i = 2:length(S)
        interval = 1+(i-1)*stride:min(i*stride, length(x));
        S(i) = interval(1);
        ds(i) = length(interval);
        [~, P(:, i)] = obj.calcSpectrum(...
            [kaiser(length(interval), kbeta) .* x(interval); ...
                zeros(stride-length(interval), 1)], ...
            fmin, fmax);    % Zero-pad if last interval is too short
    end
end