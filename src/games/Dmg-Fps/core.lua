--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager

local utils = scriptmanager.get("utils")

--// Services
local ReplicatedStorage = services.ReplicatedStorage
local HttpService = services.HttpService
local PlayerScripts = services.Players.LocalPlayer:WaitForChild("PlayerScripts")

--// Modules

local BlasterClient = require(PlayerScripts.Features.Blaster.BlasterClient)
local BlasterConfig = require(ReplicatedStorage.Shared.Config.Blaster)
local EnemyToy = require(ReplicatedStorage.Shared.Config.EnemyToy)

--// Functions
local shoot = BlasterClient.shoot

--// Events
local Remotes = require(ReplicatedStorage.Network.Network).Remotes

local Shoot = Remotes.Shoot
local Reload = Remotes.Reload

--// Variables
local p74: any = {}

local config = scriptmanager.config.set(
    {
        KillAura = {
            Value = true,
            Range = 1000,
            AimPart = "Head",
        },
    }
)

--// core
local core = {}

core = scriptmanager.set("core", core)

local Old; Old = hookfunction(shoot, function(this)
    p74 = this

    return Old(this)
end)

local OldEquip; OldEquip = hookfunction(BlasterClient.equip, function(this, ...)
    p74 = this

    return OldEquip(this, ...)
end)

--// kill aura

local function HitReport(Enemy: Instance, AimPart: BasePart): {}?
    local Humanoid = Enemy:FindFirstChildOfClass("Humanoid")
    local HumanoidRootPart = Enemy:FindFirstChild("HumanoidRootPart")
    local EnemyId = Enemy:GetAttribute("PrivateEnemyId")

    if not (Humanoid and Humanoid.Health > 0) then
        warn("Enemy does not have a valid Humanoid or is dead")
        return nil
    end

    if not HumanoidRootPart then
        warn("Enemy does not have a HumanoidRootPart")
        return nil
    end

    if not EnemyId then
        warn("Enemy does not have a PrivateEnemyId")
        return nil
    end

    return {
        EnemyId = EnemyId,
        EnemyPosition = HumanoidRootPart.Position,
        HitPosition = AimPart.Position,
        BodyRegion = EnemyToy.PartToRegion[AimPart.Name] or "Torso",
        Generation = Enemy:GetAttribute("EnemyGeneration"),
    }
end

local function Kill()
    local Blaster = p74.blaster

    if not Blaster then
        return
    end

    local AimPart, Target = utils["Aimbot"].GetClosest()

    if not AimPart then
        warn("No AimPart found")
        return
    end

    if p74.ammo == 0 then
        warn("Out of ammo, reloading...")

        local MaxAmmo = Blaster:GetAttribute(BlasterConfig.MagazineSizeAttribute)

        utils.Reload(Reload, Blaster)
        p74.ammo = MaxAmmo -- ud bro

        return
    end

    local HitReport = HitReport(Target, AimPart)

    if not HitReport then
        return
    end

    Shoot:FireServer(
        HttpService:GenerateGUID(false),
        workspace:GetServerTimeNow(),
        Blaster,
        AimPart.Position,
        { ["1"] = HitReport }
    )
end

task.spawn(function()
    while task.wait(0.1) do
        if config.KillAura.Value then
            local Success, Error = xpcall(Kill, debug.traceback)

            if not Success then
                warn("Kill aura failed: " .. tostring(Error))
            end
        end
    end
end)

return core
