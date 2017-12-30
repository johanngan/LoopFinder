% Finds seamless loop points for audio signals

classdef LoopFinder < handle
    properties
        % Data
        audio
        Fs
        
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
        tau_est
        t1_est
        t2_est
        
        r_tau   % Search window
        r_t1
        r_t2
        
        m_tau   % Penalty magnitude
        m_t1
        m_t2
        
        % Loop playback parameters
        timeBuffer  % Number of seconds before the loop end to begin playback, and after the loop start to end playback.
        
        % Spectrogram visualization
        SVspectrograms
        SVF
        SVS
        SVleft
        SVright
        SVoldlags
        SVspecDiff
    end
    
    properties(Dependent)
        % Data
        l           % Number of samples
        duration    % Length of audio in seconds
        nChannels
        
        % Loop point results
        taus    % Loop lengths in seconds
        t1s     % Loop start points in seconds
        t2s     % Loop end points in seconds
    end
    
    methods(Access = private)
        time = findTime(obj, sample)
        sample = findSample(obj, time)
        db = powToDB(obj, p)
        
        L = MSres(obj)  % Normalized residual mean square error over lags
        
        [vals, idx] = nMinCluster(obj, x)
        
        [F, X] = calcSpectrum(obj, x, fmin, fmax)
        [P, F, S, ds] = calcSpectrogram(obj, x)
        
        specDiff = diffSpectra(obj, X1, X2)
        specDiffs = diffSpectrogram(obj, P1, P2)
        [left, right] = findBestCluster(obj, specDiff, ds)
        [lag, L] = refineLag(obj, lag, left, right);
        [lag, s1, sDiff] = findLoopPoint(obj, lag, specDiff, left, right, S, ds)
        
        [lag, L, s1, sDiff, spectrograms, F, S, left, right, oldlags, specDiff] = spectrumMSE(obj, lag)
        c = calcConfidence(obj, mseVals)
    end
    
    methods     % Public methods
        % ctor
        function obj = LoopFinder(audio, Fs)
            if(nargin < 2)
                audio = [];
                Fs = [];
            end
            
            obj.audio = audio;
            obj.Fs = Fs;
            
            obj.lags = [];
            obj.s1s = [];
            obj.s2s = [];
            obj.mses = [];
            obj.confs = [];
            obj.sDiffs = [];
            
            obj.tau_est = [];
            obj.t1_est = [];
            obj.t2_est = [];
            
            obj.r_tau = [];
            obj.r_t1 = [];
            obj.r_t2 = [];
            
            obj.m_tau = [];
            obj.m_t1 = [];
            obj.m_t2 = [];
            
            obj.SVspectrograms = {};
            obj.SVF = {};
            obj.SVS = {};
            obj.SVleft = {};
            obj.SVright = {};
            obj.SVoldlags = {};
            obj.SVspecDiff = {};
            
            obj.useDefaultParams();
        end
        
        
        
        
        
        % Setters
        function loadAudio(obj, audio, Fs)            
            obj.audio = audio;
            obj.Fs = Fs;
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
        
        function set.m_tau(obj, m_tau)
            obj.m_tau = m_tau;
        end
        
        function set.m_t1(obj, m_t1)
            obj.m_t1 = m_t1;
        end
        
        function set.m_t2(obj, m_t2)
            obj.m_t2 = m_t2;
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
            tau_est = obj.tau_est;
        end
        
        function t1_est = get.t1_est(obj)
            t1_est = obj.t1_est;
        end
        
        function t2_est = get.t2_est(obj)
            t2_est = obj.t2_est;
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
        
        function m_tau = get.m_tau(obj)
            m_tau = obj.m_tau;
        end
        
        function m_t1 = get.m_t1(obj)
            m_t1 = obj.m_t1;
        end
        
        function m_t2 = get.m_t2(obj)
            m_t2 = obj.m_t2;
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
        
        
        
        
        
        useDefaultParams(obj)
        [t1, t2, c] = findLoop(obj)
        testLoop(obj, i)
        fullPlayback(obj)
        specVis(obj, i, c)
    end
end