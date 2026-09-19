local utils = {}

local Knit = shared.Knit
local scriptmanager = Knit.scriptmanager
local services = Knit.services

local ReplicatedStorage = services.ReplicatedStorage

-- the draft remotes live under Draft, not ReplicatedStorage.Remotes
local Remotes = require(ReplicatedStorage.Draft.Remotes)
local Objects = require(ReplicatedStorage.Draft.Objects)

utils.Remotes = Remotes

utils.Actions = {
    Raise = "raise",
    Pass = "pass",
}

-- character power is static, so one lookup per name is enough
local powercache = {}

-- core owns the config and loads after utils, so it can only be read lazily
local function config()
    return scriptmanager.config.get() or {}
end

utils.Setting = function(key)
    local entry = config()[key]

    if type(entry) == "table" then
        return entry.Value
    end

    return entry
end

-- sides

utils.Side = function(state, index)
    return state and state.sides and state.sides[index]
end

utils.Me = function(state)
    return utils.Side(state, state and state.you)
end

-- the other player. their wallet is the only thing that tells us when to stop
-- paying, everything else is a guess
utils.Opponent = function(state)
    if not state or not state.you then
        return nil
    end

    for index, side in pairs(state.sides or {}) do
        if index ~= state.you then
            return side
        end
    end

    return nil
end

utils.Cash = function(side)
    return (side and side.cash) or 0
end

utils.NextBid = function(state)
    return (state and state.price or 0) + 1
end

utils.LotsLeft = function(state)
    local total = (state and state.totalLots) or 1
    local lot = (state and state.lot) or 1

    return math.max(1, total - lot + 1)
end

-- measured across the PowerScaling theme list, used as the "ordinary lot" line
local AVERAGE_POWER = 22

-- value

-- every character sits in the theme table with its real power next to it:
--   Themes[theme].list[i] = { name, short, tier, value, worth, weight }
-- Arceus is 76.6, Jiren 68, and maxValue is 90, so this is the number the
-- verdict is actually scored from. Objects.weightOf answers 1 for everything
-- and is not the power at all.
local function theme_list(theme)
    local entry = Objects.Themes[theme] or Objects.Themes[Objects.DEFAULT_THEME]

    return entry and entry.list
end

utils.Power = function(object, theme)
    if not object or utils.Setting("UsePower") == false then
        return nil
    end

    local list = theme_list(theme)

    if type(list) ~= "table" then
        return nil
    end

    local key = string.format("%s/%s/%s", tostring(theme), tostring(object.name), tostring(object.short))
    local cached = powercache[key]

    if cached ~= nil then
        return cached or nil
    end

    local power = nil

    for _, entry in ipairs(list) do
        if entry.name == object.name or (object.short ~= nil and entry.short == object.short) then
            power = tonumber(entry.value) or tonumber(entry.worth)
            break
        end
    end

    powercache[key] = power or false

    return power
end

-- total power a side has already banked, read off the items it won
utils.SidePower = function(state, side)
    local total = 0

    for _, item in ipairs((side and side.items) or {}) do
        total += utils.Power(item, state and state.theme) or 0
    end

    return total
end

-- what the lot is worth us paying, in cash
--
-- cash that never gets spent scores nothing, so the wallet exists to be turned
-- into power. a lot is therefore worth its even share of what is left, scaled by
-- how good the character is against an ordinary one, plus the extra dollar it
-- takes to actually outbid rather than tie with the opponent
utils.Budget = function(state)
    local cash = utils.Cash(utils.Me(state)) - (utils.Setting("Reserve") or 0)
    local share = math.max(1, math.floor(cash / utils.LotsLeft(state)))
    local power = utils.Power(state.object, state.theme) or AVERAGE_POWER
    local boost = math.clamp(power / AVERAGE_POWER, 0.5, utils.Setting("PowerBoost") or 1)

    return share * boost + 1
end

-- the most we may ever pay for a lot
utils.Ceiling = function(state)
    local ceiling = utils.Cash(utils.Me(state)) - (utils.Setting("Reserve") or 0)
    local maxbid = utils.Setting("MaxBid") or 0

    if maxbid > 0 then
        ceiling = math.min(ceiling, maxbid)
    end

    -- never pay more than it takes to put the lot out of the opponent's reach:
    -- past their wallet a raise buys us nothing at all
    if utils.Setting("NeverOverpay") then
        local opponent = utils.Opponent(state)

        if opponent then
            ceiling = math.min(ceiling, utils.Cash(opponent) + 1)
        end
    end

    return ceiling
end

-- actions

utils.Act = function(state, action)
    utils.Remotes.DraftAction:FireServer(action, state.token)
end

-- run the game's own button handler: the payload is correct by construction, and
-- the handler re-checks whose turn it is, so this is safe to call at any time
utils.PressButton = function(name)
    local player = services.Players.LocalPlayer
    local gui = player.PlayerGui:FindFirstChild("DraftUI")
    local hud = gui and gui:FindFirstChild("HUD")
    local button = hud and hud:FindFirstChild(name)

    if not button then
        return false
    end

    local pressed = false

    for _, connection in ipairs(getconnections(button.Activated)) do
        if connection.Function then
            pressed = pcall(connection.Function) or pressed
        end
    end

    return pressed
end

scriptmanager.set("utils", utils)

return utils
