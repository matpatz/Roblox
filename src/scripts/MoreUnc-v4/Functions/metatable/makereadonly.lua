return function(target)
    setrawmetatable(target, {
        __newindex = function(_, __,)
            error("attempt to modify readonly table")
        end
    })
end