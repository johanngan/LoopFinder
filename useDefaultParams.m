function useDefaultParams(obj)
    obj.leftIgnore = 5;
    obj.rightIgnore = 5;
    obj.nBest = 15;
%     obj.sDiffTol = inf;
    obj.sDiffTol = .05;
    
    obj.minLoopLength = 5;
    obj.tres = 2.5;
    obj.overlapPercent = 50;
    
    obj.minTDiff = .1;
    obj.dBLevel = 70;
        obj.powRef = 1e-12; % Standard reference level
    obj.minRangeCutoff = .05;
    obj.maxRangeCutoff = .25;
    obj.incRangeCutoff = .05;
    obj.cutoffRad = 2;
    
    obj.confTol = .1;
    obj.tauTol = .5;
    
    obj.confRegularization = .5;
    
    obj.timeBuffer = 4;
end