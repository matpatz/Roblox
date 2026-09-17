return function(target: table)
    local metatable = getmetatable(target) -- __metatable makes this return nil
    return metatable
end