local function wrap(func)
    return function(...)
        return func(...)
    end
end

return function(func) -- function
    return wrap(func) -- the second func is hooked, or deleted the clone fails too
end