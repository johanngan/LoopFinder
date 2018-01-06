function useDefaultParams(obj)
    obj.leftIgnore = 5;
    obj.rightIgnore = 5;
    obj.nBest = 15;
%     obj.sDiffTol = inf;
    obj.sDiffTol = .05;
    
    obj.minLoopLength = 5;
%     obj.tres = 2.5;
    obj.tres = 2^17 / 44100;    % ~3 seconds; makes fft lengths a power of 2 for Fs = 44100, 22050, etc.
    obj.overlapPercent = 50;
    
    obj.minTDiff = .1;
    obj.dBLevel = 70;
        obj.powRef = 1e-12; % Standard reference level
    obj.minRangeCutoff = .05;
    obj.maxRangeCutoff = .25;
    obj.incRangeCutoff = .05;
    obj.cutoffRad = 2;
    
    obj.confTol = .1;
%     obj.tauTol = .5;
    obj.tauTol = obj.tres / 2;  % Base it on window size => resolving power
    
    obj.confRegularization = 2.5;   % Based on Gamma distribution estimate for MSE
        % If the error of one single frequency bin (P1 - P2)^2 in (dB)^2
        % follows a normal distribution with mean 0 and variance sigma^2, 
        % then the MSE follows the distribution:
        % MSE ~ Gamma(n, 2sigma^2 / n), where n is the number of frequency
        % bins in the mean calculation. For a 44100Hz sampling frequency
        % and for frequencies under 10kHz, n =~ 12500 (although this
        % doesn't matter for expected value).
        %
        % From measurements, sigma seems to hover in the range of 0.65-0.8
        % at points where the left and right spectra are similar (match).
        % Hence, E(MSE) is around 0.845-1.28. Double this to be safe, to 
        % get a value of around 2.5.
    
    obj.timeBuffer = 4;
    
    obj.isFade = false;
    
    obj.r_tau = 1;  % Estimates should be within +-1 second (default)
    obj.r_t1 = 1;
    obj.r_t2 = 1;

    obj.p_tau = 0;  % Within the estimate range, all values should be weighted equally (default)
    obj.p_t1 = 0;
    obj.p_t2 = 0;
end