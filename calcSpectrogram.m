function [P, F, S, ds] = calcSpectrogram(obj, x)
% S is the sample left endpoints, ds is the sample interval length of each chunk

%     [P, F, T] = pspectrum(x, obj.Fs, 'spectrogram', ...
%         'TimeResolution', obj.tres, 'OverlapPercent', obj.overlapPercent);
%     sRights = zeros(size(T));
%     for t = 1:length(T)-1
%         sRights(t) = obj.findSample(mean(T(t:t+1)));
%     end
%     sRights(end) = length(x);
%     S = zeros(size(T));
%     S(1) = 1;
%     S(2:end) = sRights(1:end-1) + 1;
%     ds = sRights - S;
%     
%     return
    
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
    
   % Get window function
    window = windowFunction(length(interval));
    
    [F, X] = obj.calcSpectrum(...
        window .* x(interval), fmin, fmax);
    P = zeros(length(F), length(S));
    P(:, 1) = X;
    
    for i = 2:length(S)
        interval = 1+(i-1)*stride:min(i*stride, length(x));
        S(i) = interval(1);
        ds(i) = length(interval);
        
        window = windowFunction(length(interval));
        [~, P(:, i)] = obj.calcSpectrum(...
            [window .* x(interval); ...
                zeros(stride-length(interval), 1)], ...
            fmin, fmax);    % Zero-pad if last interval is too short
    end
end

function w = windowFunction(N)
 % Select the N-point windowing function
    
    %%% Promising window functions: Rectangular, Exponential, Hamming,
    %%% Exponential-Hann
    w = ones(N, 1);     % Rectangular
    
%     kbeta = 0;  % Low sidelobe attenuation, high leakage
%     kbeta = 20;     % Kaiser beta
%     kbeta = 40;     % 0 leakage
%     w = kaiser(N, kbeta);
% 
%     w = hamming(N);
% 
%     ealpha = 2;
%     w = exp(-ealpha*abs(N-2*(0:N-1)/N))';
%     w = w .* hann(N);
end