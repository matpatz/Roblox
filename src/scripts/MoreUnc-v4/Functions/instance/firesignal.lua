local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local getconnections = getfunction("getconnections", "instance")

return function(signal, ...)
    -- BindableEvent / BindableFunction: the engine fires it, no connections to walk
    local fire = signal.Fire

    if type(fire) == "function" then
        fire(signal, ...)

        return
    end

    for _, Connection in next, getconnections(signal) do
        Connection:Fire(...)
    end
end