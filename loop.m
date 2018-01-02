function [t1, t2, c] = loop(obj, filename)
    obj.readFile(filename);
    [t1, t2, c] = obj.findLoop;
end