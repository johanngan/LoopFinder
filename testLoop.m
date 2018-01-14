function testLoop(obj, i, l, timeBuffer, t1, t2)
    if(nargin < 4)
        timeBuffer = obj.timeBuffer;
    end
    
    if(nargin < 3)
        l = 1;
    end

    if(nargin < 2)
        i = 1;
    end
    
    manual = false;
    if(nargin < 6)
        t1 = obj.t1s{i}(l);
        t2 = obj.t2s{i}(l);
        
        s1 = obj.s1s{i}(l);
        s2 = obj.s2s{i}(l);
    else
        fprintf('\nMANUAL LOOP ENTRY:');
        manual = true;
        
        s1 = obj.findSample(t1);
        s2 = obj.findSample(t2);
    end
    
    fprintf('\nLoop endpoints: [%f, %f]', t1, t2);
    fprintf('\nLoop duration: %fs', t2-t1);
    
    if(~manual)
        fprintf('\nConfidence level: %f%%', 100*obj.confs(i));
    end
    fprintf('\n\nTesting loop...\n');
    
%     lag = s2 - s1;
    sampleBuffer = round(timeBuffer * obj.Fs);
    l1 = max(1, s2 - sampleBuffer);
    l2 = s2;
    l3 = max(2, s1);
    l4 = min(obj.l, s1 + sampleBuffer);
    
    % Assemble the audio clip for seamless playback
    audioclip = [obj.audio(l1:l2, :); obj.audio(l3-1:l4, :)];
    
    p = audioplayer(audioclip, obj.Fs);
    p.play;
    pause((l2-l1)/obj.Fs);  % Pause for just the right amount of time
    fprintf('Looping...\n\n');
    pause((l4-l3+1)/obj.Fs);    % Pause until the playback ends
    
%     p.playblocking([l1, l2]);
%     fprintf('Looping...\n\n');
%     p.playblocking([l3, l4]);
end