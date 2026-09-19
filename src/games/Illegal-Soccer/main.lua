-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Modules
const Sprint = require(ReplicatedStorage.Client.Gameplay.Player.Sprint)

-- // cheat
local cheat = {
	core = {
		InfiniteStamina = {},
	},
}
local core = cheat.core

-- // config
local config = {
	InfiniteStamina = {
		Enabled = true,
	},
}

-- // Core

const STAMINA_KEY = "voltex"

core.InfiniteStamina.Enabled = function()
	Sprint.SetUnlimitedStamina(STAMINA_KEY, true)
end

core.InfiniteStamina.Disable = function()
	Sprint.SetUnlimitedStamina(STAMINA_KEY, false)
end

-- // run

if config.InfiniteStamina.Enabled then
	core.InfiniteStamina.Enabled()
end
