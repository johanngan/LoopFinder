function removeFade(obj)
    fadeLength = obj.detectFade(obj.audio, obj.Fs);
    obj.audio = obj.audio(1:end-fadeLength, :);
    obj.fadeRemoved = true;
end