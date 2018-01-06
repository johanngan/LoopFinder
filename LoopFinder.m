% Finds seamless loop points for audio signals

classdef LoopFinder < handle
    properties
        % Data
        audio
        Fs
        avgVol
        
        % Loop selection parameters
        leftIgnore  % In seconds
        rightIgnore
        nBest
        sDiffTol    % For loop start and end points
        
        % Loop point results
        lags
        s1s
        s2s
        mses
        wastages    % In seconds
        matchLengths    % In seconds
        rawMSres    % Normalized by noise level, but not by overlap width
        nMSres      % Normalized by both noise level and overlap width
        confs
        sDiffs

        % Chunking parameters
        minLoopLength
        tres    % Windowing size for spectrograms
        overlapPercent  % Window overlap for spectrograms
        
        % Clustering parameters
        minTDiff    % For non-maximum suppression for nBest selection from MSres values
        dBLevel     % Decibel level to set the mean volume of audio to. Anything differences where the audio is below 0 dB will be ignored.
            powRef  % Reference level for decibel calculation
        minRangeCutoff  % Minimum percentage of the range of values for finding low-difference regions in spectrum MSE
        maxRangeCutoff  % Maximum percentage. See above.
        incRangeCutoff  % Increment for percentage if current level is too stringent. See above.
        cutoffRad   % Multiple of the median of range-selected region to use for a cutoff value.
        
        confTol     % Confidence difference between values to use for reordering among ranked lag values
        tauTol  % Lag time difference (in seconds). See above.
        
        % Ranking parameters
        confRegularization  % Regularization for denominator in confidence value calculation.
        
        % Manual estimation parameters
        tau_est     % REMOVE THIS
        t1_est
        t2_est
        
        r_tau   % Search window
        r_t1
        r_t2
        
        p_tau   % Penalty magnitude (0-1)
        p_t1
        p_t2
        
        % Loop playback parameters
        timeBuffer  % Number of seconds before the loop end to begin playback, and after the loop start to end playback.
        
        % Spectrogram visualization
        SVspectrograms
        SVF
        SVS
        SVleft
        SVright
        SVcutoff
        SVcutoff2
        SVoldlags
        SVspecDiff
        
        fadeRemoved     % Internal flag
        isFade  % Configuration flag to specify that the track has a fade
    end
    
    properties(Dependent)
        % Data
        l           % Number of samples
        duration    % Length of audio in seconds
        nChannels
        
        % Chunking
        stride  % Strides for spectrogram windows, in seconds
        
        % Loop point results
        taus    % Loop lengths in seconds
        t1s     % Loop start points in seconds
        t2s     % Loop end points in seconds
        
        % Estimation and sensitivity
        loopMode    % 0 for no manual estimation, 1 for double endpoint estimation, 
                    % 2 for left endpoint estimation, 3 for right endpoint estimation
        
        s1_est
        s2_est
        
        m_tau   % Slopes for triangular weighting, per second deviation
        m_t1
        m_t2
        
        tauLims     % Range of acceptable values for tau, t1, t2
        t1Lims
        t2Lims
    end
    
    methods(Access = private)
        time = findTime(obj, sample)
        sample = findSample(obj, time)
        db = powToDB(obj, p)
        
        removeFade(obj)
        
        L = MSres(obj)  % Normalized residual mean square error over lags
        L = MSresNotAuto(obj, audio1, audio2)   % Normalized MSres between two different audio clips
        
        [vals, idx] = nMinCluster(obj, x)
        
        ys = smoothen(obj, y, rAvg)
        [F, X] = calcSpectrum(obj, x, fmin, fmax)
        [P, F, S, ds, sSize] = calcSpectrogram(obj, x)
        
        specDiff = diffSpectra(obj, X1, X2)
        specDiffs = diffSpectrogram(obj, P1, P2)
        [left, right, cutoff, cutoff2] = findBestCluster(obj, specDiff, sSize)
        w = calcWastage(obj, specDiff, sSize, left, right, cutoff)
        l = calcMatchLength(obj, specDiff, sSize, left, right, cutoff)
        [lag, L] = refineLag(obj, lag, left, right);
        [lag, s1, sDiff] = findLoopPoint(obj, lag, s1s)
        [lag, s1, sDiff] = findLoopPointSpecDiff(obj, lag, specDiff, left, right, S, ds)
        
        [lag, L, s1, sDiff, wastage, matchLength, ...
            spectrograms, F, S, left, right, cutoff, cutoff2, oldlags, specDiff] ...
            = spectrumMSE(obj, lag)
        c = calcConfidence(obj, mseVals, reg)
        
        
        [t1, t2, c] = findLoopEstEndpoints(obj)
        [t1, t2, c] = findLoopEstLeftEndpoint(obj)
        [t1, t2, c] = findLoopEstRightEndpoint(obj)
    end
    
    methods     % Public methods
        % ctor
        function obj = LoopFinder(audio, Fs)
            addpath('../util');
            addpath('wavematch/cxcorr_fft');
            addpath('tracks');
            
            if(nargin == 1)
                [audio, Fs] = audioread(audio);
            end
            
            if(nargin < 1)
                audio = [];
                Fs = [];
            end
            
            obj.lags = [];
            obj.s1s = [];
            obj.s2s = [];
            obj.mses = [];
            obj.confs = [];
            obj.sDiffs = [];
            obj.wastages = [];
            obj.matchLengths = [];
            obj.rawMSres = [];
            
            obj.tau_est = [];
            obj.t1_est = [];
            obj.t2_est = [];
            
%             obj.r_tau = [];
%             obj.r_t1 = [];
%             obj.r_t2 = [];
%             
%             obj.p_tau = [];
%             obj.p_t1 = [];
%             obj.p_t2 = [];
            
            obj.SVspectrograms = {};
            obj.SVF = {};
            obj.SVS = {};
            obj.SVleft = {};
            obj.SVright = {};
            obj.SVcutoff = {};
            obj.SVcutoff2 = {};
            obj.SVoldlags = {};
            obj.SVspecDiff = {};
            
            obj.useDefaultParams();
            obj.loadAudio(audio, Fs);
        end
        
        
        
        
        
        % Setters
        function loadAudio(obj, audio, Fs)
            if(any(size(audio) ~= size(obj.audio)) || ...
               ~all(all(audio == obj.audio)))
                obj.tau_est = [];
                obj.t1_est = [];
                obj.t2_est = [];
            end
            
            obj.audio = audio;
            obj.Fs = Fs;
            
            obj.avgVol = obj.powToDB(mean(sum(audio.^2, 2)));
            obj.fadeRemoved = false;
        end
        
        function readFile(obj, filename)
            [audioIn, FsIn] = audioread(filename);
            obj.loadAudio(audioIn, FsIn);
        end
        
        function set.leftIgnore(obj, leftIgnore)
            obj.leftIgnore = leftIgnore;
        end
        
        function set.rightIgnore(obj, rightIgnore)
            obj.rightIgnore = rightIgnore;
        end
        
        function setPadding(obj, pad)
            obj.leftIgnore = pad / 2;
            obj.rightIgnore = pad / 2;
        end
        
        function set.nBest(obj, nBest)
            obj.nBest = nBest;
        end
        
        function set.sDiffTol(obj, sDiffTol)
            obj.sDiffTol = sDiffTol;
        end
        
        function set.minLoopLength(obj, minLoopLength)
            obj.minLoopLength = minLoopLength;
        end
        
        function set.tres(obj, tres)
            obj.tres = tres;
        end
        
        function set.overlapPercent(obj, overlapPercent)
            obj.overlapPercent = overlapPercent;
        end
        
        function set.minTDiff(obj, minTDiff)
            obj.minTDiff = minTDiff;
        end
        
        function set.dBLevel(obj, dBLevel)
            obj.dBLevel = dBLevel;
        end
        
        function set.powRef(obj, powRef)
            obj.powRef = powRef;
            
            % Recalculate average volume level
            obj.avgVol = obj.powToDB(mean(sum(obj.audio.^2, 2)));
        end
        
        function set.minRangeCutoff(obj, minRangeCutoff)
            obj.minRangeCutoff = minRangeCutoff;
        end
        
        function set.maxRangeCutoff(obj, maxRangeCutoff)
            obj.maxRangeCutoff = maxRangeCutoff;
        end
        
        function set.incRangeCutoff(obj, incRangeCutoff)
            obj.incRangeCutoff = incRangeCutoff;
        end
        
        function set.cutoffRad(obj, cutoffRad)
            obj.cutoffRad = cutoffRad;
        end
        
        function set.confTol(obj, confTol)
            obj.confTol = confTol;
        end
        
        function set.tauTol(obj, tauTol)
            obj.tauTol = tauTol;
        end
        
        function set.confRegularization(obj, confRegularization)
            obj.confRegularization = confRegularization;
        end
        
        function set.tau_est(obj, tau_est)
            obj.tau_est = tau_est;
        end
        
        function set.t1_est(obj, t1_est)            
            obj.t1_est = t1_est;
        end
        
        function set.t2_est(obj, t2_est)
            obj.t2_est = t2_est;
        end
        
        function set.r_tau(obj, r_tau)
            obj.r_tau = r_tau;
        end
        
        function set.r_t1(obj, r_t1)
            obj.r_t1 = r_t1;
        end
        
        function set.r_t2(obj, r_t2)
            obj.r_t2 = r_t2;
        end
        
        function set.p_tau(obj, p_tau)
            if(p_tau < 0 || p_tau > 1)
                error('Penalty must be a number between 0 and 1.');
            end
            obj.p_tau = p_tau;
        end
        
        function set.p_t1(obj, p_t1)
            if(p_t1 < 0 || p_t1 > 1)
                error('Penalty must be a number between 0 and 1.');
            end
            obj.p_t1 = p_t1;
        end
        
        function set.p_t2(obj, p_t2)
            if(p_t2 < 0 || p_t2 > 1)
                error('Penalty must be a number between 0 and 1.');
            end
            obj.p_t2 = p_t2;
        end
        
        function set.timeBuffer(obj, timeBuffer)
            obj.timeBuffer = timeBuffer;
        end
        
        
        
        
        
        % Getters
        function audio = get.audio(obj)
            audio = obj.audio;
        end
        
        function Fs = get.Fs(obj)
            Fs = obj.Fs;
        end
        
        function leftIgnore = get.leftIgnore(obj)
            leftIgnore = obj.leftIgnore;
        end

        function rightIgnore = get.rightIgnore(obj)
            rightIgnore = obj.rightIgnore;
        end
        
        function nBest = get.nBest(obj)
            nBest = obj.nBest;
        end
        
        function sDiffTol = get.sDiffTol(obj)
            sDiffTol = obj.sDiffTol;
        end
        
        function lags = get.lags(obj)
            lags = obj.lags;
        end
        
        function s1s = get.s1s(obj)
            s1s = obj.s1s;
        end
        
        function s2s = get.s2s(obj)
            s2s = obj.s2s;
        end
        
        function mses = get.mses(obj)
            mses = obj.mses;
        end
        
        function confs = get.confs(obj)
            confs = obj.confs;
        end
        
        function sDiffs = get.sDiffs(obj)
            sDiffs = obj.sDiffs;
        end
        
        function minLoopLength = get.minLoopLength(obj)
            minLoopLength = obj.minLoopLength;
        end
        
        function tres = get.tres(obj)
            tres = obj.tres;
        end
        
        function overlapPercent = get.overlapPercent(obj)
            overlapPercent = obj.overlapPercent;
        end
        
        function minTDiff = get.minTDiff(obj)
            minTDiff = obj.minTDiff;
        end
        
        function dBLevel = get.dBLevel(obj)
            dBLevel = obj.dBLevel;
        end
        
        function minRangeCutoff = get.minRangeCutoff(obj)
            minRangeCutoff = obj.minRangeCutoff;
        end
        
        function maxRangeCutoff = get.maxRangeCutoff(obj)
            maxRangeCutoff = obj.maxRangeCutoff;
        end
        
        function incRangeCutoff = get.incRangeCutoff(obj)
            incRangeCutoff = obj.incRangeCutoff;
        end
        
        function cutoffRad = get.cutoffRad(obj)
            cutoffRad = obj.cutoffRad;
        end
        
        function confTol = get.confTol(obj)
            confTol = obj.confTol;
        end
        
        function tauTol = get.tauTol(obj)
            tauTol = obj.tauTol;
        end
        
        function confRegularization = get.confRegularization(obj)
            confRegularization = obj.confRegularization;
        end
        
        function tau_est = get.tau_est(obj)
            if(~isempty(obj.tau_est))
                tau_est = obj.tau_est;
            else
                tau_est = obj.t2_est - obj.t1_est;
            end
        end
        
        function t1_est = get.t1_est(obj)
            t1_est = obj.t1_est;
        end
        
        function t2_est = get.t2_est(obj)
            t2_est = obj.t2_est;
        end
        
        function tauLims = get.tauLims(obj)
            if(obj.loopMode == 1)
                tau = obj.t2_est - obj.t1_est;
            elseif(isempty(obj.tau_est))
                tauLims = [];
                return;
            else
                tau = obj.tau_est;
            end

            if(obj.p_tau == 1)
                tauLims = [tau, tau];
            elseif(obj.p_tau == 0)
                tauLims = [tau-obj.r_tau, tau+obj.r_tau];
            else
                tauLims = [...
                	max(tau-obj.r_tau, tau-1/obj.m_tau+1/obj.Fs), ...
                	min(tau+obj.r_tau, tau+1/obj.m_tau-1/obj.Fs)];
            end
        end
        
        function t1Lims = get.t1Lims(obj)
            if(isempty(obj.t1_est))
                if(isempty(obj.t2_est))
                    t1Lims = [];
                else
                    t1Lims = [0, max(0, obj.t2Lims(2)-obj.minLoopLength)];
                end
                
                return;
            end
            
            if(obj.p_t1 == 1)
                t1Lims = [obj.t1_est, obj.t1_est];
            elseif(obj.p_t1 == 0)
                t1Lims = [obj.t1_est-obj.r_t1, obj.t1_est+obj.r_t1];
            else
                t1Lims = [...
                    max(obj.t1_est-obj.r_t1, obj.t1_est-1/obj.m_t1+1/obj.Fs), ...
                	min(obj.t1_est+obj.r_t1, obj.t1_est+1/obj.m_t1-1/obj.Fs)];
            end
        end
        
        function t2Lims = get.t2Lims(obj)
            if(isempty(obj.t2_est))
                if(isempty(obj.t1_est))
                    t2Lims = [];
                else
                    t2Lims = [min(obj.duration, obj.t1Lims(1)+obj.minLoopLength), ...
                        obj.duration];
                end
                
                return;
            end
            
            if(obj.p_t2 == 1)
                t2Lims = [obj.t2_est, obj.t2_est];
            elseif(obj.p_t2 == 0)
                t2Lims = [obj.t2_est-obj.r_t2, obj.t2_est+obj.r_t2];
            else
                t2Lims = [...
                    max(obj.t2_est-obj.r_t2, obj.t2_est-1/obj.m_t2+1/obj.Fs), ...
                	min(obj.t2_est+obj.r_t2, obj.t2_est+1/obj.m_t2-1/obj.Fs)];
            end
        end
        
        function s1_est = get.s1_est(obj)
            s1_est = obj.findSample(obj.t1_est);
        end
        
        function s2_est = get.s2_est(obj)
            s2_est = obj.findSample(obj.t2_est);
        end
        
        function r_tau = get.r_tau(obj)
            r_tau = obj.r_tau;
        end
        
        function r_t1 = get.r_t1(obj)
            r_t1 = obj.r_t1;
        end
        
        function r_t2 = get.r_t2(obj)
            r_t2 = obj.r_t2;
        end
        
        function p_tau = get.p_tau(obj)
            p_tau = obj.p_tau;
        end
        
        function p_t1 = get.p_t1(obj)
            p_t1 = obj.p_t1;
        end
        
        function p_t2 = get.p_t2(obj)
            p_t2 = obj.p_t2;
        end
        
        function m_tau = get.m_tau(obj)
            m_tau = tand(obj.p_tau * 90);
        end
        
        function m_t1 = get.m_t1(obj)
            m_t1 = tand(obj.p_t1 * 90);
        end
        
        function m_t2 = get.m_t2(obj)
            m_t2 = tand(obj.p_t2 * 90);
        end
        
        function timeBuffer = get.timeBuffer(obj)
            timeBuffer = obj.timeBuffer;
        end
        
        function l = get.l(obj)
            l = size(obj.audio, 1);
        end
        
        function duration = get.duration(obj)
            duration = obj.l / obj.Fs;
        end
        
        function nChannels = get.nChannels(obj)
            nChannels = size(obj.audio, 2);
        end
        
        function taus = get.taus(obj)
            taus = obj.lags / obj.Fs;
        end
        
        function t1s = get.t1s(obj)
            t1s = obj.findTime(obj.s1s);
        end
        
        function t2s = get.t2s(obj)
            t2s = obj.findTime(obj.s2s);
        end
        
        function stride = get.stride(obj)
            stride = obj.tres * (1 - obj.overlapPercent/100);
        end
        
        function loopMode = get.loopMode(obj)
            if(~isempty(obj.t1_est) && ~isempty(obj.t2_est))
                loopMode = 1;
                return;
            end

            if(~isempty(obj.t1_est) && isempty(obj.t2_est))
                loopMode = 2;
                return;
            end

            if(isempty(obj.t1_est) && ~isempty(obj.t2_est))
                loopMode = 3;
                return;
            end
            
            loopMode = 0;
        end
        
        
        
        
        useDefaultParams(obj)
        [t1, t2, c] = findLoop(obj)
        [t1, t2, c] = loop(obj, filename)
        testLoop(obj, i, timeBuffer, t1, t2)
        fullPlayback(obj)
        specVis(obj, i, c)
        waveVis(obj, i, c)
        fadeLength = detectFade(obj, audio, Fs)
    end
end