local keymanager = {}
setmetatable(keymanager, {
    __index = function(_, Index)
        if Index == "keylist" then
            local keylist = Knit.require("Modules/misc", "keylist")
            return keylist
        end

        return rawget(_, Index)
    end
})

local conmanager = shared.Knit.conmanager

repeat
    conmanager = shared.Knit.conmanager
    task.wait()
until
    conmanager

local UserInputService = game:GetService("UserInputService")

local function manage(KeybindList, Callback)
    for i,v in next KeybindList do
        if UserInputService:IsKeyDown(v) then
            Callback()
        end
    end
end

keymanager.new = function(Key, KeybindList, Callback)
    conmanager.connect(Key, 0.1, manage) -- manage is not passed any params
end

return keymanager
