local services = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))()
local _game = services["marketplace"]:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"))()
local window = Rayfield:CreateWindow({
    Name = _game,
    LoadingTitle = "fah you",
    LoadingSubtitle = "subtitle",
})

local main = window:CreateTab("Main", 4483362458)

main:CreateLabel("Auto Hit", "wind")

local connections = {
    AutoHit = {}
}

local states = {
    runtime = {},

    values = {
        enabled = false,

        events = services["rep"]:WaitForChild("Events"),

        touch = nil
    }
}

states.values.touch = states.values.events:WaitForChild("TouchHitEvent")

local function addConnection(category, name, thread)
    if category[name] then
        pcall(function()
            if typeof(category[name]) == "RBXScriptConnection" then
                category[name]:Disconnect()
            else
                task.cancel(category[name])
            end
        end)
    end

    category[name] = thread
    states.runtime[name] = true
end

local function removeConnection(category, name)
    if category[name] then
        pcall(function()
            if typeof(category[name]) == "RBXScriptConnection" then
                category[name]:Disconnect()
            else
                task.cancel(category[name])
            end
        end)

        category[name] = nil
    end

    states.runtime[name] = false
end

local function IsValid(block)
    if not block or not block.Parent then
        return false
    end

    local health = block:GetAttribute("Health")
    local blockType = block:GetAttribute("BlockType") or "normal"

    if not health or health <= 0 then
        return false
    end

    if blockType ~= "normal" then
        return false
    end

    return true
end

local function HitBlock(block)
    if not IsValid(block) then
        return
    end

    local gx = block:GetAttribute("GX")
    local gz = block:GetAttribute("GZ")

    if not gx or not gz then
        return
    end

    states.values.touch:FireServer(gx, gz)
end

local function StartHit()
    if states.values.enabled then
        return
    end

    states.values.enabled = true

    addConnection(connections.AutoHit, "Loop", services["rs"].Heartbeat:Connect(function()
        if not states.values.enabled then
            return
        end

        local cubes = services["collection"]:GetTagged("DestructibleCube")

        if #cubes <= 0 then
            return
        end

        for _, block in ipairs(cubes) do
            HitBlock(block)
        end
    end))
end

local function StopHit()
    states.values.enabled = false

    removeConnection(connections.AutoHit, "Loop")
end

main:CreateToggle({
    Name = "Auto Hit All Blocks",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartHit()
        else
            StopHit()
        end
    end
})

Rayfield:Notify({
    Title = _game,
    Content = "successfully loaded!",
    Duration = 5,
    Image = 4483362458,
})
