function [t1, t2, c] = findLoop(obj)
% Finds the obj.nBest start and end times for seamless looping of an audio 
% track, as well as the relative confidence levels of each.
%
% INTERNAL LOOP POINT RESULT FIELDS ARE CHANGED WHEN THIS METHOD IS CALLED.

    % Remove fade if needed
    if(obj.isFade && ~obj.fadeRemoved)
        obj.removeFade();
    end
    
    % Use the endpoint estimates if given
    if(obj.loopMode ~= 0)
        [t1, t2, c] = obj.findLoopEstEndpoints();
        return;
    end
%     switch(obj.loopMode)
%         case 1
%             [t1, t2, c] = obj.findLoopEstEndpoints();
%             return;
%         case 2
%             [t1, t2, c] = obj.findLoopEstLeftEndpoint();
%             return;
%         case 3
%             [t1, t2, c] = obj.findLoopEstRightEndpoint();
%             return;
%     end

    % Execute mode 0...
    
    % Initial selection via normalized MSres
    msres = obj.MSres();
    sLeftIgnore = round(obj.leftIgnore*obj.Fs);
    sRightIgnore = round(obj.rightIgnore*obj.Fs);
    [~, i1] = obj.nMinCluster(msres(1+sLeftIgnore:end-sRightIgnore), obj.nBest);
    obj.baseLags = i1+sLeftIgnore-1;
    
    % Non-length-normalized and length-normalized MSres values for the best lags
    obj.nMSres = msres(i1+sLeftIgnore);
    obj.rawMSres = obj.nMSres .* (obj.l - obj.baseLags);
    
    % Ranking by spectrum MSE
    obj.mses = zeros(1, obj.nBest);
    obj.lags = cell(size(obj.mses));
    obj.s1s = cell(size(obj.mses));
    obj.sDiffs = cell(size(obj.mses));
    obj.wastages = zeros(size(obj.mses));
    obj.matchLengths = zeros(size(obj.mses));
    
    obj.SVspectrograms = cell(size(obj.mses));
    obj.SVF = cell(size(obj.mses));
    obj.SVS = cell(size(obj.mses));
    obj.SVleft = cell(size(obj.mses));
    obj.SVright = cell(size(obj.mses));
    obj.SVoldlags = cell(size(obj.mses));
    obj.SVspecDiff = cell(size(obj.mses));
    obj.SVcutoff = cell(size(obj.mses));
    obj.SVcutoff2 = cell(size(obj.mses));
    
    for j = 1:obj.nBest
        [obj.lags{j}, obj.mses(j), obj.s1s{j}, obj.sDiffs{j}, obj.wastages(j), obj.matchLengths(j), ...
         obj.SVspectrograms{j}, obj.SVF{j}, obj.SVS{j}, ...
         obj.SVleft{j}, obj.SVright{j}, obj.SVcutoff{j}, obj.SVcutoff2{j}, ...
         obj.SVoldlags{j}, obj.SVspecDiff{j}] = ...
            obj.spectrumMSE(obj.baseLags(j));
    end
    
    for b = 1:length(obj.lags)
        obj.baseLags(b) = obj.lags{b}(1);
    end
    
%     [obj.mses, i2] = sort(obj.mses, 'ascend');
    [~, i2] = sort(obj.mses, 'ascend');
    permuteRankings(obj, [], i2, false);
%     obj.lags = obj.lags(i2);
%     obj.s1s = obj.s1s(i2);
%     obj.sDiffs = obj.sDiffs(i2);
%     obj.wastages = obj.wastages(i2);
%     obj.rawMSres = obj.rawMSres(i2);
%     obj.nMSres = obj.nMSres(i2);
%     
%     obj.SVspectrograms = obj.SVspectrograms(i2);
%     obj.SVF = obj.SVF(i2);
%     obj.SVS = obj.SVS(i2);
%     obj.SVleft = obj.SVleft(i2);
%     obj.SVright = obj.SVright(i2);
%     obj.SVoldlags = obj.SVoldlags(i2);
%     obj.SVspecDiff = obj.SVspecDiff(i2);
    obj.confs = obj.calcConfidence(obj.mses);
    
    
     % Re-ordering based on wastage for times that are of relatively high 
     % importance (top 95%). CHANGE: reordering based on match length AND
     % wastage
    confBand = .95;
    mseMult = 2;    % TO TRY: 1.5 again?
    
    
%     iTop = 1:find(cumsum(obj.confs) >= confBand, 1);
    iTop = find(obj.mses <= mseMult*obj.mses(1));
%     iTop = find(obj.mses.*obj.nMSres <= mseMult*obj.mses(1)*obj.nMSres(1)); % TO TRY... or don't
        
%     [~, ranks] = sort(obj.wastages(iTop), 'ascend');
    
%     [~, ranks] = sort(obj.matchLengths(iTop) - obj.wastages(iTop), 'descend');
%     permuteRankings(obj, iTop, ranks, true);

    % To try: if any of the top has wastage within 3*obj.stride of the top,
    % reorder those by the matchLength - wastage
    [~, ranks] = sort(obj.wastages(iTop), 'ascend');
    permuteRankings(obj, iTop, ranks, true);
    
    iTop2 = find(obj.wastages(iTop) - obj.wastages(iTop(1)) <= 3*obj.stride);
    [~, ranks2] = sort(obj.matchLengths(iTop(iTop2)) - obj.wastages(iTop(iTop2)), 'descend');
    permuteRankings(obj, iTop(iTop2), iTop(ranks2), true);
    
    % TO TRY: also prefer larger lag values, but put more emphasis on matchLength and wastage
    % Use a stable sort to settle ties
    matchLengthWeight = 1;    % Multiplicative weights
    wastageWeight = 1;
    lagWeight = 0.9;

    [~, ranks3] = sort(...
        obj.matchLengths(iTop(iTop2)) * matchLengthWeight - ...
        obj.wastages(iTop(iTop2)) * wastageWeight + ...
        obj.baseTaus(iTop(iTop2)) * lagWeight, ...
        'descend');
    permuteRankings(obj, iTop(iTop2), iTop(ranks3), true);

    



    % Re-ordering based on MSres for times if relatively high importance 
    % that are very close in lag value
    
%     iClose = find(abs(obj.confs - obj.confs(1)) <= obj.confTol & ...
%         abs(obj.s1s - obj.s1s(1)) <= obj.tauTol*obj.Fs);  % This should
%         definitely be obj.lags, not obj.s1s...

%     newiTop = 1:find(cumsum(obj.confs) >= confBand, 1);
    newiTop = find(obj.mses <= mseMult*obj.mses(1));
%     newiTop = find(obj.mses.*obj.nMSres <= mseMult*obj.mses(1)*obj.nMSres(1)); % TO TRY... or don't
    
%     iClose = find(abs(obj.s1s(newiTop) - obj.s1s(1)) <= obj.tauTol*obj.Fs);


    iFar = newiTop;
    
    while(length(iFar) > 1)
        iClose = iFar(abs(obj.baseLags(newiTop(iFar)) - obj.baseLags(iFar(1))) <= obj.tauTol*obj.Fs);
        iFar = setdiff(iFar, iClose);
        
    %     [~, reorder] = sort(i2(iClose), 'ascend');
%         [~, reorder] = sort(obj.nMSres(iClose), 'ascend');
        [~, reorder] = sort(obj.nMSres(iClose).*obj.mses(iClose), 'ascend');
        permuteRankings(obj, iClose, iClose(reorder), false);
    end
    obj.confs = sort(obj.confs, 'descend');  % Restore descending order
    
%     obj.mses(iClose) = obj.mses(reorder);
%     obj.lags(iClose) = obj.lags(reorder);
%     obj.s1s(iClose) = obj.s1s(reorder);
%     obj.sDiffs(iClose) = obj.sDiffs(reorder);
%     obj.wastages(iClose) = obj.wastages(reorder);
%     obj.rawMSres(iClose) = obj.rawMSres(iClose);
%     obj.nMSres(iClose) = obj.nMSres(iClose);
%     
%     obj.SVspectrograms(iClose) = obj.SVspectrograms(reorder);
%     obj.SVF(iClose) = obj.SVF(reorder);
%     obj.SVS(iClose) = obj.SVS(reorder);
%     obj.SVleft(iClose) = obj.SVleft(reorder);
%     obj.SVright(iClose) = obj.SVright(reorder);
%     obj.SVoldlags(iClose) = obj.SVoldlags(reorder);
%     obj.SVspecDiff(iClose) = obj.SVspecDiff(reorder);
% %     obj.confs(iClose) = obj.confs(reorder); DON'T DO THIS

    obj.s2s = cell(size(obj.s1s));
    t1 = zeros(size(obj.s1s));
    t2 = zeros(size(t1));
    for tau = 1:length(obj.s1s)
        obj.s2s{tau} = obj.s1s{tau} + obj.lags{tau};
        
        t1(tau) = obj.findTime(obj.s1s{tau}(1));
        t2(tau) = obj.findTime(obj.s1s{tau}(1));
    end

    c = obj.confs;
end

function permuteRankings(obj, i, f, permuteConf)
% permute indices specified by i to indices specified by f

    if(nargin < 4)
        permuteConf = true;
    end
    
    if(isempty(i))
        i = 1:length(f);
    end

    obj.mses(i) = obj.mses(f);
    obj.baseLags(i) = obj.baseLags(f);
%     obj.lags(i) = obj.lags(f);
%     obj.s1s(i) = obj.s1s(f);
%     obj.sDiffs(i) = obj.sDiffs(f);
    store_lags = obj.lags;
    store_s1s = obj.s1s;
    store_sDiffs = obj.sDiffs;
    for entry = 1:length(i)
        obj.lags{i(entry)} = store_lags{f(entry)};
        obj.s1s{i(entry)} = store_s1s{f(entry)};
        obj.sDiffs{i(entry)} = store_sDiffs{f(entry)};
    end
    obj.wastages(i) = obj.wastages(f);
    obj.matchLengths(i) = obj.matchLengths(f);
    obj.rawMSres(i) = obj.rawMSres(f);
    obj.nMSres(i) = obj.nMSres(f);
    
    obj.SVspectrograms(i) = obj.SVspectrograms(f);
    obj.SVF(i) = obj.SVF(f);
    obj.SVS(i) = obj.SVS(f);
    obj.SVleft(i) = obj.SVleft(f);
    obj.SVright(i) = obj.SVright(f);
    obj.SVoldlags(i) = obj.SVoldlags(f);
    obj.SVspecDiff(i) = obj.SVspecDiff(f);
    obj.SVcutoff(i) = obj.SVcutoff(f);
    obj.SVcutoff2(i) = obj.SVcutoff2(f);
    
    if(permuteConf)
        obj.confs(i) = obj.confs(f);
    end
end