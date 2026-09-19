--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager

-- core loads after utils, so this is safe to grab here
local utils = scriptmanager.get("utils")

local config = scriptmanager.config.set(
    {
        AutoDraft = {
            Value = true,
        },
        UsePower = {
            Value = true,
        },
        -- how much more than an even share of the wallet a top-tier character is
        -- worth going for. 1 = never pay above an even split
        PowerBoost = {
            Value = 2.5,
        },
        -- never pay more than the opponent can match
        NeverOverpay = {
            Value = true,
        },
        -- ignore value entirely and win anything affordable
        AlwaysBid = {
            Value = false,
        },
        Reserve = {
            Value = 0,
        },
        MaxBid = {
            Value = 0,
        },
    }
)

--// core
local core = {
    AutoDraft = {},
}

-- the latest DraftState, and enough bookkeeping to act exactly once per turn
local state = nil

local lastkey = nil
local pendingkey = nil
local action = nil
local actedat = 0
local retried = false

-- the server hands out a fresh token for every move, so lot + token identifies a
-- single turn
local function turnkey(current)
    return string.format("%s:%s", tostring(current.lot), tostring(current.token))
end

-- "raise" / "pass" / nil when it is not our move
core.AutoDraft.Decide = function(current)
    if current.phase ~= "lot" or current.turn ~= current.you then
        return nil
    end

    if not current.canRaise then
        return utils.Actions.Pass
    end

    local bid = utils.NextBid(current)

    if bid > utils.Ceiling(current) then
        return utils.Actions.Pass
    end

    if config.AlwaysBid.Value then
        return utils.Actions.Raise
    end

    return bid <= utils.Budget(current) and utils.Actions.Raise or utils.Actions.Pass
end

core.AutoDraft.OnState = function(current)
    if type(current) ~= "table" then
        return
    end

    state = current
end

core.AutoDraft.Enabled = function()
    lastkey = nil

    core.AutoDraft.Connection = utils.Remotes.DraftState.OnClientEvent:Connect(core.AutoDraft.OnState)

    core.AutoDraft.Loop = task.spawn(function()
        while true do
            local current = state

            if current then
                local key = turnkey(current)

                if key ~= lastkey then
                    local decision = core.AutoDraft.Decide(current)

                    if decision then
                        lastkey = key
                        pendingkey = key
                        action = decision
                        actedat = os.clock()
                        retried = false

                        utils.Act(current, decision)
                    end
                elseif pendingkey == key and not retried and os.clock() - actedat > 1.5 then
                    -- the turn never advanced, so the remote call was ignored
                    pendingkey = nil
                    retried = true

                    utils.PressButton(action == utils.Actions.Raise and "BidButton" or "PassButton")
                end
            end

            task.wait(0.1)
        end
    end)
end

core.AutoDraft.Disable = function()
    if core.AutoDraft.Connection then
        core.AutoDraft.Connection:Disconnect()
        core.AutoDraft.Connection = nil
    end

    if core.AutoDraft.Loop then
        task.cancel(core.AutoDraft.Loop)
        core.AutoDraft.Loop = nil
    end

    state = nil
end

-- the game's handler checks whose turn it is, so a stray click cannot misfire
core.AutoDraft.Pass = function()
    utils.PressButton("PassButton")
end

core.AutoDraft.Raise = function()
    utils.PressButton("BidButton")
end

core.AutoDraft.State = function()
    return state
end

-- the live readout: our numbers and everything we can see of theirs, which is
-- what the bidding actually gets decided against
core.AutoDraft.Status = function()
    local current = state

    if not current then
        return {
            Title = "Waiting",
            Content = "No draft in progress.",
        }
    end

    local lot = current.object or {}
    local me = utils.Me(current)
    local opponent = utils.Opponent(current)

    local function line(side, label)
        if not side then
            return label .. "  --"
        end

        return string.format(
            "%s  %s  $%s  %s lots  %s power  bid $%s",
            label,
            tostring(side.name),
            tostring(utils.Cash(side)),
            tostring(side.lots),
            tostring(utils.SidePower(current, side)),
            tostring(side.bid)
        )
    end

    return {
        Title = string.format("Lot %s/%s  %s [%s]", tostring(current.lot), tostring(current.totalLots), tostring(lot.name), tostring(lot.tier)),
        Content = table.concat(
            {
                string.format("phase %s   price $%s   next $%s", tostring(current.phase), tostring(current.price), tostring(utils.NextBid(current))),
                line(me, "you "),
                line(opponent, "them"),
                string.format(
                    "power %s   worth $%s   ceiling $%s",
                    tostring(utils.Power(current.object, current.theme) or "?"),
                    tostring(utils.Budget(current)),
                    tostring(utils.Ceiling(current))
                ),
            },
            "\n"
        ),
    }
end

core = scriptmanager.set("core", core)

return core
