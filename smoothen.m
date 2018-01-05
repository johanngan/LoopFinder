function ys = smoothen(obj, y, rAvg)
% rAvg is the radius around each point to average
    if(nargin < 3)
        rAvg = 2;
    end

    l = length(y);
    ys = zeros(size(y));
    
%     for i = 1:l
%         ys(i) = mean(y(max(i-rAvg, 1):min(i+rAvg, l)));
%     end
    
    top = sum(y(1:min(rAvg, l)));
    bottom = min(rAvg, l);
    for i = 1:l
        right = i+rAvg;
        left = i-rAvg;
        
        if(right <= l)
            top = top + y(right);
            bottom = bottom + 1;
        end
        
        if(left > 1)
            top = top - y(left-1);
            bottom = bottom - 1;
        end
        
        ys(i) = top / bottom;
    end
end