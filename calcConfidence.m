function c = calcConfidence(obj, mseVals, reg)
% Calculates confidence levels given a vector of MSE values

    if(nargin < 3)
        reg = obj.confRegularization;
    end

%     invMse = 1./(mseVals + obj.confRegularization);
    invMse = 1./(exp(mseVals)-1 + exp(reg)-1);
    c = invMse / sum(invMse(~isnan(invMse)));
    
    c(isinf(invMse)) = 1;
end