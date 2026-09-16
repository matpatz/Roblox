return function(object: Instance): table
    local Proxy = {}
    return setmetatable(Proxy, {
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