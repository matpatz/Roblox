return function(script: LocalScript | Script)
    if not script.Enabled then
        error("script is disabled", 2)
    end

    return getfenv(0)
end
