--// Knit
local Knit = shared.Knit

local utils = Knit.utils
local services = Knit.services
local scriptmanager = Knit.scriptmanager
local playermanager = Knit.player

local name = scriptmanager.name
local config = scriptmanager.config.set(
    {
        Reset = {
            Value = false
        },
        AutoReset = {
            Value = false
        }
    }
)

--// Services
local ReplicatedStorage = services.ReplicatedStorage
local Players = services.Players

local LocalPlayer = playermanager.LocalPlayer

--// core
local core = {}

core.Reset = function()
    local Character = playermanager.Character
    if Character then
        Character:Destroy()
    end
end

scriptmanager.set("core", core)

-- bundle waits on this return, without it Knit.require hands back nil and the
-- repeat task.wait() loop in Modules/bundle.lua spins forever
return core