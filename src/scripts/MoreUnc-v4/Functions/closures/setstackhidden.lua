type func = typeof(function() end)

local stackhidden = {}

return function(func: func | number, hidden: boolean)
    local target: string = if type(func) == "function" then "func" else "thread"
    stackhidden[func] = hidden
end
