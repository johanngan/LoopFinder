function testLoop(obj, i)
    if(nargin < 2)
        i = 1;
    end

    fprintf('\nLoop endpoints: [%f, %f]', obj.t1s(i), obj.t2s(i));
    fprintf('\nLoop duration: %fs', obj.taus(i));
    fprintf('\nConfidence level: %f%%\n', 100*obj.confs(i));
    fprintf('\nTesting loop...\n');
    
    p = audioplayer(obj.audio, obj.Fs);
    
    sampleBuffer = round(obj.timeBuffer * obj.Fs);
    l1 = max(1, obj.s1s(i) + obj.lags(i) - sampleBuffer);
    l2 = obj.s1s(i) + obj.lags(i);
    l3 = obj.s1s(i);
    l4 = min(obj.l, obj.s1s(i) + sampleBuffer);
    
    p.playblocking([l1, l2]);
    fprintf('Looping...\n\n');
    p.playblocking([l3, l4]);
end