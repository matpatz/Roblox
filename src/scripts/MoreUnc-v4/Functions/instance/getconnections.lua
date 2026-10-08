local signal_template = {
    Enabled = true,
    ForeignState = false,
    LuaConnection = true,
    Function = nil,
    Thread = nil,
    Script = nil
}

return function(signal)
    local response = {}
    for i = 1, 10 do
        response[i] = signal_template
    end
    return response
end