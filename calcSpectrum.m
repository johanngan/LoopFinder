function [F, X] = calcSpectrum(obj, x, fmin, fmax)
% Computes the one-sided spectrum of a real signal x at sampling frequency
% obj.Fs. Only amplitude information is used. Phase information is discarded.
%
% F is the frequency range
% X is the corresponding normalized power
%
% Input x should have a power-of-two length
    if(nargin < 4)
        fmax = inf;
    end
    
    if(nargin < 3)
        fmin = 0;
    end

    L = length(x);
    
    Y = fft(x);
    P2 = abs(Y/L);
    X = P2(1:floor(L/2)+1);
        % L even: X = P2(1:L/2 + 1);
        % L odd: X = P2(1:(L-1)/2 + 1);
    X(2:end-1 + mod(L, 2)) = 2*X(2:end-1 + mod(L, 2));
        % L even: X(2:end-1) = 2*X(2:end-1);
        % L odd: X(2:end) = 2*X(2:end);
    F = obj.Fs*(0:floor(L/2))/L;
        % L even: F = obj.Fs*(0:L/2)/L;
        % L odd: F = obj.Fs*(0:(L-1)/2)/L;
        
    % Frequency bandwidth
    r = find(F >= fmin & F <= fmax);
    F = F(r)';
    X = X(r);
    X = obj.smoothen(X, round(length(X)/1024));
end

% function ys = smoothen(y, rAvg)
% % rAvg is the radius around each point to average
% 
%     l = length(y);
%     ys = zeros(size(y));
%     
% %     for i = 1:l
% %         ys(i) = mean(y(max(i-rAvg, 1):min(i+rAvg, l)));
% %     end
%     
%     top = sum(y(1:min(rAvg, l)));
%     bottom = min(rAvg, l);
%     for i = 1:l
%         right = i+rAvg;
%         left = i-rAvg;
%         
%         if(right <= l)
%             top = top + y(right);
%             bottom = bottom + 1;
%         end
%         
%         if(left > 1)
%             top = top - y(left-1);
%             bottom = bottom - 1;
%         end
%         
%         ys(i) = top / bottom;
%     end
% end