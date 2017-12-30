function fullPlayback(obj)
    p = audioplayer(obj.audio, obj.Fs);
    p.playblocking();
end