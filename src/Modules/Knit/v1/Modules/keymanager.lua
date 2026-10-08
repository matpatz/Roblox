local keymanager = {}

local Knit = shared.Knit
repeat
    Knit = shared.Knit
    task.wait()
until
    Knit

local conmanager = Knit.conmanager

repeat
    conmanager = Knit.conmanager
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
