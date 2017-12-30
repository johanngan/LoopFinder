function specVis(obj, i, c)
% Visualize the spectrogram comparison of the ith best lag value, for the
% cth channel. If c is not 1 or 2, then both channels will be used. i
% defaults to 1.

    if(nargin < 3)
        c = 0;
    end
    
    if(nargin < 2)
        i = 1;
    end

    addpath('../util');
    avgVol = obj.powToDB(mean(sum(obj.audio.^2, 2)));
    
%     for j = 1:length(obj.SVS{i})
    j = 0;
    keypress = 29;
    while(keypress ~= 113 && keypress ~= 8 && keypress ~= 27)  % Quit at 'q', backspace, or escape
        k = 0;
        j_old = j;
        
        if(keypress == 29 || keypress == 31 || keypress == 13)    % Right, down, or enter
            j = min(length(obj.SVS{i}), j + 1);
        elseif(keypress == 28 || keypress == 30)    % Left or up
            j = max(1, j - 1);
        end
        
        % Update
        if(j ~= j_old)
            subplot(1, 2, 1)

            switch(c)
                case {1}
                    plot(obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{1, 1}(:, j)), ...
                        obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{2, 1}(:, j)));
                case {2}
                    plot(obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{1, 2}(:, j)), ...
                        obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{2, 2}(:, j)));
                otherwise
                    plot(obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{1, 1}(:, j)), ...
                        obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{2, 1}(:, j)), ...
                        obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{1, 2}(:, j)), ...
                        obj.SVF{i}, obj.powToDB(obj.SVspectrograms{i}{2, 2}(:, j)));
            end
            title(sprintf('Avg Vol = %f dB, t = %f', avgVol, obj.SVS{i}(j)/obj.Fs));
            ylabel('Volume (dB)');
            xlabel('Frequency (Hz)');
            horizontal(avgVol - obj.dBLevel, 'linestyle', '--', 'color', 'r');

            subplot(1, 2, 2)
            plot(obj.SVS{i}/obj.Fs, obj.SVspecDiff{i}, obj.SVS{i}(j)/obj.Fs, obj.SVspecDiff{i}(j), 'o');
            title(sprintf('Lag = %f, MSE = %f', obj.SVoldlags{i}/obj.Fs, mean(obj.SVspecDiff{i}(obj.SVleft{i}:obj.SVright{i}))));
            ylabel('Spectrum MSE');
            xlabel('Time');
            vertical(obj.SVS{i}(obj.SVleft{i})/obj.Fs, 'linestyle', '--', 'color', 'r');
            vertical(obj.SVS{i}(obj.SVright{i})/obj.Fs, 'linestyle', '--', 'color', 'r');
        end

        while(~k)
            k = waitforbuttonpress;
            keypress = double(get(gcf, 'CurrentCharacter'));
        end
    end
end