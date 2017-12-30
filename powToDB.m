function db = powToDB(obj, p)
    db = 10*log10(p / obj.powRef);
end