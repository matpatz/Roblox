--// Knit
local Knit = shared.Knit

local scriptmanager = Knit.scriptmanager
local services = Knit.services
local conmanager = Knit.conmanager

local config = scriptmanager.config.set({
    flags = {},
    SilentAim = {
        -- per-weapon Settings.MaxDistance is 400 on the pistol (600 is just the
        -- fallback), a target past it eats the shot and gets the ammo refunded
        Range = 400,
        Visible = true,
        TeamCheck = true,
        AimParts = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },

        EntityLists = {},
    },
})

local utils = scriptmanager.get("utils")

--// Services
local ReplicatedStorage = services.ReplicatedStorage
-- local CollectionService = services.CollectionService

local Lighting = game:GetService("Lighting")
    -- do not cloneref
    
--// Events
local GunFire = ReplicatedStorage:FindFirstChild("GunFire")
local R6CameraAimRemote = ReplicatedStorage:FindFirstChild("R6CameraAimRemote")

--// core
local core = {
    TargetHUD = nil,
}

local function UpdateTargetHUD(Target, AimPart, Weapon)
    local TargetHUD = core.TargetHUD
    if not TargetHUD then
        return
    end

    if not Target then
        TargetHUD:toggle(false)
        return
    end

    local Character = Target.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

    TargetHUD:toggle(true)
    TargetHUD:setName(Target.Name)
    TargetHUD:setDistance(tostring(math.floor((AimPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)))
    TargetHUD:setWeapon(Weapon)

    if Humanoid then
        TargetHUD:setHealth(Humanoid.Health, Humanoid.MaxHealth)
    end
end

local __game = getrawmetatable(game)

local ___namecall = __game.__namecall
pcall(restorefunction, ___namecall)

local ___newindex = __game.__newindex
pcall(restorefunction, ___newindex)

local ___index = __game.__index
pcall(restorefunction, ___index)

-- GunFire:FireServer(muzzlePos, Origin, Unit, name, serverTimeNow, isADS, weapon, sequence, dronePose)
-- R6CameraAimRemote:FireServer(pitch, yaw, hasTool, cameraPosition, lookVector, serverTimeNow, cameraActive)

-- the server cross-checks a shot against the camera data R6CameraBodyAim reports,
-- so the report has to agree with the direction we actually fired
local cameraHold

local function cameraReport(Direction)
    local Character = services.Players.LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    local Camera = workspace.CurrentCamera

    if not Root or not Camera then
        return nil
    end

    local Pitch = math.asin(math.clamp(Direction.Y, -1, 1))
    if math.abs(Pitch) <= 0.013089969389957472 then
        Pitch = 0
    end

    local Flat = Vector3.new(Direction.X, 0, Direction.Z)
    local Forward = Vector3.new(Root.CFrame.LookVector.X, 0, Root.CFrame.LookVector.Z)
    local Right = Vector3.new(Root.CFrame.RightVector.X, 0, Root.CFrame.RightVector.Z)

    local Yaw = 0
    if Flat.Magnitude > 0.001 and Forward.Magnitude > 0.001 and Right.Magnitude > 0.001 then
        local Unit = Flat.Unit
        Yaw = math.atan2(-Unit:Dot(Right.Unit), Unit:Dot(Forward.Unit))
    end

    return math.clamp(Pitch, -1.2217304763960306, 1.2566370614359172),
        math.clamp(Yaw, -1.0821041362364843, 1.0821041362364843),
        Camera.CFrame.Position
end

local function silent_aim(self, Args)
    local Hitchance = config.flags["SilentAim.hitchance"]

    local AimPart, Target = utils.GetClosest(config.SilentAim)
    UpdateTargetHUD(Target, AimPart, Args[4])

    if AimPart and Hitchance and utils.shouldredirect(Hitchance.value) then
        local Direction = (AimPart.Position - Args[2]).Unit
        Args[3] = Direction

        -- report the aim first, then the shot, and keep the game's own reports
        -- in line with it until the shot is over
        if R6CameraAimRemote then
            local Pitch, Yaw, CameraPosition = cameraReport(Direction)
            if Pitch then
                cameraHold = { Pitch = Pitch, Yaw = Yaw, Look = Direction, Until = os.clock() + 0.25 }

                R6CameraAimRemote:FireServer(Pitch, Yaw, true, CameraPosition, Direction, workspace:GetServerTimeNow(), true)
            end
        end
    end

    return Args
end

local function camera_aim(self, Args)
    local Hold = cameraHold
    if not Hold or os.clock() >= Hold.Until then
        return Args
    end

    Args[1] = Hold.Pitch
    Args[2] = Hold.Yaw
    Args[5] = Hold.Look

    return Args
end

local __namecalls = {
    {
        Flag = "SilentAim",
        Method = "FireServer",
        _self = GunFire,
        callback = silent_aim,
    },
}

if R6CameraAimRemote then
    table.insert(__namecalls, {
        Flag = "SilentAim",
        Method = "FireServer",
        _self = R6CameraAimRemote,
        callback = camera_aim,
    })
end

local __namecall; __namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local Method = getnamecallmethod()
    if checkcaller() == true then
        return __namecall(self, ...)
    end

    local Args = { ... }

    for _, v in __namecalls do
        if Method ~= v.Method then
            continue
        end

        if self ~= v._self then
            continue
        end

        local Flag = config.flags[v.Flag]
        if not Flag or Flag.value ~= true then
            continue
        end

        Args = v.callback(self, Args) or Args
    end

    setnamecallmethod(Method)

    return __namecall(self, table.unpack(Args))
end)

-- // World

-- value = what the game believes the property holds; game writes only update it
-- and never reach the real property, so reads give the game its own value back
-- while the real property keeps ours
local __indexes = {
    ["ambinece"] = {
        object = Lighting,
        property = "Ambient",
        value = Lighting.Ambient,
    }
}

core.World = __indexes

local __newindex; __newindex = hookmetamethod(game, "__newindex", function(object, property, value)
    if checkcaller() == true then
        return __newindex(object, property, value)
    end

    for Name, v in __indexes do
        if object ~= v.object then
            continue
        end

        if property ~= v.property then
            continue
        end

        local Flag = config.flags[Name]
        if not Flag or Flag.value ~= true then
            continue
        end

        v.value = value
        return
    end

    return __newindex(object, property, value)
end)

local __index; __index = hookmetamethod(game, "__index", function(object, property)
    if object == Lighting and checkcaller() == false then
        for Name, v in __indexes do
            if property ~= v.property then
                continue
            end

            local Flag = config.flags[Name]
            if not Flag or Flag.value ~= true then
                continue
            end

            return v.value
        end
    end

    return __index(object, property)
end)

core = scriptmanager.set("core", core)

return core