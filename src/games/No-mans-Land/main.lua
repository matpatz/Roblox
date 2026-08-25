local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local PH = require(game.ReplicatedStorage.Modules.Other.WeaponStuff.ProjectileHandler)

-- HandleBullets upvalues (decompiler comment order):
-- 1 WeaponAttributes, 2 GetBulletVectors, 3 u1, 4 LocalPlayer,
-- 5 DoSuppression, 6 PartStoresClient, 7 GetBulletStore, 8 PropagateBullet
local upvalues = debug.getupvalues(PH.HandleBullets)
local OldPropagate = upvalues[8]
assert(OldPropagate, "PropagateBullet not found")

local Enabled   = true
local MaxRange  = 400
local FOV       = 30          -- degrees off crosshair before we snap
local AimPart   = "HumanoidRootPart"  -- or "Head"

local function closestEnemy(origin, lookDir)
    local best, bestScore
    for _, plr in Players:GetPlayers() do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(AimPart) or char:FindFirstChild("Torso")
        if not part then continue end

        local to    = part.Position - origin
        local dist  = to.Magnitude
        if dist > MaxRange then continue end

        local angle = math.deg(math.acos(math.clamp(lookDir:Dot(to.Unit), -1, 1)))
        if angle > FOV then continue end

        local score = dist * (1 + angle / 180)   -- prefer close + near crosshair
        if not bestScore or score < bestScore then
            best, bestScore = part, score
        end
    end
    return best
end

debug.setupvalue(PH.HandleBullets, 8, function(v14, u1)
    if Enabled and v14.IsMainClient then          -- only redirect YOUR shots
        local origin  = v14.StartCFrame.Position  -- muzzle
        local target  = closestEnemy(origin, v14.BulletVector.Unit)
        if target then
            local speed = v14.BulletVector.Magnitude
            v14.BulletVector = (target.Position - origin).Unit * speed  -- keep speed
        end
    end
    return OldPropagate(v14, u1)
end)