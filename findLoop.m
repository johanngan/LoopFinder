function [t1, t2, c] = findLoop(obj)
% Finds the obj.nBest start and end times for seamless looping of an audio 
% track, as well as the relative confidence levels of each.
%
% INTERNAL LOOP POINT RESULT FIELDS ARE CHANGED WHEN THIS METHOD IS CALLED.

    % Initial selection via normalized MSres
    msres = obj.MSres();
    sLeftIgnore = round(obj.leftIgnore*obj.Fs);
    sRightIgnore = round(obj.rightIgnore*obj.Fs);
    [~, i1] = obj.nMinCluster(msres(1+sLeftIgnore:end-sRightIgnore));
    obj.lags = i1+sLeftIgnore-1;
    
    % Ranking by spectrum MSE
    obj.mses = zeros(1, obj.nBest);
    obj.s1s = zeros(size(obj.mses));
    obj.sDiffs = zeros(size(obj.mses));
    
    for j = 1:obj.nBest
        [obj.lags(j), obj.mses(j), obj.s1s(j), obj.sDiffs(j)] = ...
            obj.spectrumMSE(obj.lags(j));
    end
    
    [obj.mses, i2] = sort(obj.mses, 'ascend');
    obj.lags = obj.lags(i2);
    obj.s1s = obj.s1s(i2);
    obj.sDiffs = obj.sDiffs(i2);
    obj.confs = obj.calcConfidence(obj.mses);
    
    
    % Re-ordering based on MSres for times that are very close in
    % confidence AND lag value
    iClose = find(abs(obj.confs - obj.confs(1)) <= obj.confTol & ...
        abs(obj.s1s - obj.s1s(1)) <= obj.tauTol*obj.Fs);
    [~, reorder] = sort(i2(iClose), 'ascend');
    obj.mses(iClose) = obj.mses(reorder);
    obj.lags(iClose) = obj.lags(reorder);
    obj.s1s(iClose) = obj.s1s(reorder);
    obj.sDiffs(iClose) = obj.sDiffs(reorder);
%     obj.confs(iClose) = obj.confs(reorder); DON'T DO THIS

    obj.s2s = obj.s1s + obj.lags;

    t1 = obj.findTime(obj.s1s);
    t2 = obj.findTime(obj.s2s);
    c = obj.confs;
end