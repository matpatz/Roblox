return function(object: Instance)
    -- plain table + raw set, __newindex would forward "__raw" onto the instance
    local proxy = {
        __raw = object, -- compareinstances unwraps this
    }

    return setmetatable(proxy, {
        __index = object,
        __newindex = function(_, Key, Value)
            object[Key] = Value
        end,
        __tostring = function()
            return tostring(object)
        end,
        __eq = function()
            return false
        end,
    })
end