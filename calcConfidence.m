function c = calcConfidence(obj, mseVals)
% Calculates confidence levels given a vector of MSE values

%     invMse = 1./(mseVals + obj.confRegularization);
    invMse = 1./(exp(mseVals)-1 + exp(obj.confRegularization)-1);
    c = invMse / sum(invMse(~isnan(invMse)));
    
    c(isinf(invMse)) = 1;
end