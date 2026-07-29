-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local Debris = game:GetService("Debris");
local Players = game:GetService("Players");
local TweenService = game:GetService("TweenService");
local ContextActionService = game:GetService("ContextActionService");
local FieldOfView = workspace.CurrentCamera.FieldOfView;
local SPH_Assets = ReplicatedStorage.SPH_Assets;
local Modules = SPH_Assets.Modules;
local _ = SPH_Assets.Animations;
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent.Parent;
local Humanoid = Parent:WaitForChild("Humanoid");
local HumanoidRootPart = Parent:WaitForChild("HumanoidRootPart", 10);
local Inventory = LocalPlayer:WaitForChild("Inventory");
local Equipment = Inventory:WaitForChild("Equipment");
local u1 = 0;
local RequestSprintChange = ReplicatedStorage.RequestSprintChange;
local u2, u3, u4;

if Humanoid.RigType == Enum.HumanoidRigType.R6 then
    u2 = HumanoidRootPart:WaitForChild("RootJoint");
    u3 = Parent.Torso.Neck;
    u4 = Humanoid.RigType;
else
    u2 = Parent.LowerTorso.Root;
    u3 = Parent.Head.Neck;
    u4 = Humanoid.RigType;
end;

local u5 = {};
local u6 = {};
local CurrentCamera = workspace.CurrentCamera;

if CurrentCamera.CameraSubject ~= Humanoid then
    CurrentCamera.CameraSubject = Humanoid;
end;

CurrentCamera.CameraType = Enum.CameraType.Custom;

if CurrentCamera:FindFirstChild("WeaponRig") then
    CurrentCamera.WeaponRig:Destroy();
end;

local Fovmult = LocalPlayer:WaitForChild("Settings"):WaitForChild("Fovmult");
local Value = Fovmult.Value;
Fovmult.Changed:Connect(function(p7) -- Line: 42
    -- upvalues: Value (ref)
    Value = p7;
end);

local function getArmorSpeedReduction() -- Line: 45
    -- upvalues: Inventory (copy), Equipment (copy), LocalPlayer (copy)
    if not Inventory then
        return 0;
    end;

    if not Equipment then
        return 0;
    end;

    local v8 = 0;

    for _, v in ipairs({ "Helmet", "BodyArmor", "Backpack", "Facemask" }) do
        local v9 = Equipment:FindFirstChild(v);

        if v9 then
            local ItemName = v9:FindFirstChild("ItemName");

            if ItemName and ItemName.Value ~= "" then
                local Character = LocalPlayer.Character;

                if Character then
                    local v10 = Character:FindFirstChild(ItemName.Value);

                    if v10 then
                        local SpeedReduction = v10:FindFirstChild("SpeedReduction");

                        if SpeedReduction and SpeedReduction:IsA("NumberValue") then
                            v8 = v8 + SpeedReduction.Value;
                        end;
                    end;
                end;
            end;
        end;
    end;

    return v8;
end;

local u11 = {
    Level_I = 1,
    Level_II = 2,
    Level_III = 3,
    Level_IV = 4
};
local GetPlayerAdminRank = ReplicatedStorage:WaitForChild("GetPlayerAdminRank");

local function isAdminPlayer() -- Line: 76
    -- upvalues: GetPlayerAdminRank (copy), LocalPlayer (copy), u11 (copy)
    local success, result = pcall(function() -- Line: 77
        -- upvalues: GetPlayerAdminRank (ref), LocalPlayer (ref)
        return GetPlayerAdminRank:InvokeServer(LocalPlayer);
    end);

    if success and typeof(result) == "string" then
        return (u11[result] or 0) >= 1;
    end;

    return false;
end;

local u12 = 0;
local success, result = pcall(function() -- Line: 77
    -- upvalues: GetPlayerAdminRank (copy), LocalPlayer (copy)
    return GetPlayerAdminRank:InvokeServer(LocalPlayer);
end);
local u13;

if success and typeof(result) == "string" then
    u13 = (u11[result] or 0) >= u11.Level_I;
else
    u13 = false;
end;

local WeldMod = require(Modules.WeldMod);
local BridgeNet = require(Modules.BridgeNet);
local ViewMod = require(Modules.ViewMod);
local SpringModule = require(Modules.SpringModule);
require(Modules.HitFX);
local BGLOPP = require(Modules.BGLOPP);
local Mods = require(SPH_Assets.Mods);
BGLOPP.Initialize(LocalPlayer);
local GameConfig = require(SPH_Assets.GameConfig);
Humanoid.WalkSpeed = GameConfig.walkSpeed;
local Shells = workspace:WaitForChild("SPH_Workspace"):WaitForChild("Shells");
local u14 = nil;
local u15 = RaycastParams.new();
u15.IgnoreWater = true;
u15.RespectCanCollide = true;
u15.FilterType = Enum.RaycastFilterType.Exclude;
u15.FilterDescendantsInstances = { Parent, CurrentCamera, Shells };
local u16 = SpringModule.new();
local u17 = SpringModule.new();
local u18 = SpringModule.new();
local u19 = SpringModule.new();
local u20 = BridgeNet.CreateBridge("BodyAnimRequest");
local u21 = BridgeNet.CreateBridge("SwitchWeapon");
local u22 = BridgeNet.CreateBridge("PlayerFire");
local u23 = BridgeNet.CreateBridge("PlaySound");
local u24 = BridgeNet.CreateBridge("Reload");
BridgeNet.CreateBridge("PlayerChamber");
local u25 = BridgeNet.CreateBridge("MoveBolt");
local u26 = BridgeNet.CreateBridge("SwitchFireMode");
local u27 = BridgeNet.CreateBridge("PlayCharacterSound");
local u28 = BridgeNet.CreateBridge("PlayerDropGun");
local u29 = BridgeNet.CreateBridge("PlayerToggleAttachment");
local u30 = BridgeNet.CreateBridge("RepBoltOpen");
local u31 = BridgeNet.CreateBridge("MagGrab");
local u32 = BridgeNet.CreateBridge("PlayerLean");
local u33 = 0;
local u34 = 0;
local walkSpeed = GameConfig.walkSpeed;
local JumpPower = LocalPlayer.Character.Humanoid.JumpPower;
local u35 = walkSpeed;
local u36 = false;
local u37 = true;
local u38 = false;
local u39 = false;
local u40 = false;
local u41 = true;
local u42 = false;
local u43 = false;
local u44 = 0;
local u45 = nil;
local u46 = false;
local u47 = false;
local u48 = false;
local u49 = true;
local u50 = false;
local u51 = false;
local u52 = false;
local u53 = nil;
local u54 = nil;
local u55 = 0;
local u56 = nil;
local u57 = nil;
local u58 = nil;
local u59 = nil;
local u60 = nil;
local u61 = nil;
local u62 = nil;
local u63 = nil;
local u64 = nil;
local u65 = nil;
local u66 = CFrame.new();
local u67 = CFrame.new();
local u68 = CFrame.new();
local u69 = CFrame.new();
local FieldOfView2 = CurrentCamera.FieldOfView;
local u70 = CFrame.new();
local u71 = CFrame.new();
local u72 = {
    sprintSwayAmplitude = 0.1,
    sprintSwaySpeed = 6,
    sprintSwayLerp = 0.15,
    fixedDt = 0.008333333333333333,
    defaultJumpPower = 25,
    sprintRotation = CFrame.new(0, -0.3, 0.2) * CFrame.Angles(-0.5235987755982988, 0.5235987755982988, 0.6108652381980153),
    leanLeftRotation = CFrame.new(-1, 0, 0.2) * CFrame.Angles(0, 0, -0.08726646259971647),
    leanRightRotation = CFrame.new(0.5, 0, -0.1) * CFrame.Angles(0, 0, 0.08726646259971647)
};
local u73 = 0;
local u74 = 0;
local zero = Vector2.zero;
local u75 = CFrame.new(1000000, 0, 0);
local u76;

if u4 == Enum.HumanoidRigType.R15 then
    u76 = SPH_Assets.Animations.R15;
else
    u76 = SPH_Assets.Animations.R6;
end;

local u77 = 0;
local u78 = Humanoid.Animator:LoadAnimation(u76.Crouch_Idle);
u78.Looped = true;
u78.Priority = Enum.AnimationPriority.Idle;
local u79 = Humanoid.Animator:LoadAnimation(u76.Crouch_Move);
u79.Looped = true;
u79.Priority = Enum.AnimationPriority.Movement;
local u80 = Humanoid.Animator:LoadAnimation(u76.Prone_Idle);
u80.Looped = true;
u80.Priority = Enum.AnimationPriority.Idle;
local v81 = Humanoid.Animator:LoadAnimation(u76.Prone_Move);
v81.Looped = true;
v81.Priority = Enum.AnimationPriority.Movement;
local u82 = nil;
local u83 = {};
local u84 = Vector3.new(0, 0, 0);
local CameraMode = LocalPlayer.CameraMode;
local u85 = {};
local u86 = 1;
local u87 = 0;
local u88 = 0;
local u89 = 1;
local u90 = SPH_Assets.HUD.LaserDotUI:Clone();
local Attachment = Instance.new("Attachment");
Attachment.Parent = workspace.Terrain;
u90.Enabled = false;
u90.Parent = Attachment;
local Beam = Instance.new("Beam");
Beam.Attachment1 = Attachment;
Beam.LightInfluence = 0;
Beam.Brightness = 3;
Beam.Segments = 1;
Beam.Width0 = 0.02;
Beam.Width1 = 0.02;
Beam.FaceCamera = true;
Beam.Transparency = NumberSequence.new(0.5);
Beam.Name = "FirstPersonLaser";
Beam.Parent = Attachment;
Beam.Enabled = false;
local u91 = Beam:Clone();
u91.Name = "ThirdPersonLaser";
u91.Parent = Attachment;
u91.Enabled = false;
local u92 = Vector3.new(0, 0, 0);
local u93 = Vector3.new(0, 0, 0);

if HumanoidRootPart:FindFirstChild("Died") then
    HumanoidRootPart.Died.Volume = 0;
end;

if GameConfig.lockFirstPerson then
    LocalPlayer.CameraMode = Enum.CameraMode.Classic;
end;

rig = ViewMod.RigModel(LocalPlayer);

if u4 == Enum.HumanoidRigType.R6 then
    local v94 = rig["Right Arm"];
    rig["Left Arm"].Color = Parent["Left Arm"].Color;
    v94.Color = Parent["Right Arm"].Color;

    for _, descendant in ipairs(rig:GetDescendants()) do
        if descendant.Name == "Skin" then
            if descendant.Parent.Name == "Left Arm" then
                descendant.Color = Parent["Left Arm"].Color;
            elseif descendant.Parent.Name == "Right Arm" then
                descendant.Color = Parent["Right Arm"].Color;
            end;
        end;
    end;
else
    local v95 = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" };

    for i = 1, #v95 do
        rig[v95[i]].Color = Parent[v95[i]].Color;
    end;
end;

local Humanoid2 = Instance.new("Humanoid", rig);
Humanoid2.RigType = u4;

for _, v in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
    if v ~= Enum.HumanoidStateType.None then
        Humanoid2:SetStateEnabled(v, false);
    end;
end;

local Animator = Instance.new("Animator", Humanoid2);
local Shirt = Instance.new("Shirt", rig);
local AnimBase = rig.AnimBase;
AnimBase.CFrame = u75;
rig.Parent = CurrentCamera;
local u96 = Parent:FindFirstChild("WeaponRig") or Parent:WaitForChild("WeaponRig");
local Animator2 = u96:WaitForChild("AnimationController").Animator;
local u97 = nil;
local Gunsmith = require(Modules.Gunsmith);
local attStats = Gunsmith.attStats;

local function PlayRepSound(p98) -- Line: 276
    -- upvalues: u40 (ref), u57 (ref), u59 (ref), attStats (ref), u56 (ref), u38 (ref), HumanoidRootPart (copy), Debris (copy), u23 (copy)
    if not u40 and u57 then
        local v99 = u59.Grip:FindFirstChild(p98);

        if attStats.newFireSound and p98 == "Fire" then
            v99 = u59[attStats.newMuzzleDevice].Main.Fire;
        end;

        if v99 and u56 then
            if u38 then
                v99:Play();
            else
                local v100 = v99:Clone();
                v100.Parent = HumanoidRootPart;
                v100:Play();
                Debris:AddItem(v100, v100.TimeLength);
            end;

            u23:Fire(p98, u38);
        end;
    end;
end;

local function GetCurrentWepStats() -- Line: 296
    -- upvalues: u57 (ref)
    return u57;
end;

local function IsLoaded() -- Line: 299
    -- upvalues: u60 (ref)
    return u60.MagAmmo.Value > 0;
end;

local function GetMuzzlePoint(p101) -- Line: 302
    return p101.Grip.Muzzle;
end;

local function PlayCharSound(p102) -- Line: 305
    -- upvalues: SPH_Assets (copy), HumanoidRootPart (copy), Debris (copy), u27 (copy)
    local v103 = SPH_Assets.Sounds:FindFirstChild(p102);

    if v103 then
        local v104 = v103:GetChildren();
        local v105 = v104[math.random(#v104)]:Clone();
        v105.Parent = HumanoidRootPart;
        v105:Play();
        Debris:AddItem(v105, v105.TimeLength);
        u27:Fire(p102);
    end;
end;

local function IsMovingForward() -- Line: 316
    -- upvalues: Humanoid (copy), HumanoidRootPart (copy), GameConfig (copy)
    if Humanoid.MoveDirection.Magnitude <= 0 then
        return false;
    end;

    return HumanoidRootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection.Unit) >= (GameConfig.sprintForwardThreshold or 0.5);
end;

local function ChangeLean(p106) -- Line: 322
    -- upvalues: GameConfig (copy), u87 (ref), PlayCharSound (copy), u32 (copy)
    if not GameConfig.canLean then
        return;
    end;

    if p106 ~= u87 then
        PlayCharSound("Lean");
    end;

    u87 = p106;
    u32:Fire(p106);
end;

local function MoveBolt(p107, p108) -- Line: 328
    -- upvalues: BGLOPP (copy), u59 (ref), u57 (ref), u60 (ref), u96 (copy), PlayRepSound (copy), u25 (copy)
    BGLOPP.MoveBolt(u59, u57, p107, u60.MagAmmo.Value);
    BGLOPP.MoveBolt(u96.Weapon:FindFirstChildWhichIsA("Model"), u57, p107, u60.MagAmmo.Value);

    if u60.MagAmmo.Value <= 0 and not p108 then
        PlayRepSound("Empty");
    end;

    u25:Fire(p107, u60.MagAmmo.Value);
end;

local function ToggleADS(p109) -- Line: 336
    -- upvalues: u57 (ref), attStats (ref), u5 (copy), TweenService (copy), u6 (copy)
    if u57 and u57.ADSEnabled or attStats and attStats.ADSEnabled then
        local v110 = not u57.aimTime and 0.2 or u57.aimTime / 20;

        if attStats.aimTime then
            v110 = v110 * attStats.aimTime;
        end;

        local v111 = TweenInfo.new(v110, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, v110);

        if not p109 then
            for _, v in ipairs(u5) do
                if v.Parent then
                    TweenService:Create(v, v111, {
                        Transparency = 0
                    }):Play();
                end;
            end;

            for _, v in ipairs(u6) do
                if v.Parent then
                    TweenService:Create(v, v111, {
                        Transparency = 1
                    }):Play();
                end;
            end;

            return;
        end;

        if p109 then
            for _, v in ipairs(u5) do
                if v.Parent then
                    TweenService:Create(v, v111, {
                        Transparency = 1
                    }):Play();
                end;
            end;

            for _, v in ipairs(u6) do
                if v.Parent then
                    TweenService:Create(v, v111, {
                        Transparency = 0
                    }):Play();
                end;
            end;
        end;
    end;
end;

local function GetThirdPersonGunModel() -- Line: 374
    -- upvalues: u14 (ref), u96 (copy)
    if not (u14 and u14.Parent) then
        u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
    end;

    return u14;
end;

local function StopAnimation(p112, p113) -- Line: 380
    -- upvalues: u83 (copy)
    if not u83[p112] then
        return;
    end;

    if p113 then
        u83[p112]:Stop(p113);
        u83[p112 .. "ThirdPerson"]:Stop(p113);

        return;
    end;

    u83[p112]:Stop();
    u83[p112 .. "ThirdPerson"]:Stop();
end;

local function SwitchFireMode() -- Line: 392
    -- upvalues: u54 (ref), u57 (ref), u26 (copy)
    while true do
        u54 = u54 + 1;

        if u54 > 4 then
            u54 = 0;
            break;
        end;

        if u57.fireSwitch[u54] then
            break;
        end;
    end;

    u26:Fire(u54);
end;

local function PlayAnimation(u114, p115, u116, p117) -- Line: 399
    -- upvalues: u83 (copy), u76 (ref), Animator (copy), Animator2 (copy), u59 (ref), PlayRepSound (copy), u56 (ref), u61 (ref), u57 (ref), PlayAnimation (copy), u24 (copy), u50 (ref), u60 (ref), attStats (ref), MoveBolt (copy), u54 (ref), u26 (copy), u14 (ref), u96 (copy), u31 (copy), u30 (copy)
    local v118 = p115 or {};
    local u119 = nil;
    local v120 = nil;

    if u83[u114] then
        u119 = u83[u114];
        v120 = u83[u114 .. "ThirdPerson"];
    elseif u114 and u76:FindFirstChild(u114) then
        u119 = Animator:LoadAnimation(u76[u114]);
        u119.Looped = v118.looped or false;
        u119.Priority = v118.priority or Enum.AnimationPriority.Action;
        u83[u114] = u119;
        v120 = Animator2:LoadAnimation(u76[u114]);
        v120.Looped = v118.looped or false;
        v120.Priority = v118.priority or Enum.AnimationPriority.Action;
        u83[u114 .. "ThirdPerson"] = v120;
        u119.KeyframeReached:Connect(function(p121) -- Line: 414
            -- upvalues: u59 (ref), PlayRepSound (ref), u56 (ref), u61 (ref), u57 (ref), u114 (copy), u83 (ref), PlayAnimation (ref), u24 (ref), u119 (copy), u50 (ref), u60 (ref), attStats (ref), MoveBolt (ref), u54 (ref), u26 (ref), u14 (ref), u96 (ref), u31 (ref), u30 (ref)
            if u59.Grip:FindFirstChild(p121) then
                PlayRepSound(p121);
            end;

            if p121 == "MagIn" then
                if u56 then
                    u61 = true;
                    local v122;

                    if u56.BoltReady.Value then
                        v122 = u57.boltChamber;
                    else
                        v122 = u57.boltClose;
                    end;

                    local v123 = u114;

                    if u83[v123] then
                        u83[v123]:Stop(0.4);
                        u83[v123 .. "ThirdPerson"]:Stop(0.4);
                    end;

                    PlayAnimation(v122, {
                        transSpeed = 0.05,
                        priority = Enum.AnimationPriority.Action2
                    });
                end;

                local v124 = u57.bulletHandler and u59:FindFirstChild(u57.bulletHolder);

                if v124 then
                    for _, child in v124:GetChildren() do
                        if child:IsA("BasePart") and string.sub(child.Name, 1, 6) == "Bullet" then
                            child.Transparency = 0;
                        end;
                    end;
                end;

                u24:Fire();

                if u57.magType > 1 then
                    u119.DidLoop:Once(function() -- Line: 440
                        -- upvalues: u114 (ref), u83 (ref)
                        local v125 = u114;

                        if not u83[v125] then
                            return;
                        end;

                        u83[v125]:Stop();
                        u83[v125 .. "ThirdPerson"]:Stop();
                    end);
                end;
            else
                if p121 == "ShellInsert" or p121 == "BulletInsert" then
                    if u50 then
                        u50 = false;
                        u119.Looped = false;
                        u119.Stopped:Once(function() -- Line: 448
                            -- upvalues: u56 (ref), u119 (ref), u83 (ref), u57 (ref), PlayAnimation (ref), u61 (ref)
                            if not u56 then
                                return;
                            end;

                            local Name = u119.Name;

                            if u83[Name] then
                                u83[Name]:Stop();
                                u83[Name .. "ThirdPerson"]:Stop();
                            end;

                            if u56.BoltReady.Value and not u57.openBolt then
                                u61 = false;

                                return;
                            end;

                            PlayAnimation(u57.boltClose, {
                                priority = Enum.AnimationPriority.Action2
                            });
                        end);
                    elseif u60.MagAmmo.Value + 1 >= u60.MagAmmo.MaxValue or u60.ArcadeAmmoPool.Value - 1 <= 0 then
                        u119.DidLoop:Once(function() -- Line: 458
                            -- upvalues: u56 (ref), u119 (ref), u83 (ref), u57 (ref), PlayAnimation (ref), u61 (ref)
                            if not u56 then
                                return;
                            end;

                            local Name = u119.Name;

                            if u83[Name] then
                                u83[Name]:Stop();
                                u83[Name .. "ThirdPerson"]:Stop();
                            end;

                            if u56.BoltReady.Value and (u57.operationType ~= 3 and not u57.openBolt) then
                                u61 = false;

                                return;
                            end;

                            PlayAnimation(u57.boltClose, {
                                priority = Enum.AnimationPriority.Action2
                            });
                        end);
                    else
                        local _ = u57.openBolt;
                    end;

                    local v126 = u57.bulletHolder and u59:FindFirstChild(u57.bulletHolder);
                    local v127 = v126 and v126:FindFirstChild("Bullet" .. u60.MagAmmo.MaxValue - u60.MagAmmo.Value);

                    if v127 then
                        v127.Transparency = 0;
                    end;

                    u24:Fire();

                    return;
                end;

                if p121 == "ClipInsertEnd" then
                    local v128 = u60.MagAmmo.MaxValue - u60.MagAmmo.Value;
                    local v129 = u57.clipSize or (attStats.magazineCapacity or u57.magazineCapacity);
                    local reloadSpeedModifier = u57.reloadSpeedModifier;

                    if attStats.reloadSpeedModifier then
                        reloadSpeedModifier = reloadSpeedModifier * attStats.reloadSpeedModifier;
                    end;

                    if v128 > 0 then
                        local Name = u119.Name;

                        if u83[Name] then
                            u83[Name]:Stop();
                            u83[Name .. "ThirdPerson"]:Stop();
                        end;

                        if v129 <= v128 then
                            PlayAnimation(u57.clipReloadAnim, {
                                looped = true,
                                transSpeed = 0.17,
                                speed = reloadSpeedModifier,
                                priority = Enum.AnimationPriority.Action2
                            });

                            return;
                        end;

                        PlayAnimation(u57.reloadAnim, {
                            transSpeed = 0.17,
                            speed = reloadSpeedModifier,
                            priority = Enum.AnimationPriority.Action2
                        }, "Reload");
                    end;
                else
                    if p121 == "ClipInsert" then
                        u24:Fire();

                        return;
                    end;

                    if p121 == "SlideRelease" or p121 == "BoltClose" then
                        u61 = false;
                        MoveBolt(CFrame.new(), true);

                        return;
                    end;

                    if p121 == "Equip" then
                        return;
                    end;

                    if p121 == "Switch" and not u61 then
                        while true do
                            u54 = u54 + 1;

                            if u54 > 4 then
                                u54 = 0;
                                break;
                            end;

                            if u57.fireSwitch[u54] then
                                break;
                            end;
                        end;

                        u26:Fire(u54);

                        return;
                    end;

                    if p121 == "MagGrab" then
                        if u59 and (u57.projectile ~= "Bullet" and u59:FindFirstChild(u57.projectile)) then
                            local v130 = u59:FindFirstChild(u57.projectile);
                            v130.LocalTransparencyModifier = 0;

                            for _, descendant in ipairs(v130:GetDescendants()) do
                                if descendant:IsA("BasePart") then
                                    descendant.LocalTransparencyModifier = 0;
                                end;
                            end;

                            if not (u14 and u14.Parent) then
                                u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                            end;

                            local v131 = u14:FindFirstChild(u57.projectile);
                            v131.LocalTransparencyModifier = 0;

                            for _, descendant in ipairs(v131:GetDescendants()) do
                                if descendant:IsA("BasePart") then
                                    descendant.LocalTransparencyModifier = 0;
                                end;
                            end;

                            u31:Fire();
                        end;
                    elseif p121 == "BoltOpen" then
                        u30:Fire();
                    end;
                end;
            end;
        end);
        u119.Stopped:Connect(function() -- Line: 522
            -- upvalues: u116 (copy), u61 (ref), u57 (ref), u59 (ref)
            if u116 == "Equip" then
                return;
            end;

            if u116 == "Reload" then
                u61 = false;

                if u57 and (u59 and u59:FindFirstChild(u57.projectile)) then
                    local v132 = u59:FindFirstChild(u57.projectile);
                    v132.LocalTransparencyModifier = 0;

                    for _, descendant in ipairs(v132:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            descendant.LocalTransparencyModifier = 0;
                        end;
                    end;
                end;
            end;
        end);
    end;

    if u119 and not p117 then
        if u57 and u114 == u57.sprintAnim then
            v120:Play(v118.transSpeed or 0);
            v120:AdjustSpeed(v118.speed or 1);

            return u119;
        end;

        u119:Play(v118.transSpeed or 0);
        u119:AdjustSpeed(v118.speed or 1);
        v120:Play(v118.transSpeed or 0);
        v120:AdjustSpeed(v118.speed or 1);
    end;

    return u119;
end;

local function ChangeHoldStance(p133) -- Line: 553
    -- upvalues: u62 (ref), u44 (ref), u45 (ref), u83 (copy), u57 (ref), PlayAnimation (copy)
    if u62 then
        return;
    end;

    if u44 == p133 and u45 then
        local Name = u45.Name;

        if u83[Name] then
            u83[Name]:Stop(0.3);
            u83[Name .. "ThirdPerson"]:Stop(0.3);
        end;

        u45 = nil;
        u44 = 0;

        return;
    end;

    u44 = p133;

    if u45 then
        local Name = u45.Name;

        if u83[Name] then
            u83[Name]:Stop(0.3);
            u83[Name .. "ThirdPerson"]:Stop(0.3);
        end;
    end;

    local v134 = nil;

    if u44 == 1 and u57.holdUpAnim then
        v134 = u57.holdUpAnim;
    elseif u44 == 2 and u57.patrolAnim then
        v134 = u57.patrolAnim;
    elseif u44 == 3 and u57.holdDownAnim then
        v134 = u57.holdDownAnim;
    end;

    if not v134 then
        if u45 then
            u45 = nil;
        end;

        return;
    end;

    u45 = PlayAnimation(v134, {
        looped = true,
        transSpeed = 0.3,
        priority = Enum.AnimationPriority.Action
    });
    u45:Play();
end;

local function ChamberAnim() -- Line: 580
    -- upvalues: u56 (ref), u54 (ref), u57 (ref), u61 (ref), ChangeHoldStance (copy), PlayAnimation (copy)
    local v135;

    if u56.BoltReady.Value or u54 == 5 then
        v135 = u57.boltChamber;
    else
        v135 = u57.boltClose;
    end;

    if v135 then
        u61 = true;
        ChangeHoldStance(0);
        PlayAnimation(v135, {
            transSpeed = 0.05,
            priority = Enum.AnimationPriority.Action2
        }).Stopped:Once(function() -- Line: 591
        end);
    end;
end;

local function IdleAnim() -- Line: 595
    -- upvalues: PlayAnimation (copy), u57 (ref)
    PlayAnimation(u57.idleAnim, {
        looped = true,
        priority = Enum.AnimationPriority.Idle
    });
end;

local function EquipAnim() -- Line: 598
    -- upvalues: PlayAnimation (copy), u57 (ref), u38 (ref), u42 (ref), u59 (ref)
    PlayAnimation(u57.equipAnim, {
        priority = Enum.AnimationPriority.Action2
    }, "Equip");
    task.wait(0.1);

    if u38 then
        u42 = true;
    end;

    if not u57 then
        return;
    end;

    local v136 = u59:FindFirstChild(u57.projectile);

    if v136 and u57.projectile ~= "Bullet" then
        v136.LocalTransparencyModifier = 1;

        for _, descendant in ipairs(v136:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.LocalTransparencyModifier = 1;
            end;
        end;
    end;
end;

local function ReloadAnim() -- Line: 613
    -- upvalues: u56 (ref), u50 (ref), ChangeHoldStance (copy), u61 (ref), u57 (ref), attStats (ref), u60 (ref), PlayAnimation (copy), u97 (ref), u59 (ref)
    if not u56 then
        return;
    end;

    u50 = false;
    ChangeHoldStance(0);
    u61 = true;
    local reloadSpeedModifier = u57.reloadSpeedModifier;

    if attStats.reloadSpeedModifier then
        reloadSpeedModifier = reloadSpeedModifier * attStats.reloadSpeedModifier;
    end;

    if u57.operationType == 3 or u57.operationType == 2 and u60.MagAmmo.Value <= 0 then
        local v137 = PlayAnimation(u57.boltOpen, {
            transSpeed = 0.17,
            speed = reloadSpeedModifier,
            priority = Enum.AnimationPriority.Action2
        });

        if not v137 then
            warn("【 SPEARHEAD 】 " .. "To use operation type " .. u57.operationType .. ", a \'boltOpen\' animation is required.");
            u61 = false;

            return;
        end;

        v137.Stopped:Once(function() -- Line: 627
            -- upvalues: u57 (ref), u60 (ref), attStats (ref), PlayAnimation (ref), reloadSpeedModifier (ref), u97 (ref), u59 (ref)
            if u57.magType == 3 and (u60.MagAmmo.MaxValue - u60.MagAmmo.Value >= (u57.clipSize or (attStats.magazineCapacity or u57.magazineCapacity)) and u60.ArcadeAmmoPool.Value >= (u57.clipSize or (attStats.magazineCapacity or u57.magazineCapacity))) then
                PlayAnimation(u57.clipReloadAnim, {
                    looped = true,
                    transSpeed = 0.17,
                    speed = reloadSpeedModifier,
                    priority = Enum.AnimationPriority.Action2
                });

                return;
            end;

            if u97 and u97.Name ~= u59.Name then
                return;
            end;

            local v138 = PlayAnimation(u57.reloadAnim, {
                transSpeed = 0.17,
                looped = true,
                speed = reloadSpeedModifier,
                priority = Enum.AnimationPriority.Action2
            }, "Reload");

            if u57.magType > 1 then
                v138.Looped = true;
            end;
        end);
    else
        PlayAnimation(u57.reloadAnim, {
            transSpeed = 0.17,
            speed = reloadSpeedModifier,
            priority = Enum.AnimationPriority.Action2
        }, "Reload");
    end;
end;

local function RefreshViewmodel() -- Line: 642
    -- upvalues: u38 (ref), u39 (ref), u42 (ref), Parent (copy), Shirt (copy), u4 (ref), PlayAnimation (copy), u57 (ref), Mods (copy), LocalPlayer (copy)
    if u38 and not u39 then
        u42 = true;
    end;

    local v139 = Parent:FindFirstChildWhichIsA("Shirt");

    if v139 then
        Shirt.ShirtTemplate = v139.ShirtTemplate;
    end;

    if u4 == Enum.HumanoidRigType.R6 then
        local v140 = rig["Right Arm"];
        rig["Left Arm"].Color = Parent["Left Arm"].Color;
        v140.Color = Parent["Right Arm"].Color;

        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant.Name == "Skin" then
                if descendant.Parent.Name == "Left Arm" then
                    descendant.Color = Parent["Left Arm"].Color;
                elseif descendant.Parent.Name == "Right Arm" then
                    descendant.Color = Parent["Right Arm"].Color;
                end;
            end;
        end;
    else
        local v141 = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" };

        for i = 1, #v141 do
            local v142 = Parent:FindFirstChild(v141[i]);
            local v143 = rig:FindFirstChild(v141[i]);

            if v142 and v143 then
                v143.Color = v142.Color;
            end;
        end;
    end;

    PlayAnimation(u57.idleAnim, {
        looped = true,
        priority = Enum.AnimationPriority.Idle
    });

    if Mods.onViewmodelRefresh then
        Mods.onViewmodelRefresh(LocalPlayer, rig);
    end;
end;

local function ResetHead() -- Line: 675
    -- upvalues: u42 (ref)
    u42 = false;
end;

local function GetSineOffset(p144) -- Line: 678
    local v145 = tick() * p144 * 1.3;

    return math.sin(v145) * 0.3;
end;

local function LerpNumber(p146, p147, p148) -- Line: 681
    return p146 + (p147 - p146) * p148;
end;

local LocalPlayer2 = game.Players.LocalPlayer;

local function ToggleAiming(p149) -- Line: 685
    -- upvalues: Parent (copy), ChangeHoldStance (copy), u62 (ref), attStats (ref), u86 (ref), u57 (ref), ToggleADS (copy), UserInputService (copy), u89 (ref), PlayRepSound (copy), GameConfig (copy), LocalPlayer2 (copy), CameraMode (copy)
    Parent:SetAttribute("Aiming", p149);

    if p149 then
        ChangeHoldStance(0);
        u62 = true;

        if attStats.ADSEnabled and attStats.ADSEnabled[u86] or u57.ADSEnabled and u57.ADSEnabled[u86] then
            ToggleADS(true);
        else
            ToggleADS(false);
        end;

        UserInputService.MouseDeltaSensitivity = u89;
        PlayRepSound("AimUp");

        if not GameConfig.lockFirstPerson then
            LocalPlayer2.CameraMode = Enum.CameraMode.LockFirstPerson;
        end;
    else
        u62 = false;
        ToggleADS(false);
        UserInputService.MouseDeltaSensitivity = 1;
        PlayRepSound("AimDown");

        if u57 then
            local _ = u57.aimTime / 2;
        end;

        if not GameConfig.lockFirstPerson then
            LocalPlayer2.CameraMode = CameraMode;
        end;
    end;
end;

local u150 = 0;

local function UpdateViewmodelPosition(p151) -- Line: 717
    -- upvalues: u150 (ref), AnimBase (copy), CurrentCamera (copy), u63 (ref), u64 (ref), u67 (ref), u59 (ref), u86 (ref), attStats (ref), u69 (ref), u57 (ref), u62 (ref), u68 (ref), Parent (copy), u38 (ref), u96 (copy), u15 (copy), u12 (ref), GameConfig (copy), u43 (ref), u74 (ref), ChangeHoldStance (copy), PlayAnimation (copy), ToggleADS (copy), UserInputService (copy), PlayRepSound (copy), LocalPlayer2 (copy), CameraMode (copy), u83 (copy), u52 (ref), ToggleAiming (copy), u58 (ref), HumanoidRootPart (copy), u87 (ref), u33 (ref), u72 (copy), u70 (ref), u71 (ref), zero (ref), u16 (copy), u93 (ref), u92 (ref), u42 (ref), u75 (copy)
    u150 = 1 / p151;
    AnimBase.CFrame = CFrame.new((CurrentCamera.CFrame * u63).Position);

    if u64 then
        local v152 = AnimBase;
        v152.CFrame = v152.CFrame * u67;
    else
        local v153 = AnimBase;
        v153.CFrame = v153.CFrame * (CurrentCamera.CFrame - CurrentCamera.CFrame.Position);
    end;

    local v154 = AnimBase;
    v154.CFrame = v154.CFrame * CFrame.new(0, 0, 0);
    local v155 = u59:FindFirstChild("AimPart" .. u86) or u59.AimPart;

    if attStats.aimParts and attStats.aimParts["AimPart" .. u86] then
        v155 = u59[attStats.aimParts["AimPart" .. u86]]:FindFirstChild("AimPart" .. u86);
    end;

    u69 = v155.CFrame:ToObjectSpace(CurrentCamera.CFrame);
    local aimTime = u57.aimTime;

    if attStats.aimTime then
        aimTime = aimTime * attStats.aimTime;
    end;

    if u62 then
        u68 = u68:Lerp(u69, 0.7 / aimTime * 0.3 * p151 * 60);
    else
        u68 = u68:Lerp(CFrame.new(), 0.7 / aimTime * 0.3 * p151 * 60);
    end;

    local v156 = AnimBase;
    v156.CFrame = v156.CFrame * u68;
    local gunLength = u57.gunLength;

    if attStats.gunLength then
        gunLength = gunLength + attStats.gunLength;
    end;

    local Head = Parent:FindFirstChild("Head");
    local v157;

    if u38 and Head then
        v157 = Head.Position;
    else
        v157 = u96.AnimBase.Position;
    end;

    local v158 = workspace:Raycast(v157, CurrentCamera.CFrame.LookVector * gunLength, u15);
    u12 = v158 and gunLength - (v157 - v158.Position).Magnitude or nil;
    local v159 = u12;

    if v159 then
        if GameConfig.pushBackViewmodel and v159 > 0 then
            local v160;

            if u43 then
                v160 = v159 / 2;
            else
                v160 = v159;
            end;

            local v161 = u74;
            u74 = v161 + (v160 - v161) * (p151 * 12);
        else
            local v162 = u74;
            u74 = v162 + (0 - v162) * (p151 * 12);
        end;

        if GameConfig.raiseGunAtWall then
            if u57.maxPushback <= v159 then
                if not u43 then
                    ChangeHoldStance(0);
                    PlayAnimation(u57.holdUpAnim, {
                        looped = true,
                        transSpeed = 0.3,
                        priority = Enum.AnimationPriority.Action
                    });
                    u43 = true;

                    if u62 then
                        Parent:SetAttribute("Aiming", false);
                        u62 = false;
                        ToggleADS(false);
                        UserInputService.MouseDeltaSensitivity = 1;
                        PlayRepSound("AimDown");

                        if u57 then
                            local _ = u57.aimTime / 2;
                        end;

                        if not GameConfig.lockFirstPerson then
                            LocalPlayer2.CameraMode = CameraMode;
                        end;
                    end;
                end;
            elseif u43 then
                local holdUpAnim = u57.holdUpAnim;

                if u83[holdUpAnim] then
                    u83[holdUpAnim]:Stop(0.3);
                    u83[holdUpAnim .. "ThirdPerson"]:Stop(0.3);
                end;

                u43 = false;

                if u52 and (not u62 and u38) then
                    ToggleAiming(true);
                end;
            end;
        end;
    else
        if u43 then
            local holdUpAnim = u57.holdUpAnim;

            if u83[holdUpAnim] then
                u83[holdUpAnim]:Stop(0.3);
                u83[holdUpAnim .. "ThirdPerson"]:Stop(0.3);
            end;
        end;

        u43 = false;

        if u52 and (not u62 and (u38 and not u58)) then
            ToggleAiming(true);
        end;

        local v163 = u74;
        u74 = v163 + (0 - v163) * (p151 * 12);
        local v164 = u74;
        endshbackOffset = v164 + (0 - v164) * (p151 * 12);
    end;

    local v165 = AnimBase;
    v165.CFrame = v165.CFrame * CFrame.new(0, 0, u74);
    local v166 = HumanoidRootPart.CFrame:VectorToObjectSpace(HumanoidRootPart.Velocity);
    local v167;

    if u62 then
        v167 = 0;
    else
        local v168 = math.clamp(-v166.X, -GameConfig.maxStrafeRoll, GameConfig.maxStrafeRoll) + -u87 * (GameConfig.maxStrafeRoll * 0.4);
        v167 = math.clamp(v168, -GameConfig.maxStrafeRoll, GameConfig.maxStrafeRoll);
    end;

    if GameConfig.cameraTilting then
        v167 = v167 / 2;
    end;

    local v169 = u33;
    u33 = v169 + (v167 - v169) * (p151 * 0.07 * 60);
    local v170 = AnimBase;
    v170.CFrame = v170.CFrame * CFrame.Angles(0, 0, (math.rad(u33)));
    u70 = u70:Lerp(u58 and not u62 and u72.sprintRotation or CFrame.new(), p151 * 0.1 * 60);
    local v171 = AnimBase;
    v171.CFrame = v171.CFrame * u70;
    local v172 = CFrame.new();

    if not u62 then
        if u87 < 0 then
            v172 = u72.leanLeftRotation;
        elseif u87 > 0 then
            v172 = u72.leanRightRotation;
        end;
    end;

    u71 = u71:Lerp(v172, p151 * 0.07 * 60);
    local v173 = AnimBase;
    v173.CFrame = v173.CFrame * u71;
    local v174 = UserInputService:GetMouseDelta();
    local v175 = zero;

    if GameConfig.hipfireMove and (not u62 or u62 and GameConfig.offCenterAiming) then
        local hipfireMoveX = GameConfig.hipfireMoveX;
        local hipfireMoveY = GameConfig.hipfireMoveY;

        if u62 then
            hipfireMoveX = hipfireMoveX / 4;
            hipfireMoveY = hipfireMoveY / 4;
        end;

        local v176 = math.clamp(v175.X - v174.X * GameConfig.hipfireMoveSpeed * p151 * 60, -hipfireMoveX, hipfireMoveX);
        local v177 = math.clamp(v175.Y - v174.Y * GameConfig.hipfireMoveSpeed * p151 * 60, -hipfireMoveY, hipfireMoveY);
        zero = Vector2.new(v176, v177);
    else
        zero = zero:Lerp(Vector2.zero, 0.3);
    end;

    local v178 = AnimBase;
    v178.CFrame = v178.CFrame * CFrame.Angles(math.rad(zero.Y), math.rad(zero.X), 0);
    u16:shove((Vector3.new(-v174.X / 500, v174.Y / 200, 0)));
    local v179 = u16:update(p151);
    local v180 = AnimBase;
    v180.CFrame = v180.CFrame * CFrame.new(v179.X, v179.Y, 0);
    local v181 = tick() * 0.15;
    local breathingDist = GameConfig.breathingDist;

    if u62 then
        breathingDist = breathingDist * GameConfig.breathingAimMultiplier;
    end;

    local v182 = AnimBase;
    v182.CFrame = v182.CFrame * CFrame.new(breathingDist * math.sin(v181 * GameConfig.breathingSpeed / 2), breathingDist * math.sin(v181 * GameConfig.breathingSpeed), 0);
    local _ = u57.recoil;
    local _ = u57.gunRecoil;
    local v183 = AnimBase;
    v183.CFrame = v183.CFrame * CFrame.Angles(math.rad(u93.X), math.rad(u93.Y), 0);
    local v184 = AnimBase;
    v184.CFrame = v184.CFrame * CFrame.new(0, 0, u93.Z);
    local v185 = CurrentCamera;
    v185.CFrame = v185.CFrame * CFrame.Angles(math.rad(u92.X), math.rad(u92.Y), (math.rad(u92.Z)));

    if not u42 then
        local v186 = AnimBase;
        v186.CFrame = v186.CFrame * u75;
    end;
end;

local function ToggleSprint(p187) -- Line: 850
    -- upvalues: u58 (ref), RequestSprintChange (copy), Parent (copy), u62 (ref), ToggleADS (copy), UserInputService (copy), PlayRepSound (copy), u57 (ref), GameConfig (copy), LocalPlayer2 (copy), CameraMode (copy), ChangeHoldStance (copy), u36 (ref), PlayAnimation (copy), u83 (copy)
    u58 = p187;
    RequestSprintChange:FireServer(p187);
    Parent:SetAttribute("Sprinting", p187);

    if p187 then
        if u62 then
            Parent:SetAttribute("Aiming", false);
            u62 = false;
            ToggleADS(false);
            UserInputService.MouseDeltaSensitivity = 1;
            PlayRepSound("AimDown");

            if u57 then
                local _ = u57.aimTime / 2;
            end;

            if not GameConfig.lockFirstPerson then
                LocalPlayer2.CameraMode = CameraMode;
            end;
        end;

        ChangeHoldStance(0);
        UserInputService.MouseDeltaSensitivity = 1;
        u36 = false;

        if u57 and u57.sprintAnim then
            PlayAnimation(u57.sprintAnim, {
                looped = true,
                transSpeed = 0.2,
                priority = Enum.AnimationPriority.Action
            });
        end;
    elseif u57 and u57.sprintAnim then
        local sprintAnim = u57.sprintAnim;

        if u83[sprintAnim] then
            u83[sprintAnim]:Stop(0.2);
            u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
        end;
    end;
end;

local function ChangeWalkSpeed(p188) -- Line: 875
    -- upvalues: getArmorSpeedReduction (copy), walkSpeed (ref)
    local v189 = p188 - getArmorSpeedReduction();
    walkSpeed = math.max(v189, 4);
end;

task.spawn(function() -- Line: 882
    -- upvalues: LocalPlayer2 (copy), getArmorSpeedReduction (copy), JumpPower (ref), u72 (copy)
    while true do
        task.wait(3);
        local Character = LocalPlayer2.Character;

        if Character then
            Character = Character:FindFirstChildOfClass("Humanoid");
        end;

        if Character then
            local v190 = getArmorSpeedReduction();
            JumpPower = math.max(u72.defaultJumpPower - v190 * 1.4, 15);
            Character.JumpPower = JumpPower;
        end;
    end;
end);
local HipHeight = LocalPlayer2.Character:WaitForChild("Humanoid").HipHeight;

local function ChangeStance(p191) -- Line: 898
    -- upvalues: u77 (ref), u82 (ref), GameConfig (copy), u78 (copy), getArmorSpeedReduction (copy), walkSpeed (ref), u4 (ref), HipHeight (copy), TweenService (copy), Humanoid (copy), PlayCharSound (copy), u79 (copy), u65 (ref), u80 (copy)
    local v192 = u77 + p191;
    local v193 = v192 < 0 and 0 or (v192 > 2 and 2 or v192);
    local v194;

    if u82 then
        v194 = u82.IsPlaying;
    else
        v194 = false;
    end;

    if v193 == 0 then
        script.Parent.MovementLeaning:SetAttribute("DisableLean", false);

        if u82 then
            u82:Stop(GameConfig.stanceChangeTime);
        end;

        u82 = nil;
        u78:Stop(GameConfig.stanceChangeTime);
        local v195 = GameConfig.walkSpeed - getArmorSpeedReduction();
        walkSpeed = math.max(v195, 4);
        local v196 = u4 == Enum.HumanoidRigType.R6 and 0 or HipHeight;
        TweenService:Create(Humanoid, TweenInfo.new(GameConfig.stanceChangeTime), {
            HipHeight = v196
        }):Play();
        PlayCharSound("Uncrouch");
    elseif v193 == 1 then
        script.Parent.MovementLeaning:SetAttribute("DisableLean", false);

        if u82 then
            u82:Stop(GameConfig.stanceChangeTime);
        end;

        u82 = u79;

        if u65 then
            u82:Play(GameConfig.stanceChangeTime);
        end;

        u80:Stop(GameConfig.stanceChangeTime);
        u78:Play(GameConfig.stanceChangeTime);
        local v197 = GameConfig.crouchSpeed - getArmorSpeedReduction();
        walkSpeed = math.max(v197, 4);
        local v198 = u4 == Enum.HumanoidRigType.R6 and 0 or HipHeight;
        TweenService:Create(Humanoid, TweenInfo.new(GameConfig.stanceChangeTime), {
            HipHeight = v198
        }):Play();

        if u77 == 0 then
            PlayCharSound("Crouch");
        elseif u77 == 2 then
            PlayCharSound("Unprone");
        end;
    end;

    if v194 and u82 then
        u82:Play();
    end;

    u77 = v193;
end;

local function refreshSpeed() -- Line: 946
    -- upvalues: u58 (ref), GameConfig (copy), getArmorSpeedReduction (copy), walkSpeed (ref), u77 (ref)
    if u58 then
        local v199 = GameConfig.sprintSpeed - getArmorSpeedReduction();
        walkSpeed = math.max(v199, 4);

        return;
    end;

    if u77 == 1 then
        local v200 = GameConfig.crouchSpeed - getArmorSpeedReduction();
        walkSpeed = math.max(v200, 4);

        return;
    end;

    local v201 = GameConfig.walkSpeed - getArmorSpeedReduction();
    walkSpeed = math.max(v201, 4);
end;

local function watchSlot(p202) -- Line: 955
    -- upvalues: u58 (ref), GameConfig (copy), getArmorSpeedReduction (copy), walkSpeed (ref), u77 (ref)
    local ItemName = p202:FindFirstChild("ItemName");

    if ItemName then
        ItemName:GetPropertyChangedSignal("Value"):Connect(function() -- Line: 958
            -- upvalues: u58 (ref), GameConfig (ref), getArmorSpeedReduction (ref), walkSpeed (ref), u77 (ref)
            if u58 then
                local v203 = GameConfig.sprintSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v203, 4);

                return;
            end;

            if u77 == 1 then
                local v204 = GameConfig.crouchSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v204, 4);

                return;
            end;

            local v205 = GameConfig.walkSpeed - getArmorSpeedReduction();
            walkSpeed = math.max(v205, 4);
        end);
    end;
end;

for _, child in ipairs(Equipment:GetChildren()) do
    watchSlot(child);
end;

ChangeStance(0);
Equipment.ChildAdded:Connect(function(p206) -- Line: 967
    -- upvalues: u58 (ref), GameConfig (copy), getArmorSpeedReduction (copy), walkSpeed (ref), u77 (ref)
    local ItemName = p206:FindFirstChild("ItemName");

    if ItemName then
        ItemName:GetPropertyChangedSignal("Value"):Connect(function() -- Line: 958
            -- upvalues: u58 (ref), GameConfig (ref), getArmorSpeedReduction (ref), walkSpeed (ref), u77 (ref)
            if u58 then
                local v207 = GameConfig.sprintSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v207, 4);

                return;
            end;

            if u77 == 1 then
                local v208 = GameConfig.crouchSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v208, 4);

                return;
            end;

            local v209 = GameConfig.walkSpeed - getArmorSpeedReduction();
            walkSpeed = math.max(v209, 4);
        end);
    end;
end);

local function HandleInput(p210, p211, p212) -- Line: 970
    -- upvalues: UserInputService (copy), u58 (ref), RequestSprintChange (copy), Parent (copy), u57 (ref), u83 (copy), GameConfig (copy), getArmorSpeedReduction (copy), walkSpeed (ref), u77 (ref), ChangeStance (copy), u65 (ref), Humanoid (copy), HumanoidRootPart (copy), ToggleSprint (copy), u87 (ref), PlayCharSound (copy), u32 (copy), u51 (ref), LocalPlayer2 (copy), u56 (ref), u50 (ref), u61 (ref), u36 (ref), u60 (ref), PlayRepSound (copy), u41 (ref), u55 (ref), u28 (copy), u37 (ref), ReloadAnim (copy), u38 (ref), u64 (ref), u43 (ref), u52 (ref), ToggleAiming (copy), u62 (ref), ToggleADS (copy), CameraMode (copy), u59 (ref), attStats (ref), u86 (ref), u53 (ref), u67 (ref), CurrentCamera (copy), u66 (ref), ChangeHoldStance (copy), PlayAnimation (copy), u46 (ref), u91 (copy), u29 (copy), u90 (copy), u47 (ref), u96 (copy)
    local Begin = Enum.UserInputState.Begin;
    local _ = Enum.UserInputState.End;
    local TouchEnabled = UserInputService.TouchEnabled;

    if p210 ~= "SPH_Sprint" then
        if p211 == Begin then
            if p210 == "SPH_ToggleStance" and not Humanoid.Sit then
                if u77 == 0 then
                    ChangeStance(1);

                    if u58 then
                        u58 = false;
                        RequestSprintChange:FireServer(false);
                        Parent:SetAttribute("Sprinting", false);

                        if u57 and u57.sprintAnim then
                            local sprintAnim = u57.sprintAnim;

                            if u83[sprintAnim] then
                                u83[sprintAnim]:Stop(0.2);
                                u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
                            end;
                        end;
                    end;
                elseif u77 > 0 then
                    ChangeStance(-1);
                end;
            elseif p210 == "SPH_LeanLeft" and (u77 < 2 and not (u58 or (Humanoid.Sit or LocalPlayer2.PlayerGui.PauseMenu.Frame.Visible))) then
                if u87 == -1 then
                    if GameConfig.canLean then
                        if u87 ~= 0 then
                            PlayCharSound("Lean");
                        end;

                        u87 = 0;
                        u32:Fire(0);
                    end;
                elseif GameConfig.canLean then
                    if u87 ~= -1 then
                        PlayCharSound("Lean");
                    end;

                    u87 = -1;
                    u32:Fire(-1);
                end;
            elseif p210 == "SPH_LeanRight" and (u77 < 2 and not (u58 or (Humanoid.Sit or LocalPlayer2.PlayerGui.PauseMenu.Frame.Visible))) then
                if u87 == 1 then
                    if GameConfig.canLean then
                        if u87 ~= 0 then
                            PlayCharSound("Lean");
                        end;

                        u87 = 0;
                        u32:Fire(0);
                    end;
                elseif GameConfig.canLean then
                    if u87 ~= 1 then
                        PlayCharSound("Lean");
                    end;

                    u87 = 1;
                    u32:Fire(1);
                end;
            end;
        end;

        if u56 then
            if p210 == "SPH_Trigger" then
                if p211 == Begin then
                    u50 = true;

                    if not (u58 or u61) then
                        u36 = true;

                        if u60.MagAmmo.Value <= 0 and (u56:GetAttribute("FireMode") ~= 5 or u56:GetAttribute("MagAmmo") <= 0) then
                            PlayRepSound("Click");
                        end;
                    end;
                else
                    u36 = false;
                    u41 = true;
                    u55 = 0;
                end;
            elseif p210 == "SPH_DropGun" and p211 == Begin then
                Unequip(u56);
                u28:Fire();
            elseif p210 == "SPH_Reload" and (p211 == Begin and (not u61 and u37)) then
                if u57.infiniteAmmo or u60.ArcadeAmmoPool.Value > 0 then
                    if u57.openBolt and u60.MagAmmo.Value < u60.MagAmmo.MaxValue then
                        ReloadAnim();
                    else
                        if u57.operationType == 4 or u57.operationType == 3 and u60.MagAmmo.Value + 1 >= u60.MagAmmo.MaxValue or u57.operationType == 2 and u60.MagAmmo.Value >= u60.MagAmmo.MaxValue then
                            return Enum.ContextActionResult.Pass;
                        end;

                        ReloadAnim();
                    end;
                end;
            elseif p210 == "SPH_HoldAim" then
                if UserInputService.TouchEnabled or GameConfig.toggleAiming then
                    if p211 == Begin then
                        if u38 and not (u64 or (u43 or u62)) then
                            u52 = true;
                            u58 = false;
                            RequestSprintChange:FireServer(false);
                            Parent:SetAttribute("Sprinting", false);

                            if u57 and u57.sprintAnim then
                                local sprintAnim = u57.sprintAnim;

                                if u83[sprintAnim] then
                                    u83[sprintAnim]:Stop(0.2);
                                    u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
                                end;
                            end;

                            if u77 == 0 then
                                local v213 = GameConfig.walkSpeed - getArmorSpeedReduction();
                                walkSpeed = math.max(v213, 4);
                            end;

                            ToggleAiming(true);
                        else
                            u52 = false;
                            Parent:SetAttribute("Aiming", false);
                            u62 = false;
                            ToggleADS(false);
                            UserInputService.MouseDeltaSensitivity = 1;
                            PlayRepSound("AimDown");

                            if u57 then
                                local _ = u57.aimTime / 2;
                            end;

                            if not GameConfig.lockFirstPerson then
                                LocalPlayer2.CameraMode = CameraMode;
                            end;
                        end;
                    end;
                elseif p211 == Begin and (u38 and not (u64 or u43)) then
                    u52 = true;
                    u58 = false;
                    RequestSprintChange:FireServer(false);
                    Parent:SetAttribute("Sprinting", false);

                    if u57 and u57.sprintAnim then
                        local sprintAnim = u57.sprintAnim;

                        if u83[sprintAnim] then
                            u83[sprintAnim]:Stop(0.2);
                            u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
                        end;
                    end;

                    if u77 == 0 then
                        local v214 = GameConfig.walkSpeed - getArmorSpeedReduction();
                        walkSpeed = math.max(v214, 4);
                    end;

                    ToggleAiming(true);
                elseif not u58 and u62 then
                    u52 = false;
                    Parent:SetAttribute("Aiming", false);
                    u62 = false;
                    ToggleADS(false);
                    UserInputService.MouseDeltaSensitivity = 1;
                    PlayRepSound("AimDown");

                    if u57 then
                        local _ = u57.aimTime / 2;
                    end;

                    if not GameConfig.lockFirstPerson then
                        LocalPlayer2.CameraMode = CameraMode;
                    end;
                end;
            else
                if p210 == "SPH_Chamber" then
                    return Enum.ContextActionResult.Pass;
                end;

                if p210 == "SPH_SwitchSights" and (p211 == Begin and (u62 and (u59:FindFirstChild("AimPart2") or attStats.aimParts and attStats.aimParts.AimPart2))) then
                    local v215 = u86 + 1;

                    if u59:FindFirstChild("AimPart" .. v215) then
                        u86 = v215;
                        PlayRepSound("AimUp");
                    elseif attStats.aimParts then
                        if attStats.aimParts["AimPart" .. v215] then
                            u86 = v215;
                            PlayRepSound("AimUp");
                        else
                            u86 = 1;
                            PlayRepSound("AimDown");
                        end;
                    else
                        u86 = 1;
                        PlayRepSound("AimDown");
                    end;

                    if u86 == 2 then
                        u53 = 60;
                    else
                        u53 = nil;
                    end;

                    if attStats.ADSEnabled and attStats.ADSEnabled[u86] or u57.ADSEnabled and u57.ADSEnabled[u86] then
                        ToggleADS(true);
                    else
                        ToggleADS(false);
                    end;
                elseif p210 == "SPH_Freelook" then
                    if p211 == Begin then
                        u64 = true;
                        Humanoid.AutoRotate = false;
                        u67 = CurrentCamera.CFrame - CurrentCamera.CFrame.Position;
                    else
                        u64 = false;
                        u66 = u67:ToObjectSpace(CurrentCamera.CFrame);
                        u66 = u66 - u66.Position;
                        Humanoid.AutoRotate = true;
                    end;
                elseif p210 == "SPH_HoldUp" and (p211 == Begin and not u61) then
                    ChangeHoldStance(1);
                elseif p210 == "SPH_HoldPatrol" and (p211 == Begin and not u61) then
                    ChangeHoldStance(2);
                elseif p210 == "SPH_HoldDown" and (p211 == Begin and not u61) then
                    ChangeHoldStance(3);
                elseif p210 == "SPH_SwitchFireMode" and p211 == Begin then
                    PlayAnimation(u57.switchAnim, {
                        transSpeed = 0.2
                    });
                elseif p210 == "SPH_ToggleLaser" and p211 == Begin then
                    local Laser = u59.Grip:FindFirstChild("Laser");

                    if attStats.laserOrigin then
                        Laser = u59[attStats.laserOrigin].Main:FindFirstChild("Laser");
                    end;

                    if Laser then
                        u46 = not u46;

                        if not u38 then
                            u91.Enabled = true;
                        end;

                        PlayRepSound("Button");
                        u29:Fire(1, u46);
                        u90.Dot.ImageColor3 = Laser.Color.Value;
                    end;
                elseif p210 == "SPH_ToggleFlashlight" and p211 == Begin then
                    local Flashlight = u59.Grip:FindFirstChild("Flashlight");

                    if Flashlight then
                        local v216 = Flashlight:FindFirstChildWhichIsA("Light");
                        u47 = not u47;
                        v216.Enabled = u47;
                        PlayRepSound("Button");
                        u29:Fire(0, v216.Enabled);

                        if u47 then
                            if not u38 then
                                u96.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true;
                            end;
                        else
                            u96.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false;
                        end;
                    end;

                    if attStats.flashlights_client then
                        if not Flashlight then
                            u47 = not u47;
                        end;

                        for _, v in ipairs(attStats.flashlights_client) do
                            local Flashlight2 = v.Main:FindFirstChild("Flashlight");

                            if Flashlight2 then
                                local v217 = Flashlight2:FindFirstChildWhichIsA("Light");
                                v217.Enabled = u47;
                                PlayRepSound("Button");
                                u29:Fire(0, v217.Enabled);

                                if u47 then
                                    if not u38 then
                                        u96.Weapon:FindFirstChildWhichIsA("Model")[v.Name].Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true;
                                    end;
                                else
                                    u96.Weapon:FindFirstChildWhichIsA("Model")[v.Name].Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;

        return Enum.ContextActionResult.Pass;
    end;

    if TouchEnabled or p212.UserInputType == Enum.UserInputType.Gamepad1 then
        if p211 == Enum.UserInputState.Begin then
            if u58 then
                u58 = false;
                RequestSprintChange:FireServer(false);
                Parent:SetAttribute("Sprinting", false);

                if u57 and u57.sprintAnim then
                    local sprintAnim = u57.sprintAnim;

                    if u83[sprintAnim] then
                        u83[sprintAnim]:Stop(0.2);
                        u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
                    end;
                end;

                local v218 = GameConfig.walkSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v218, 4);
            else
                if u77 == 1 then
                    ChangeStance(-1);
                end;

                if u77 < 2 and u65 then
                    local v219;

                    if Humanoid.MoveDirection.Magnitude <= 0 then
                        v219 = false;
                    else
                        v219 = HumanoidRootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection.Unit) >= (GameConfig.sprintForwardThreshold or 0.5);
                    end;

                    if v219 then
                        ToggleSprint(true);
                        local v220 = GameConfig.sprintSpeed - getArmorSpeedReduction();
                        walkSpeed = math.max(v220, 4);

                        if GameConfig.canLean then
                            if u87 ~= 0 then
                                PlayCharSound("Lean");
                            end;

                            u87 = 0;
                            u32:Fire(0);
                        end;
                    end;
                end;
            end;
        end;
    else
        u51 = p211 == Enum.UserInputState.Begin;
        local v221, v222;

        if u51 and (u77 < 2 and u65) then
            local v223;

            if Humanoid.MoveDirection.Magnitude <= 0 then
                v223 = false;
            else
                v223 = HumanoidRootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection.Unit) >= (GameConfig.sprintForwardThreshold or 0.5);
            end;

            if v223 then
                if u77 == 1 then
                    ChangeStance(-1);
                end;

                ToggleSprint(true);
                local v224 = GameConfig.sprintSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v224, 4);

                if GameConfig.canLean then
                    if u87 ~= 0 then
                        PlayCharSound("Lean");
                    end;

                    u87 = 0;
                    u32:Fire(0);
                end;
            elseif p211 == Enum.UserInputState.End then
                u58 = false;
                RequestSprintChange:FireServer(false);
                Parent:SetAttribute("Sprinting", false);

                if u57 and u57.sprintAnim then
                    v221 = u57.sprintAnim;

                    if u83[v221] then
                        u83[v221]:Stop(0.2);
                        u83[v221 .. "ThirdPerson"]:Stop(0.2);
                    end;
                end;

                v222 = GameConfig.walkSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v222, 4);
            end;
        elseif p211 == Enum.UserInputState.End then
            u58 = false;
            RequestSprintChange:FireServer(false);
            Parent:SetAttribute("Sprinting", false);

            if u57 and u57.sprintAnim then
                v221 = u57.sprintAnim;

                if u83[v221] then
                    u83[v221]:Stop(0.2);
                    u83[v221 .. "ThirdPerson"]:Stop(0.2);
                end;
            end;

            v222 = GameConfig.walkSpeed - getArmorSpeedReduction();
            walkSpeed = math.max(v222, 4);
        end;
    end;

    return Enum.ContextActionResult.Pass;
end;

local function BindAiming() -- Line: 1176
    -- upvalues: ContextActionService (copy), HandleInput (copy), GameConfig (copy)
    ContextActionService:BindActionAtPriority("SPH_HoldAim", HandleInput, GameConfig.mobileButtons, GameConfig.gunInputPriority, unpack(GameConfig.aimGun));
    ContextActionService:SetTitle("SPH_HoldAim", "Aim");
    ContextActionService:SetPosition("SPH_HoldAim", UDim2.fromScale(0.4, -0.2));
end;

local function UnbindAiming() -- Line: 1181
    -- upvalues: ContextActionService (copy)
    ContextActionService:UnbindAction("SPH_HoldAim");
end;

local function BindGunInputs() -- Line: 1184
    -- upvalues: ContextActionService (copy), HandleInput (copy), GameConfig (copy), u38 (ref), BindAiming (copy), LocalPlayer2 (copy)
    ContextActionService:BindActionAtPriority("SPH_Trigger", HandleInput, GameConfig.mobileButtons, GameConfig.gunInputPriority, unpack(GameConfig.fireGun));
    ContextActionService:BindActionAtPriority("SPH_DropGun", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.dropKey));
    ContextActionService:BindActionAtPriority("SPH_Reload", HandleInput, GameConfig.mobileButtons, GameConfig.gunInputPriority, unpack(GameConfig.keyReload));
    ContextActionService:BindActionAtPriority("SPH_Chamber", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.keyChamber));
    ContextActionService:BindActionAtPriority("SPH_SwitchSights", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.sightSwitch));
    ContextActionService:BindActionAtPriority("SPH_Freelook", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.freeLook));
    ContextActionService:BindActionAtPriority("SPH_HoldUp", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.holdUp));
    ContextActionService:BindActionAtPriority("SPH_HoldPatrol", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.holdPatrol));
    ContextActionService:BindActionAtPriority("SPH_HoldDown", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.holdDown));
    ContextActionService:BindActionAtPriority("SPH_SwitchFireMode", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.switchFireMode));
    ContextActionService:BindActionAtPriority("SPH_ToggleLaser", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.toggleLaser));
    ContextActionService:BindActionAtPriority("SPH_ToggleFlashlight", HandleInput, false, GameConfig.gunInputPriority, unpack(GameConfig.toggleFlashlight));

    if u38 then
        BindAiming();
    end;

    ContextActionService:SetTitle("SPH_Trigger", "Fire");
    ContextActionService:SetPosition("SPH_Trigger", UDim2.fromScale(0.05, 0.1));

    if LocalPlayer2.PlayerGui:FindFirstChild("ContextActionGui") then
        for _, descendant in pairs(LocalPlayer2.PlayerGui:FindFirstChild("ContextActionGui"):GetDescendants()) do
            if descendant:IsA("TextLabel") and descendant.Text == "Fire" then
                descendant.Parent.Size = UDim2.fromScale(0.475, 0.6);
            end;
        end;
    end;

    ContextActionService:SetTitle("SPH_Reload", "Reload");
    ContextActionService:SetPosition("SPH_Reload", UDim2.fromScale(-0.1, 0.7));
end;

local function UnbindGunInputs() -- Line: 1213
    -- upvalues: ContextActionService (copy)
    ContextActionService:UnbindAction("SPH_Trigger");
    ContextActionService:UnbindAction("SPH_DropGun");
    ContextActionService:UnbindAction("SPH_Reload");
    ContextActionService:UnbindAction("SPH_HoldAim");
    ContextActionService:UnbindAction("SPH_Chamber");
    ContextActionService:UnbindAction("SPH_SwitchSights");
    ContextActionService:UnbindAction("SPH_Freelook");
    ContextActionService:UnbindAction("SPH_HoldUp");
    ContextActionService:UnbindAction("SPH_HoldPatrol");
    ContextActionService:UnbindAction("SPH_HoldDown");
    ContextActionService:UnbindAction("SPH_SwitchFireMode");
    ContextActionService:UnbindAction("SPH_ToggleLaser");
    ContextActionService:UnbindAction("SPH_ToggleFlashlight");
end;

local function BindCharacterInputs() -- Line: 1228
    -- upvalues: ContextActionService (copy), HandleInput (copy), GameConfig (copy)
    ContextActionService:BindAction("SPH_Sprint", HandleInput, GameConfig.mobileButtons, unpack(GameConfig.keySprint));
    ContextActionService:BindAction("SPH_ToggleStance", HandleInput, GameConfig.mobileButtons, unpack(GameConfig.lowerStance), Enum.KeyCode.ButtonB);
    ContextActionService:BindAction("SPH_LeanLeft", HandleInput, false, unpack(GameConfig.leanLeft), Enum.KeyCode.DPadLeft);
    ContextActionService:BindAction("SPH_LeanRight", HandleInput, false, unpack(GameConfig.leanRight), Enum.KeyCode.DPadRight);
    ContextActionService:SetTitle("SPH_ToggleStance", "Crouch");
    ContextActionService:SetPosition("SPH_ToggleStance", UDim2.fromScale(-2.3, 0.6));
    ContextActionService:SetTitle("SPH_Sprint", "Sprint");
    ContextActionService:SetPosition("SPH_Sprint", UDim2.fromScale(0.7, -0.4));
end;

BindCharacterInputs();

local function UnbindCharacterInputs() -- Line: 1259
    -- upvalues: ContextActionService (copy)
    ContextActionService:UnbindAction("SPH_Sprint");
    ContextActionService:UnbindAction("SPH_ToggleStance");
    ContextActionService:UnbindAction("SPH_LeanLeft");
    ContextActionService:UnbindAction("SPH_LeanRight");
end;

Humanoid.Died:Connect(function() -- Line: 1265
    -- upvalues: u40 (ref), u21 (copy), u56 (ref), u57 (ref), attStats (ref), Parent (copy), u62 (ref), ToggleADS (copy), UserInputService (copy), PlayRepSound (copy), GameConfig (copy), LocalPlayer2 (copy), CameraMode (copy), u42 (ref), AnimBase (copy), u75 (copy), UnbindGunInputs (copy), Humanoid (copy), CurrentCamera (copy)
    u40 = true;
    u21:Fire();
    u56 = nil;
    u57 = nil;
    attStats = {};
    Parent:SetAttribute("Aiming", false);
    u62 = false;
    ToggleADS(false);
    UserInputService.MouseDeltaSensitivity = 1;
    PlayRepSound("AimDown");

    if u57 then
        local _ = u57.aimTime / 2;
    end;

    if not GameConfig.lockFirstPerson then
        LocalPlayer2.CameraMode = CameraMode;
    end;

    u42 = false;
    AnimBase.CFrame = u75;
    task.wait(0.1);
    game.Workspace.Camera.FieldOfView = 70;
    UnbindGunInputs();

    if GameConfig.useDeathCameraSubject then
        repeat
            task.wait();
        until Humanoid.Parent ~= Parent;

        CurrentCamera.CameraSubject = Humanoid;
    end;

    if rig then
        rig:Destroy();
    end;
end);

function Unequip(p225)
    -- upvalues: AnimBase (copy), u75 (copy), u97 (ref), u59 (ref), u21 (copy), u56 (ref), u57 (ref), attStats (ref), Parent (copy), u62 (ref), ToggleADS (copy), UserInputService (copy), PlayRepSound (copy), GameConfig (copy), LocalPlayer2 (copy), CameraMode (copy), u52 (ref), u42 (ref), Animator (copy), Animator2 (copy), u85 (ref), u64 (ref), u66 (ref), u67 (ref), CurrentCamera (copy), Humanoid (copy), u44 (ref), u45 (ref), u46 (ref), u47 (ref), u90 (copy), Beam (copy), u91 (copy), UnbindGunInputs (copy)
    AnimBase.CFrame = u75;
    u97 = u59;
    u21:Fire();

    if p225 == u56 then
        u56 = nil;
        u57 = nil;
        attStats = {};
    end;

    Parent:SetAttribute("Aiming", false);
    u62 = false;
    ToggleADS(false);
    UserInputService.MouseDeltaSensitivity = 1;
    PlayRepSound("AimDown");

    if u57 then
        local _ = u57.aimTime / 2;
    end;

    if not GameConfig.lockFirstPerson then
        LocalPlayer2.CameraMode = CameraMode;
    end;

    u52 = false;
    u42 = false;

    for _, v in ipairs(Animator:GetPlayingAnimationTracks()) do
        v:Stop();
    end;

    for _, v in ipairs(Animator2:GetPlayingAnimationTracks()) do
        v:Stop();
    end;

    if GameConfig.lockFirstPerson then
        LocalPlayer2.CameraMode = Enum.CameraMode.Classic;
    end;

    u85 = {};
    u64 = false;
    u66 = u67:ToObjectSpace(CurrentCamera.CFrame);
    u66 = u66 - u66.Position;
    Humanoid.AutoRotate = true;
    u44 = 0;
    u45 = nil;
    u46 = false;
    u47 = false;
    u90.Enabled = false;
    Beam.Enabled = false;
    u91.Enabled = false;
    UnbindGunInputs();
end;

local function GetRotationBetween(p226, p227, p228) -- Line: 1319
    local v229 = p226:Dot(p227);
    local v230 = p226:Cross(p227);

    if v229 < -0.99999 then
        return CFrame.fromAxisAngle(p228, 3.141592653589793);
    end;

    return CFrame.new(0, 0, 0, v230.x, v230.y, v230.z, 1 + v229);
end;

local function CacheSightUI(p231) -- Line: 1324
    -- upvalues: u85 (ref)
    local Frame = p231:WaitForChild("SurfaceGui").Frame;
    local v232 = Frame:FindFirstChild("Reticle") or Frame:FindFirstChild("Holo");
    table.insert(u85, {
        part = p231,
        ui = v232
    });
end;

local function SetAttachment(p233, p234, p235, p236) -- Line: 1330
    -- upvalues: Gunsmith (copy), SPH_Assets (copy), attStats (ref), CacheSightUI (copy), WeldMod (copy)
    local v237 = Gunsmith.placeAttachment(p233, p234, p235, p236);

    if not SPH_Assets.Attachments:FindFirstChild(p235) then
        warn(p235 .. "Not found in SPH_Assets.Attachments!");

        return;
    end;

    local AttStats = require(SPH_Assets.Attachments[p235].AttStats);

    if AttStats.ADSEnabled then
        if attStats.ADSEnabled then
            warn("Multiple attachments enabling ADS Mesh");
        else
            attStats.ADSEnabled = AttStats.ADSEnabled;
        end;
    end;

    for _, child in ipairs(v237:GetChildren()) do
        if child.Name == "SightReticle" or child.Name == "ProjectorSight" then
            CacheSightUI(child);
        end;

        if string.find(child.Name, "AimPart") then
            if not attStats.aimParts then
                attStats.aimParts = {};
            end;

            if attStats.aimParts[child.Name] then
                local v238 = 1;

                for _, _ in attStats.aimParts do
                    v238 = v238 + 1;
                end;

                child.Name = "AimPart" .. v238;
                attStats.aimParts[child.Name] = v237.Name;
            else
                attStats.aimParts[child.Name] = v237.Name;
            end;

            if p233:FindFirstChild(child.Name) then
                p233.Grip["Grip_" .. child.Name]:Destroy();
                p233[child.Name].CFrame = child.CFrame;
                WeldMod.Weld(p233[child.Name], p233.Grip);
            end;
        end;
    end;

    if v237.Main:FindFirstChild("Flashlight") then
        if not attStats.flashlights_client then
            attStats.flashlights_client = {};
        end;

        table.insert(attStats.flashlights_client, v237);
    end;

    WeldMod.WeldModel(v237, p236[p234], false);
end;

local function setRecursiveAttachments(p239, p240, p241, p242) -- Line: 1374
    -- upvalues: SetAttachment (copy), setRecursiveAttachments (copy)
    if not p241 or p241 == "" then
        return;
    end;

    if typeof(p241) ~= "string" then
        if typeof(p241) == "table" then
            local v243 = p241[1];
            local v244 = p241[2];
            SetAttachment(p239, p240, v243, p242);

            for i, v in pairs(v244) do
                setRecursiveAttachments(p239, i, v, p239[v243]);
            end;
        end;

        return;
    end;

    if p242:FindFirstChild(p240) then
        SetAttachment(p239, p240, p241, p242);

        return;
    end;

    warn("No slot found for " .. p241);
end;

Parent.ChildAdded:Connect(function(p245) -- Line: 1388
    -- upvalues: u58 (ref), u65 (ref), u77 (ref), SPH_Assets (copy), u40 (ref), Humanoid (copy), u48 (ref), u61 (ref), zero (ref), u39 (ref), u43 (ref), u46 (ref), u37 (ref), u21 (copy), u56 (ref), u57 (ref), u18 (copy), u19 (copy), u63 (ref), FieldOfView2 (ref), u66 (ref), LocalPlayer2 (copy), u89 (ref), u62 (ref), UserInputService (copy), WeldMod (copy), attStats (ref), Gunsmith (copy), SetAttachment (copy), setRecursiveAttachments (copy), CacheSightUI (copy), u59 (ref), u14 (ref), u96 (copy), u5 (copy), u6 (copy), u38 (ref), RefreshViewmodel (copy), BindGunInputs (copy), EquipAnim (copy), PlayAnimation (copy), u83 (copy), RequestSprintChange (copy), Parent (copy), ToggleSprint (copy), GameConfig (copy), getArmorSpeedReduction (copy), walkSpeed (ref), u87 (ref), PlayCharSound (copy), u32 (copy), u60 (ref), MoveBolt (copy), u54 (ref), Beam (copy), u97 (ref)
    local v246 = u58 and u65 and u77 < 2;

    if p245:FindFirstChild("SPH_Weapon") and not SPH_Assets.WeaponModels:FindFirstChild(p245.Name) then
        warn("【 SPEARHEAD 】 " .. "No gun model could be found for \'" .. p245.Name .. "\'");

        return;
    end;

    if p245:FindFirstChild("SPH_Weapon") and (not u40 and (not Humanoid.Sit or Humanoid.Sit and not u48)) then
        u61 = false;
        zero = Vector2.zero;
        u39 = true;
        u43 = false;
        u46 = false;
        u37 = true;
        u21:Fire(p245);
        u56 = p245;
        u57 = require(u56.SPH_Weapon.WeaponStats);
        u18.Damping = u57.recoil.damping;
        u18.Speed = u57.recoil.speed;
        u19.Damping = u57.gunRecoil.damping;
        u19.Speed = u57.gunRecoil.speed;
        u63 = u57.viewmodelOffset;
        FieldOfView2 = u57.aimFovDefault or 70;
        u66 = CFrame.new();
        local Aimsens = LocalPlayer2:WaitForChild("Settings"):WaitForChild("Aimsens");
        u89 = u57.aimSpeed * Aimsens.Value;

        if aimSensConnection then
            aimSensConnection:Disconnect();
        end;

        aimSensConnection = Aimsens.Changed:Connect(function(p247) -- Line: 1417
            -- upvalues: u57 (ref), u89 (ref), u62 (ref), UserInputService (ref)
            if u57 then
                u89 = u57.aimSpeed * p247;

                if u62 then
                    UserInputService.MouseDeltaSensitivity = u89;
                end;
            end;
        end);

        if not u57.operationType then
            u57.operationType = 1;
        end;

        if type(u57.operationType) == "string" then
            u57.operationType = 1;
        end;

        if not u57.magType then
            u57.magType = 1;
        end;

        local v248 = rig.Weapon:FindFirstChildWhichIsA("Model");

        if v248 then
            v248:Destroy();
        end;

        local v249 = SPH_Assets.WeaponModels:FindFirstChild(p245.Name);

        if not v249 then
            warn("【 SPEARHEAD 】 " .. "Could not find a gun model with the name: \'" .. p245.Name .. "\'!");

            return;
        end;

        local v250 = v249:Clone();
        WeldMod.WeldModel(v250, v250.Grip, false);

        if u57.Attachments then
            attStats = Gunsmith.getAttStats(u57.Attachments);

            for i, v in u57.Attachments do
                if typeof(v) == "string" then
                    if v250:FindFirstChild(i) then
                        SetAttachment(v250, i, v, v250);
                    else
                        warn("No slot found for " .. i);
                    end;
                elseif typeof(v) == "table" then
                    setRecursiveAttachments(v250, i, v, v250);
                else
                    warn("Node type" .. (i == nil and "nil" or (typeof(i) or "nil")) .. "not recognized");
                end;
            end;
        end;

        if attStats.recoil then
            local v251 = u18;
            v251.Damping = v251.Damping * attStats.recoil.damping;
            local v252 = u18;
            v252.Speed = v252.Speed * attStats.recoil.speed;
        end;

        if attStats.gunRecoil then
            local v253 = u19;
            v253.Damping = v253.Damping * attStats.gunRecoil.damping;
            local v254 = u19;
            v254.Speed = v254.Speed * attStats.gunRecoil.speed;
        end;

        if attStats.aimFovDefault then
            FieldOfView2 = attStats.aimFovDefault;
        end;

        for _, v in ipairs(u57.rigParts) do
            if v250:FindFirstChild(v) then
                v250.Grip["Grip_" .. v]:Destroy();
                local v255 = WeldMod.M6D(v250.Grip, v250[v]);
                v255.Name = v;
                v255.Parent = v250.Grip;
            end;
        end;

        for _, descendant in ipairs(v250:GetDescendants()) do
            if descendant.Name == "SightReticle" or descendant.Name == "ProjectorSight" then
                CacheSightUI(descendant);
            end;
        end;

        v250.Parent = rig.Weapon;
        u59 = v250;
        u59 = v250;
        u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
        table.clear(u5);
        table.clear(u6);

        for _, descendant in ipairs(u59:GetDescendants()) do
            if descendant.Name == "REG" then
                table.insert(u5, descendant);
            elseif descendant.Name == "ADS" then
                table.insert(u6, descendant);
            end;
        end;

        WeldMod.BlankM6D(rig.AnimBase, v250.Grip);

        if u38 then
            RefreshViewmodel();
        end;

        BindGunInputs();
        EquipAnim();
        PlayAnimation(u57.idleAnim, {
            looped = true,
            priority = Enum.AnimationPriority.Idle
        });
        local v256 = u83[u57.equipAnim];

        if v256 then
            if v256.IsPlaying then
                v256.Stopped:Once(function() -- Line: 1501
                    -- upvalues: u39 (ref)
                    u39 = false;
                end);
            else
                u39 = false;
            end;
        else
            u39 = false;
        end;

        if v246 then
            task.defer(function() -- Line: 1509
                -- upvalues: u58 (ref), RequestSprintChange (ref), Parent (ref), u57 (ref), u83 (ref), ToggleSprint (ref), GameConfig (ref), getArmorSpeedReduction (ref), walkSpeed (ref), u87 (ref), PlayCharSound (ref), u32 (ref)
                u58 = false;
                RequestSprintChange:FireServer(false);
                Parent:SetAttribute("Sprinting", false);

                if u57 and u57.sprintAnim then
                    local sprintAnim = u57.sprintAnim;

                    if u83[sprintAnim] then
                        u83[sprintAnim]:Stop(0.2);
                        u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
                    end;
                end;

                ToggleSprint(true);
                local v257 = GameConfig.sprintSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v257, 4);

                if not GameConfig.canLean then
                    return;
                end;

                if u87 ~= 0 then
                    PlayCharSound("Lean");
                end;

                u87 = 0;
                u32:Fire(0);
            end);
        end;

        u60 = p245:WaitForChild("Ammo");

        if not u56.BoltReady.Value then
            MoveBolt(u57.boltDist, true);
        end;

        if GameConfig.lockFirstPerson then
            LocalPlayer2.CameraMode = Enum.CameraMode.LockFirstPerson;
        end;

        u54 = u56.FireMode.Value;

        if u59.Grip:FindFirstChild("Laser") then
            Beam.Attachment0 = u59.Grip.Laser;
        end;

        if attStats.laserOrigin and u59[attStats.laserOrigin].Main:FindFirstChild("Laser") then
            Beam.Attachment0 = u59[attStats.laserOrigin].Main.Laser;
        end;

        local reloadSpeedModifier = u57.reloadSpeedModifier;

        if attStats.reloadSpeedModifier then
            reloadSpeedModifier = reloadSpeedModifier * attStats.reloadSpeedModifier;
        end;

        if u57.magType == 1 then
            PlayAnimation(u57.reloadAnim, {
                transSpeed = 0.17,
                speed = reloadSpeedModifier,
                priority = Enum.AnimationPriority.Action2
            }, "Reload", true);
        else
            PlayAnimation(u57.reloadAnim, {
                transSpeed = 0,
                speed = reloadSpeedModifier,
                priority = Enum.AnimationPriority.Action2,
                looped = u60.MagAmmo.MaxValue > 1
            }, "Reload", true);

            if u57.magType == 3 then
                PlayAnimation(u57.clipReloadAnim, {
                    transSpeed = 0.17,
                    looped = false,
                    speed = reloadSpeedModifier,
                    priority = Enum.AnimationPriority.Action2
                }, "Reload", true);
            end;
        end;

        PlayAnimation(u57.equipAnim, {
            priority = Enum.AnimationPriority.Action2
        }, "Equip", true);
        PlayAnimation(u57.boltChamber, {
            transSpeed = 0.05,
            looped = false,
            priority = Enum.AnimationPriority.Action2
        }, "Chamber", true);

        if u57.operationType == 2 or u57.operationType == 3 then
            PlayAnimation(u57.boltOpen, {
                transSpeed = 0,
                looped = false,
                priority = Enum.AnimationPriority.Action2
            }, "BoltOpen", true);
            PlayAnimation(u57.boltClose, {
                looped = false,
                priority = Enum.AnimationPriority.Action2
            }, "BoltClose", true);
        end;

        wait(1);
        u97 = p245;
    end;
end);
Parent.ChildRemoved:Connect(function(p258) -- Line: 1550
    -- upvalues: u56 (ref)
    if u56 and p258 == u56 then
        Unequip(p258);
    end;
end);
RunService.Heartbeat:Connect(function(p259) -- Line: 1555
    -- upvalues: u56 (ref), u40 (ref), u36 (ref), u37 (ref), u58 (ref), u61 (ref), u41 (ref), u43 (ref), u44 (ref), u60 (ref), u54 (ref), GameConfig (copy), u64 (ref), u39 (ref), u38 (ref), u57 (ref), PlayAnimation (copy), u55 (ref), u49 (ref), u96 (copy), u59 (ref), attStats (ref), u62 (ref), u77 (ref), u18 (copy), u19 (copy), BGLOPP (copy), LocalPlayer2 (copy), PlayRepSound (copy), MoveBolt (copy), u14 (ref), u22 (copy), ChamberAnim (copy)
    if u56 and (not u40 and (u36 and (u37 and not (u58 or u61)))) then
        if u41 and (not u43 and u44 == 0) and (u60.MagAmmo.Value > 0 and (u54 > 0 and (GameConfig.fireWithFreelook or not (GameConfig.fireWithFreelook or u64))) and not u39) then
            if not (u38 or GameConfig.thirdPersonFiring) then
                return;
            end;

            local v260 = u57;

            if v260.fireAnim then
                PlayAnimation(v260.fireAnim, {
                    looped = false,
                    priority = Enum.AnimationPriority.Action2
                });
            end;

            u55 = u55 + 1;
            u49 = false;

            if u54 == 1 or (u54 == 5 or u54 == 3 and u55 >= v260.burstNumber) then
                u41 = false;
                u36 = false;
            end;

            u37 = false;
            u96.Weapon:FindFirstChildWhichIsA("Model");
            local v261 = u59;
            local recoil = v260.recoil;
            local vertical = recoil.vertical;
            local horizontal = recoil.horizontal;

            if attStats.recoil then
                vertical = vertical * attStats.recoil.vertical;
                horizontal = horizontal * attStats.recoil.horizontal;
                recoil.camShake = recoil.camShake * attStats.recoil.camShake;
                recoil.aimReduction = recoil.aimReduction * attStats.recoil.aimReduction;
            end;

            if u62 then
                vertical = vertical / recoil.aimReduction;
                horizontal = horizontal / recoil.aimReduction;
            end;

            if u77 == 2 then
                vertical = vertical / 2;
                horizontal = horizontal / 2;
            end;

            local v262 = math.random(-horizontal, horizontal);
            u18:shove((Vector3.new(vertical, v262, recoil.camShake)));
            local gunRecoil = v260.gunRecoil;
            local vertical2 = gunRecoil.vertical;
            local horizontal2 = gunRecoil.horizontal;

            if attStats.gunRecoil then
                vertical2 = vertical2 * attStats.gunRecoil.vertical;
                horizontal2 = horizontal2 * attStats.gunRecoil.horizontal;
                gunRecoil.punchMultiplier = gunRecoil.punchMultiplier * attStats.gunRecoil.punchMultiplier;
            end;

            if u77 == 2 then
                vertical2 = vertical2 / 1.5;
                horizontal2 = horizontal2 / 1.5;
            end;

            local v263 = math.random(-horizontal2, horizontal2);
            u19:shove((Vector3.new(vertical2, v263, gunRecoil.punchMultiplier)));
            local v264 = u57.bulletHolder and u59:FindFirstChild(u57.bulletHolder);
            local v265 = v264 and v264:FindFirstChild("Bullet" .. u60.MagAmmo.MaxValue - (u60.MagAmmo.Value - 1));

            if v265 then
                v265.Transparency = 1;
            end;

            local v266 = u59;

            if not u38 then
                v266 = u96.Weapon:FindFirstChildWhichIsA("Model");
            end;

            if attStats.newMuzzleDevice then
                v266 = v266[attStats.newMuzzleDevice];
            end;

            BGLOPP.FireFX(LocalPlayer2, v266, "Muzzle", attStats.muzzleChance or u57.muzzleChance);
            PlayRepSound("Fire");
            MoveBolt(v260.boltDist);
            local v267;

            if v260.shotgun then
                v267 = v260.shotgunPellets or 1;
            else
                v267 = 1;
            end;

            while true do
                v267 = v267 - 1;
                local v268 = v260.spread * 100;
                local Angles = CFrame.Angles;
                local v269 = math.random(-v268, v268) / 100;
                local v270 = math.rad(v269);
                local v271 = math.random(-v268, v268) / 100;
                local v272 = Angles(v270, math.rad(v271), 0);
                local v273, v274;

                if u38 then
                    local Muzzle = v261.Grip.Muzzle;
                    v273 = Muzzle.WorldCFrame.Position;
                    v274 = (Muzzle.WorldCFrame * v272).LookVector;
                else
                    if not (u14 and u14.Parent) then
                        u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                    end;

                    local Muzzle = u14.Grip.Muzzle;
                    v273 = Muzzle.WorldCFrame.Position;
                    v274 = (Muzzle.WorldCFrame * v272).LookVector;
                end;

                local muzzleVelocity = v260.muzzleVelocity;

                if attStats.muzzleVelocityReplace then
                    muzzleVelocity = attStats.muzzleVelocityReplace;
                end;

                if attStats.muzzleVelocity then
                    muzzleVelocity = muzzleVelocity * attStats.muzzleVelocity;
                end;

                if v260.tracerTiming and attStats.tracerTiming then
                    local _ = v260.tracerTiming;
                end;

                BGLOPP.FireBullet(u96, v273, v274, v274 * muzzleVelocity * 3.5, u56, LocalPlayer2, attStats.tracerColor or v260.tracerColor);

                if v267 <= 0 then
                    local v275;

                    if u38 then
                        v275 = v261.Grip.Muzzle;
                    else
                        v275 = u96.Weapon:FindFirstChildWhichIsA("Model").Grip.Muzzle;
                    end;

                    u22:Fire(v275.WorldCFrame);
                    local fireRate = v260.fireRate;

                    if u54 == 3 and v260.burstFireRate then
                        fireRate = v260.burstFireRate;
                    end;

                    if attStats.fireRate then
                        fireRate = fireRate * attStats.fireRate;
                    end;

                    if u59 and (v260.projectile ~= "Bullet" and u59:FindFirstChild(v260.projectile)) then
                        local v276 = u59:FindFirstChild(v260.projectile);
                        v276.LocalTransparencyModifier = 1;

                        for _, descendant in ipairs(v276:GetDescendants()) do
                            if descendant:IsA("BasePart") then
                                descendant.LocalTransparencyModifier = 1;
                            end;
                        end;
                    end;

                    task.wait(60 / fireRate);

                    if not u56 then
                        return;
                    end;

                    if v260.autoChamber and (u54 == 5 and not u61) then
                        ChamberAnim();
                    end;

                    u37 = true;

                    return;
                end;
            end;
        end;

        if u60.MagAmmo.Value <= 0 then
            PlayRepSound("Click");
            u36 = false;

            return;
        end;

        if u57.emptyCloseBolt then
            MoveBolt(CFrame.new());
        end;
    end;
end);
local u277 = 0;
RunService.RenderStepped:Connect(function(p278) -- Line: 1694
    -- upvalues: u1 (ref), u72 (copy), u93 (ref), u19 (copy), u92 (ref), u18 (copy), u73 (ref), Humanoid (copy), u48 (ref), u38 (ref), u64 (ref), GameConfig (copy), HumanoidRootPart (copy), CurrentCamera (copy), u40 (ref), Parent (copy), u58 (ref), u3 (ref), u20 (copy), u56 (ref), BindAiming (copy), u47 (ref), u59 (ref), u96 (copy), attStats (ref), u46 (ref), u91 (copy), Beam (copy), ContextActionService (copy), u14 (ref), u42 (ref), u84 (ref), u82 (ref), u65 (ref), RequestSprintChange (copy), u57 (ref), u83 (copy), getArmorSpeedReduction (copy), walkSpeed (ref), u51 (ref), u77 (ref), ChangeStance (copy), ToggleSprint (copy), u87 (ref), PlayCharSound (copy), u32 (copy), u4 (ref), u2 (ref), u88 (ref), UserInputService (copy), u34 (ref), u13 (copy), RefreshViewmodel (copy), UpdateViewmodelPosition (copy), u90 (copy), Attachment (copy), u39 (ref), u35 (ref), u62 (ref), u17 (copy), AnimBase (copy), u277 (ref), u85 (ref), u53 (ref), FieldOfView2 (ref), FieldOfView (ref), Value (ref), GetRotationBetween (copy)
    if math.ceil(1 / p278) < 5 then
        return;
    end;

    u1 = u1 + p278;
    u1 = math.min(u1, u72.fixedDt * 8);

    while u1 >= u72.fixedDt do
        u93 = u19:update(u72.fixedDt);
        u92 = u18:update(u72.fixedDt);
        u1 = u1 - u72.fixedDt;
    end;

    u73 = u73 - p278;

    if (Humanoid.Sit and (not u48 and u38) or u64) and GameConfig.cameraLimitInSeats then
        local v279, v280, v281 = HumanoidRootPart.CFrame:ToObjectSpace(CurrentCamera.CFrame):ToOrientation();
        local X = CurrentCamera.CFrame.Position.X;
        local Y = CurrentCamera.CFrame.Position.Y;
        local Z = CurrentCamera.CFrame.Position.Z;
        local v282 = math.deg(v279);
        local v283 = math.clamp(v282, -60, 60);
        local v284 = math.rad(v283);
        local v285 = math.deg(v280);
        local v286 = math.clamp(v285, -60, 60);
        local v287 = math.rad(v286);
        local v288 = math.deg(v281);
        local v289 = math.clamp(v288, -60, 60);
        local v290 = math.rad(v289);
        local v291 = HumanoidRootPart.CFrame:ToWorldSpace(CFrame.new(X, Y, Z) * CFrame.fromOrientation(v284, v287, v290));
        CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position) * (v291 - v291.Position);
    end;

    if not u40 and Parent:FindFirstChild("Head") then
        if not u40 then
            local v292;

            if Humanoid.RigType == Enum.HumanoidRigType.R6 then
                v292 = Parent.Torso.CFrame.LookVector;
            else
                v292 = Parent.UpperTorso.CFrame.LookVector;
            end;

            local CFrame2 = CurrentCamera.CFrame;

            if (not GameConfig.headRotation or u58) and not u38 then
                CFrame2 = HumanoidRootPart.CFrame;
            end;

            local LookVector = HumanoidRootPart.CFrame:ToObjectSpace(CFrame2).LookVector;
            local v293 = CFrame.Angles(0, math.asin(LookVector.X) / 1.15, 0);
            local Angles = CFrame.Angles;
            local v294 = math.clamp(CFrame2.LookVector.Y, -0.8, 0.15);
            local v295 = -math.asin(v294);
            local v296 = math.clamp(v292.Y, -0.6, 0.6);
            local v297 = v293 * Angles(v295 + math.asin(v296), 0, 0);
            local v298;

            if Humanoid.RigType == Enum.HumanoidRigType.R6 then
                v298 = CFrame.new(0, -0.5, 0) * v297 * CFrame.Angles(-1.5707963267948966, 0, 3.141592653589793);
            else
                v298 = CFrame.new(0, -0.5, 0) * v297 * CFrame.Angles(0, 0, 0);
            end;

            u3.C1 = u3.C1:Lerp(v298, 1 - math.exp(-GameConfig.headRotationSpeed * p278));

            if u73 <= 0 and not (u40 or GameConfig.disableHeadRotation) then
                u73 = GameConfig.headRotationEventRate;
                u20:Fire(u3.C1);
            end;
        end;

        if u38 or Parent.Head.LocalTransparencyModifier < 0.6 then
            if u38 and Parent.Head.LocalTransparencyModifier <= 0.6 then
                u38 = false;
                ContextActionService:UnbindAction("SPH_HoldAim");

                if u56 then
                    if u46 then
                        u91.Enabled = true;
                        Beam.Enabled = false;

                        if not u91.Attachment0 then
                            if not (u14 and u14.Parent) then
                                u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                            end;

                            u91.Attachment0 = u14.Grip.Laser;
                        end;

                        if attStats.laserOrigin and u59[attStats.laserOrigin].Main:FindFirstChild("Laser") then
                            if not (u14 and u14.Parent) then
                                u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                            end;

                            u91.Attachment0 = u14[attStats.laserOrigin].Main.Laser;
                        end;
                    end;

                    if u59.Grip:FindFirstChild("Flashlight") then
                        u59.Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false;

                        if u96.Weapon:FindFirstChildWhichIsA("Model") and u47 then
                            u96.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true;
                        end;
                    end;

                    if attStats.flashlights_client then
                        for _, v in ipairs(attStats.flashlights_client) do
                            v.Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false;

                            if u96.Weapon:FindFirstChildWhichIsA("Model") and u47 then
                                u96.Weapon:FindFirstChildWhichIsA("Model")[v].Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true;
                            end;
                        end;
                    end;
                end;

                u42 = false;
                u84 = Vector3.new(0, 0, 0);
            end;
        else
            u38 = true;

            if u56 then
                BindAiming();

                if u47 then
                    if u59.Grip:FindFirstChild("Flashlight") then
                        u59.Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true;
                        u96.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false;
                    end;

                    if attStats.flashlights_client then
                        for _, v in ipairs(attStats.flashlights_client) do
                            v.Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true;
                            u96.Weapon:FindFirstChildWhichIsA("Model")[v.Name].Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false;
                        end;
                    end;
                end;

                if u46 then
                    u91.Enabled = false;
                    Beam.Enabled = true;
                end;
            end;
        end;

        if u82 then
            u82:AdjustSpeed(Humanoid.WalkSpeed / 6);
        end;

        if Humanoid.MoveDirection.Magnitude > 0 and not u65 then
            u65 = true;

            if u82 then
                u82:Play(GameConfig.stanceChangeTime);
            end;
        elseif Humanoid.MoveDirection.Magnitude <= 0 then
            u65 = false;

            if u58 then
                u58 = false;
                RequestSprintChange:FireServer(false);
                Parent:SetAttribute("Sprinting", false);

                if u57 and u57.sprintAnim then
                    local sprintAnim = u57.sprintAnim;

                    if u83[sprintAnim] then
                        u83[sprintAnim]:Stop(0.2);
                        u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
                    end;
                end;

                local v299 = GameConfig.walkSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v299, 4);
            end;

            if u82 then
                u82:Stop(GameConfig.stanceChangeTime);
            end;
        end;

        local v300, v301;

        if u58 then
            local v302;

            if Humanoid.MoveDirection.Magnitude <= 0 then
                v302 = false;
            else
                v302 = HumanoidRootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection.Unit) >= (GameConfig.sprintForwardThreshold or 0.5);
            end;

            if v302 then
                if u51 and (not u58 and (u77 < 2 and u65)) then
                    if Humanoid.MoveDirection.Magnitude <= 0 then
                        v300 = false;
                    else
                        v300 = HumanoidRootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection.Unit) >= (GameConfig.sprintForwardThreshold or 0.5);
                    end;

                    if v300 then
                        if u77 == 1 then
                            ChangeStance(-1);
                        end;

                        ToggleSprint(true);
                        v301 = GameConfig.sprintSpeed - getArmorSpeedReduction();
                        walkSpeed = math.max(v301, 4);

                        if GameConfig.canLean then
                            if u87 ~= 0 then
                                PlayCharSound("Lean");
                            end;

                            u87 = 0;
                            u32:Fire(0);
                        end;
                    end;
                end;
            else
                u58 = false;
                RequestSprintChange:FireServer(false);
                Parent:SetAttribute("Sprinting", false);

                if u57 and u57.sprintAnim then
                    local sprintAnim = u57.sprintAnim;

                    if u83[sprintAnim] then
                        u83[sprintAnim]:Stop(0.2);
                        u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
                    end;
                end;

                local v303 = GameConfig.walkSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v303, 4);
            end;
        elseif u51 and (not u58 and (u77 < 2 and u65)) then
            if Humanoid.MoveDirection.Magnitude <= 0 then
                v300 = false;
            else
                v300 = HumanoidRootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection.Unit) >= (GameConfig.sprintForwardThreshold or 0.5);
            end;

            if v300 then
                if u77 == 1 then
                    ChangeStance(-1);
                end;

                ToggleSprint(true);
                v301 = GameConfig.sprintSpeed - getArmorSpeedReduction();
                walkSpeed = math.max(v301, 4);

                if GameConfig.canLean then
                    if u87 ~= 0 then
                        PlayCharSound("Lean");
                    end;

                    u87 = 0;
                    u32:Fire(0);
                end;
            end;
        end;

        local v304, v305, v306;

        if u4 == Enum.HumanoidRigType.R6 then
            if GameConfig.firstPersonBody and u38 then
                local v307 = -1.2 + (Parent.HumanoidRootPart.CFrame:ToObjectSpace(CurrentCamera.CFrame):ToEulerAngles() + 1.4) / 2.8;
                u84 = Vector3.new(0, 0, v307);
            else
                u84 = Vector3.new(0, 0, 0);
            end;

            v304 = 0;
            v305 = 0;
            v306 = u84.Z;

            if u77 == 1 then
                v305 = -1;

                if u38 then
                    v306 = v306 - 0.3;
                end;
            elseif u77 == 2 then
                v305 = -1.5;

                if u38 then
                    v306 = -1.7;
                end;
            end;

            if u87 < 0 then
                v305 = v305 + -0.2;
                v304 = -1;
            elseif u87 > 0 then
                v305 = v305 + -0.2;
                v304 = 1;
            end;
        else
            if GameConfig.firstPersonBody and u38 then
                local v308 = -1.6 + (Parent.HumanoidRootPart.CFrame:ToObjectSpace(CurrentCamera.CFrame):ToEulerAngles() + 1.4) / 2.8;
                u84 = Vector3.new(0, 0, v308);
            else
                u84 = Vector3.new(0, 0, 0);
            end;

            v304 = 0;
            v305 = 0;
            v306 = u84.Z;

            if u77 == 1 then
                v305 = 0.5;

                if u38 then
                    v306 = v306 - 1.5;
                end;
            elseif u77 == 2 then
                v305 = 1.5;

                if u38 then
                    v306 = -3;
                end;
            end;

            if u87 < 0 then
                v305 = v305 + -0.2;
                v304 = -1;
            elseif u87 > 0 then
                v305 = v305 + -0.2;
                v304 = 1;
            end;
        end;

        if not u48 and CurrentCamera.CameraType == Enum.CameraType.Custom then
            if u4 == Enum.HumanoidRigType.R6 then
                u84 = Vector3.new(v304, v305, v306);
            else
                u84 = Vector3.new(v304, -v305, v306);
            end;

            Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp(u84, p278 * 0.1 * 60);

            if u4 == Enum.HumanoidRigType.R15 then
                u2.C1 = u2.C1:Lerp(CFrame.new(-v304 / 2, 0, 0) * CFrame.Angles(0, 0, (math.rad(u87 * 10))), p278 * 0.04 * 60);
            else
                u2.C1 = u2.C1:Lerp(CFrame.new(-v304 / 2, 0, 0) * CFrame.Angles(1.5707963267948966, math.rad(u87 * 10) + 3.141592653589793, 0), p278 * 0.04 * 60);
            end;

            local v309 = u88;
            u88 = v309 + (-u87 * 15 - v309) * 0.04;
            local v310 = CurrentCamera;
            v310.CFrame = v310.CFrame * CFrame.Angles(0, 0, (math.rad(u88)));

            if GameConfig.cameraTilting and u38 then
                local v311 = HumanoidRootPart.CFrame:VectorToObjectSpace(HumanoidRootPart.Velocity);
                local v312 = UserInputService:GetMouseDelta();
                local v313 = u34;
                u34 = v313 + (math.clamp(-v311.X, -2, 2) + v312.X / 2 - v313) * (p278 * 0.07 * 60);
                local v314 = CurrentCamera;
                v314.CFrame = v314.CFrame * CFrame.Angles(0, 0, (math.rad(u34)));
            end;

            if not u13 then
                local v315 = RaycastParams.new();
                v315.FilterType = Enum.RaycastFilterType.Exclude;
                v315.FilterDescendantsInstances = { Parent, CurrentCamera };
                v315.RespectCanCollide = true;
                local Position = HumanoidRootPart.Position;
                local v316 = CurrentCamera.CFrame.Position - Position;
                local Magnitude = v316.Magnitude;

                if Magnitude > 0.05 then
                    local v317 = workspace:Raycast(Position, v316.Unit * (Magnitude + 0.6), v315);

                    if v317 then
                        local v318 = math.max((v317.Position - Position).Magnitude - 0.6, 0);
                        CurrentCamera.CFrame = CFrame.new(Position + v316.Unit * v318) * (CurrentCamera.CFrame - CurrentCamera.CFrame.Position);
                    end;
                else
                    CurrentCamera.CFrame = CFrame.new(Position) * (CurrentCamera.CFrame - CurrentCamera.CFrame.Position);
                end;
            end;
        end;

        if u56 and CurrentCamera.CameraType == Enum.CameraType.Custom then
            if u38 and not u42 then
                RefreshViewmodel();
                ToggleSprint(u51);
            end;

            UpdateViewmodelPosition(p278);

            if u46 then
                if not u90.Enabled then
                    u90.Enabled = true;
                    local v319;

                    if attStats.laserOrigin then
                        v319 = u59[attStats.laserOrigin].Main.Laser;
                    else
                        v319 = nil;
                    end;

                    if u59.Grip:FindFirstChild("Laser") then
                        v319 = u59.Grip.Laser;
                    end;

                    u90.Dot.ImageColor3 = v319.Color.Value;

                    if GameConfig.laserTrail then
                        Beam.Color = ColorSequence.new(v319.Color.Value);
                        u91.Color = ColorSequence.new(v319.Color.Value);

                        if u38 then
                            Beam.Enabled = true;
                        else
                            u91.Enabled = true;

                            if not u91.Attachment0 then
                                if attStats.laserOrigin then
                                    if not (u14 and u14.Parent) then
                                        u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                                    end;

                                    u91.Attachment0 = u14[attStats.laserOrigin].Main.Laser;
                                end;

                                if u59.Grip:FindFirstChild("Laser") then
                                    if not (u14 and u14.Parent) then
                                        u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                                    end;

                                    u91.Attachment0 = u14.Grip.Laser;
                                end;
                            end;
                        end;
                    end;
                end;

                local v320;

                if u59.Grip:FindFirstChild("Laser") then
                    v320 = u38 and u59.Grip.Laser;

                    if not v320 then
                        if not (u14 and u14.Parent) then
                            u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                        end;

                        v320 = u14.Grip.Laser;
                    end;
                else
                    v320 = nil;
                end;

                if attStats.laserOrigin then
                    v320 = u38 and u59[attStats.laserOrigin].Main.Laser;

                    if not v320 then
                        if not (u14 and u14.Parent) then
                            u14 = u96.Weapon:FindFirstChildWhichIsA("Model");
                        end;

                        v320 = u14[attStats.laserOrigin].Main.Laser;
                    end;
                end;

                if not Attachment then
                    return;
                end;

                local v321 = RaycastParams.new();
                v321.FilterType = Enum.RaycastFilterType.Exclude;
                v321.FilterDescendantsInstances = { u59, Parent };
                v321.RespectCanCollide = true;
                local WorldPosition = v320.WorldPosition;
                local v322 = v320.WorldCFrame.LookVector * 600;
                local v323 = workspace:Raycast(WorldPosition, v322, v321);

                if v323 then
                    Attachment.WorldPosition = v323.Position;
                else
                    Attachment.WorldPosition = WorldPosition + v322;
                end;
            elseif u90.Enabled then
                u90.Enabled = false;
                Beam.Enabled = false;
                u91.Enabled = false;
            end;
        elseif u42 and not u39 then
            u42 = false;
        end;

        local bobDampening = GameConfig.bobDampening;
        local v324 = bobDampening - (bobDampening - bobDampening / (u35 / GameConfig.walkSpeed)) / 8;

        if u62 then
            v324 = v324 * GameConfig.aimBobDampening;
        end;

        local v325 = GameConfig.bobSpeed * (u35 / GameConfig.walkSpeed);

        if not Humanoid.Sit then
            local v326 = tick() * v325 * 1.3;
            local v327 = math.sin(v326) * 0.3;
            local v328 = tick() * (v325 / 2) * 1.3;
            local v329 = math.sin(v328) * 0.3;
            local v330 = tick() * (v325 * 1.5) * 1.3;
            local v331 = math.sin(v330) * 0.3;
            u17:shove(Vector3.new(v327, v329, v331) / v324 * HumanoidRootPart.Velocity.Magnitude / v324 * p278 * 60);
        end;

        local v332 = u17:update(p278);
        AnimBase.CFrame = AnimBase.CFrame:ToWorldSpace(CFrame.new(v332.Y, v332.X, 0) * CFrame.Angles(v332.Y * 0.3, 0, v332.Y * 0.8));
        local v333;

        if u58 then
            local v334 = tick() * u72.sprintSwaySpeed;
            v333 = math.sin(v334) * u72.sprintSwayAmplitude or 0;
        else
            v333 = 0;
        end;

        local v335 = u277;
        u277 = v335 + (v333 - v335) * (u72.sprintSwayLerp * p278 * 60);
        local v336 = AnimBase;
        v336.CFrame = v336.CFrame * CFrame.new(0, 0, u277);

        if GameConfig.cameraMovement and (u38 and (not Humanoid.Sit and (not u48 and CurrentCamera.CameraType == Enum.CameraType.Custom))) then
            local v337 = CurrentCamera;
            v337.CFrame = v337.CFrame * CFrame.Angles(math.rad(v332.X / GameConfig.cameraBobDampening), math.rad(v332.Y / GameConfig.cameraBobDampening), 0);
        end;

        for _, v in ipairs(u85) do
            local part = v.part;
            local ui = v.ui;
            local v338 = part.CFrame:PointToObjectSpace(CurrentCamera.CFrame.Position) / part.Size;
            ui.Position = UDim2.fromScale(0.5 + v338.X, 0.5 - v338.Y);

            if ui.Name == "Holo" then
                local v339 = CurrentCamera.FieldOfView / 70;
                ui.Size = UDim2.fromScale(v339, v339);
            end;
        end;

        local v340 = not (u57 and u57.aimTime) and 0.25 or u57.aimTime;

        if attStats and attStats.aimTime then
            v340 = v340 * attStats.aimTime;
        end;

        local v341 = p278 / math.max(v340 * 0.05, 0.05);
        local v342 = math.clamp(v341, 0, 1);
        FieldOfView = FieldOfView + ((not u62 and 70 or (u53 or FieldOfView2)) - FieldOfView) * v342;
        CurrentCamera.FieldOfView = FieldOfView * Value;
    end;

    u35 = walkSpeed;

    if script:GetAttribute("WalkspeedOverrideToggle") then
        u35 = script:GetAttribute("WalkspeedOverride");
    end;

    if Humanoid.Health < 30 and GameConfig.lowHealthEffects then
        u35 = u35 * (Humanoid.Health / 30);
    end;

    local WalkSpeed = Humanoid.WalkSpeed;
    Humanoid.WalkSpeed = WalkSpeed + (u35 - WalkSpeed) * (p278 * 0.2 * 60);

    if u77 == 2 and GameConfig.proneAngle then
        local v343 = RaycastParams.new();
        v343.FilterType = Enum.RaycastFilterType.Exclude;
        v343.FilterDescendantsInstances = { Parent };
        v343.IgnoreWater = true;
        v343.RespectCanCollide = true;
        local v344 = workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -2, 0), v343);

        if v344 and v344.Instance then
            local v345 = GetRotationBetween(HumanoidRootPart.CFrame.UpVector, v344.Normal, Vector3.new(1, 0, 0));
            local v346 = u2;
            v346.C0 = v346.C0 * CFrame.Angles(v345.X, v345.Y, v345.Z);
            local _ = v345 * HumanoidRootPart.CFrame;
        end;
    end;
end);
Humanoid.Seated:Connect(function(p347, p348) -- Line: 2054
    -- upvalues: ContextActionService (copy), u58 (ref), RequestSprintChange (copy), Parent (copy), u57 (ref), u83 (copy), GameConfig (copy), u87 (ref), PlayCharSound (copy), u32 (copy), u77 (ref), ChangeStance (copy), u48 (ref), u56 (ref), Humanoid (copy), BindCharacterInputs (copy)
    if p347 then
        ContextActionService:UnbindAction("SPH_Sprint");
        ContextActionService:UnbindAction("SPH_ToggleStance");
        ContextActionService:UnbindAction("SPH_LeanLeft");
        ContextActionService:UnbindAction("SPH_LeanRight");
        u58 = false;
        RequestSprintChange:FireServer(false);
        Parent:SetAttribute("Sprinting", false);

        if u57 and u57.sprintAnim then
            local sprintAnim = u57.sprintAnim;

            if u83[sprintAnim] then
                u83[sprintAnim]:Stop(0.2);
                u83[sprintAnim .. "ThirdPerson"]:Stop(0.2);
            end;
        end;

        if GameConfig.canLean then
            if u87 ~= 0 then
                PlayCharSound("Lean");
            end;

            u87 = 0;
            u32:Fire(0);
        end;

        if u77 == 1 then
            ChangeStance(-1);
        elseif u77 == 2 then
            ChangeStance(-1);
            ChangeStance(-1);
        end;

        if not p348:IsA("VehicleSeat") then
            u48 = false;

            return;
        end;

        u48 = true;

        if u56 then
            Humanoid:UnequipTools();
        end;
    else
        BindCharacterInputs();
        u48 = false;
    end;
end);
local u349 = true;
UserInputService.JumpRequest:Connect(function() -- Line: 2079
    -- upvalues: Humanoid (copy), Parent (copy), u77 (ref), u349 (ref), GameConfig (copy)
    if Humanoid.Sit then
        Parent.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping);

        return;
    end;

    if u77 == 0 then
        if Parent.Humanoid.FloorMaterial == Enum.Material.Air then
            return;
        end;

        if u349 then
            u349 = false;
            Parent.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
            Parent.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false);
            task.wait(GameConfig.jumpCooldown);
            u349 = true;
            Parent.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true);
        end;
    end;
end);