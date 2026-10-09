local keymanager = {}

local Knit = shared.Knit

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
    for _, Keybind in KeybindList do
        if UserInputService:IsKeyDown(Keybind) then
            Callback()
        end
    end
end

keymanager.new = function(Key, KeybindList, Callback)
    conmanager.connect(Key, 0.1, function()
        manage(KeybindList, Callback)
    end)
end

return keymanager
