local stackhidden = {}

return function(func: function | number, hidden: boolean)
    local target: string = if type(func) == "function" then "func" else "thread"
    stackhidden[func] = hidden
end
