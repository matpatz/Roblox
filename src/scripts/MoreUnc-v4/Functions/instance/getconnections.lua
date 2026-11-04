-- roblox gives scripts no way to walk a signal's connections, so there is nothing
-- real to hand back here; executors that ship their own keep theirs, this is only
-- reached when the executor has none. returning fake proxies made firesignal throw
return function(signal)
    return {}
end