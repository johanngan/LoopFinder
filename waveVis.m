function waveVis(obj, i, l, c)
% Visualize the waveform comparison of the ith best lag value, for the
% cth channel. If c is not 1 or 2, then both channels will be used. i
% defaults to 1.

    if(nargin < 4)
        c = 0;
    end
    
    if(nargin < 3)
        l = 1;
    end
    
    if(nargin < 2)
        i = 1;
    end
    
    clf;
    
    invert = true;
    key = " ";
    
    while(key ~= "esc" && key ~= "q" && key ~= "bksp" && key ~= "ctrl-c")
        invert = ~invert;
        
        switch(c)
            case 0
                subplot(1, 2, 1);
                drawWave(obj, i, l, 1, invert);

                subplot(1, 2, 2);
                drawWave(obj, i, l, 2, invert);
            case 1
                drawWave(obj, i, l, 1, invert);
            case 2
                drawWave(obj, i, l, 2, invert);
        end

        key = string(readkey('InputType', 'keyboard', 'ValidInputs', ...
                    {'left', 'right', 'up', 'down', ' ', 'enter', 'tab', ...
                    'esc', 'q', 'bksp', 'ctrl-c'}));
    end
end

function drawWave(obj, i, l, channel, invert)
    if(nargin < 4)
        invert = false;
    end

    lag = obj.lags{i}(l);
    samps = 1:obj.l-lag;
    times = obj.findTime(samps);
    
    blue = [0, 0.4470, 0.7410];
    orange = [0.8500, 0.3250, 0.0980];
    if(invert)
        plot(times, obj.audio(samps+lag, channel), 'color', orange);
        hold on;
        plot(times, obj.audio(samps, channel), 'color', blue);
        hold off;
        first = 'Second'; second = 'First';
    else
        plot(times, obj.audio(samps, channel), 'color', blue);
        hold on;
        plot(times, obj.audio(samps+lag, channel), 'color', orange);
        hold off;
        first = 'First'; second = 'Second';
    end
    vertical(obj.t1s{i}(l), 'linestyle', '--', 'color', 'g');
    legend(first, second, 'Loop Point');
    
    xlabel('Time (s)');
    title(sprintf('Lag = %fs, Channel %i', obj.taus{i}(l), channel));
end