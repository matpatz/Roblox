--// Knit
local Knit = shared.Knit
local services = Knit.services

-- // Servics
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

--// Classes
local Classes = require(ReplicatedStorage:FindFirstChild("UmePointer").Value);

-- // Network
local Network = Classes.Network

--local RealNetwork = debug.getupvalue(Network.GetEvent, 3) -- u5
--local Remotes: Instance = debug.getupvalue(RealNetwork._getRemote, 3) -- u1

-- // WeaponController
local WeaponController = Classes.WeaponController
-- local GetAimRay = WeaponController.GetAimRay

local tryShoot = filtergc("function", {
    Name = "tryShoot"
}, true)

--// Workspace
local UmeWorkspace = Classes.Dirs.UmeWorkspace;

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	Character = NewCharacter
	HumanoidRootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")
end)

-- // Variables
local u126 -- where this will break: the user shooting manully (unsyced count) then server recieving it

const Constants = {
    DUCK_PREFIX = "DuckController_Client_",
    Shoot = "Shoot",
    -- index of tryShoot's shot counter upvalue (u22 in `Client - WeaponController`),
    -- re-check with `debug.getupvalues(tryShoot)[SHOT_COUNTER]` after game updates
    SHOT_COUNTER = 17
}

-- // config
local config = {
    AutoKillDucks = {
        Enabled = false
    }
}

-- // cheat
local cheat = {
	Utils = {

	},
	Core = {

	}
}

local Utils = cheat.Utils
local Util = Utils
local Core = cheat.Core

function Utils.GetClosestDuck(): Instance?
    local origin;
    local camera = workspace.CurrentCamera;

    if HumanoidRootPart then
        origin = HumanoidRootPart.Position;
    elseif camera then
        origin = camera.CFrame.Position;
    end;

    if not origin then
        return nil;
    end;

    local count = 0
    local closest, closestDist;

    for _, duck in next, (UmeWorkspace:GetChildren()) do
        if duck:IsA("Model") and string.sub(duck.Name, 1, #Constants["DUCK_PREFIX"]) == Constants["DUCK_PREFIX"] then
            local part = duck.PrimaryPart or duck:FindFirstChildWhichIsA("BasePart");

            if part then
                local dist = (part.Position - origin).Magnitude;

                if not closestDist or dist < closestDist then
                    -- count += 1
                    closest, closestDist = duck, dist;
                end;
            end;
        end;
    end;

    return closest, origin;
end;

function Utils.GetShotId(): number?
    local Counter = debug.getupvalues(tryShoot)[Constants["SHOT_COUNTER"]];

    if type(Counter) ~= "number" then
        return nil;
    end;

    return Counter + 1;
end;

function Util.Fire()
    local Target, Origin = Utils.GetClosestDuck();

    if not (Target and Origin) then
        return;
    end;

    local Part = Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart");

    if not Part then
        return;
    end;

    local ShotId = Utils.GetShotId();

    if not ShotId then
        return;
    end;

    local Direction = (Part.Position - Origin).Unit;

    -- keep the game's shot counter in sync
    if not pcall(debug.setupvalue, tryShoot, Constants["SHOT_COUNTER"], ShotId) then
        return;
    end;

    Network.Fire("WeaponController_Shoot", Origin, Direction, ShotId, workspace:GetServerTimeNow(), Constants["Shoot"]);
end;

-- limited to reload time, i will not be fixing it
function Core.FireAll()
    for Iterator = 1, #UmeWorkspace:GetChildren() do
        Util.Fire()
    end
end

UmeWorkspace.ChildAdded:Connect(function(duck)
    if config.AutoKillDucks.Enabled and duck:IsA("Model") and string.sub(duck.Name, 1, #Constants["DUCK_PREFIX"]) == Constants["DUCK_PREFIX"] then
        Core.FireAll()
    end
end)

-- // Interface

local Rayfield = Knit.ui.new("Rayfield")()

local Window = Rayfield:CreateWindow({
    Name = "Catch a billion Ducks",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "subtitle",
})

local tabs = {
    Ducks = Window:CreateTab("Ducks"),
    settings = Window:CreateTab("settings"),
}

tabs.Ducks:CreateToggle({
    Name = "Auto Kill Ducks",
    CurrentValue = false,
    Flag = "AutoStealEgg",
    Callback = function(Value)
        config.AutoKillDucks.Enabled = Value
        if not Value then
            return
        end

        Core.FireAll()
    end,
})

tabs.Ducks:CreateButton({
    Name = "Kill Ducks",
    Callback = function()
        task.spawn(function()
            Core.FireAll()
        end)
    end,
})

tabs.Ducks:CreateButton({
    Name = "Kill Closest Duck",
    Callback = function()
        task.spawn(function()
            Util.Fire()
        end)
    end,
})