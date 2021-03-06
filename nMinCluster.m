function [vals, idx] = nMinCluster(obj, x, n)
% Returns the n minimum elements of x, where the indices are
% separated by at least obj.minTDiff*obj.Fs

    if(obj.nBest < 0)
        error('nBest must a nonnegative integer');
    end
    
    if(n == 0)
        vals = [];
        idx = [];
        return;
    end

    % If n = 1, just use the min function
    if(n == 1)
        [vals, idx] = min(x);
        return;
    end

    if(iscolumn(x))
        x = x';
    end
    
    [x, i] = sort(x, 'ascend');
    
    vals = x(1);
    idx = i(1);    % Column until returned
    
    for j = 2:n
        maxj = find(all(abs(i - idx) >= obj.minTDiff*obj.Fs, 1), 1);
        if(maxj)
            idx = [idx; i(maxj)];
            vals = [vals, x(maxj)];
        else
            break;
        end
    end
    
    idx = idx';
end