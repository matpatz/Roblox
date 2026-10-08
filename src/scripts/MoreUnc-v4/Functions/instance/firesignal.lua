local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local getconnections = getfunction("getconnections", "instance")

return function(signal, ...)
    local Args = { ... }
    for _, Connection in next, getconnections(signal) do
        if #Args > 0 then
            Connection:Fire(table.unpack(Args))
        else
            Connection:Fire()
        end
    end
end