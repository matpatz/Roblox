return function(target: table, metatable: table)
    pcall(function()
        setmetatable(target, metatable) -- pretty sure this errors with a locked metatable, not sure
    end)
end