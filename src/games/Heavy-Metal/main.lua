-- actual game is "Heavy Rust"

local am = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/aimbot.lua"))()
local sm = require(game:GetService("ReplicatedStorage")["Blaster"]["Scripts"]["BlasterController"])

local old
old = hookfunction(sm.shoot, function(self)

    local camera = workspace.CurrentCamera
    local origin = camera.CFrame.Position

    local nearest = am.gclosest(650, false)
    print(nearest)

    if nearest then -- lb
        local oldp = camera.CFrame
        camera.CFrame = CFrame.new(origin, nearest["Character"]["HumanoidRootPart"].Position)

        old(self)

        camera.CFrame = oldp
        return
    end

    return old(self)
end)
