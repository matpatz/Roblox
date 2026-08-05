if not game:IsLoaded() then game.Loaded:Wait(); end;

getgenv().sneeky_silent_aim = true;
getgenv().sneeky_fov_size = 200;
getgenv().sneeky_wallcheck = false; -- Switch this to true if you don't want the silent aim to target people behind cover!

local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> ...any) return f; end;
local newcclosure = newcclosure or clonefunction;
local executor = identifyexecutor and identifyexecutor() or "Your executor";
local SG = loadstring(game:HttpGet("https://sneekysscripts.uk/Scripts/NOTIFICATION_LIBRARY/main.luau"))();

if not (hookfunction and require) then
    local err = executor .. " is missing " .. (not hookfunction and "hookfunction " or "") .. (not require and "require" or "");
    SG["error"](err);
    return error(err);
end;

local RS: ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"));
local Players: Players = cloneref(game:GetService("Players"));
local UIS: UserInputService = cloneref(game:GetService("UserInputService"));

local plr = Players.LocalPlayer;
local cam = workspace.CurrentCamera;

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled;

local ac = require(RS.Modules.FastCastRedux.ActiveCast).new
if not ac then
    error("ActiveCast not found")
end

local bots = workspace:FindFirstChild("Npc");
if not bots then
    local err = "Script needs updating";
    SG["error"](err);
    return warn(err);
end;

local rp = RaycastParams.new();
rp.FilterType = Enum.RaycastFilterType.Exclude;
rp.IgnoreWater = true;

local isVisible = function(part: BasePart, origin: Vector3): (boolean, Instance?)
    local char = plr.Character;
    if not (char and part) then return false, nil, nil; end;

    rp.FilterDescendantsInstances = {char, workspace.Characters};

    local dir = part.Position - origin;
    local result: RaycastResult = workspace:Raycast(origin, dir, rp);
    if not result then return true, nil, nil; end;

    if result.Instance:IsDescendantOf(part.Parent) then
        return true, result.Instance, result.Position;
    end;

    return false, result.Instance, result.Position;
end;

local getTarget = function(origin: Vector3)
    if not getgenv().sneeky_silent_aim then return nil; end;
    local cPart, cDistance, cPos = nil, getgenv().sneeky_fov_size or 300, nil;

    local t = table.create(#Players:GetPlayers() + #bots:GetChildren());
    local idx = 1;
    for _, v in next, Players:GetPlayers() do t[idx] = v; idx += 1; end;
    for _, v in next, bots:GetChildren() do t[idx] = v; idx += 1; end;

    for _, v: Player | Model in next, t do
        if v == plr then continue; end;

        local char = v:IsA("Model") and v or v.Character;
        if not char or char:FindFirstChildOfClass("ForceField") or (char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0) then continue; end;

        local tPart: BasePart = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart");
        if not tPart then continue; end;

        local pos, onScreen = cam:WorldToViewportPoint(tPart.Position);
        if not onScreen then continue; end;

        local v, nTPart, nTPos = isVisible(tPart, origin);
        if not v and getgenv().sneeky_wallcheck then
            v, nTPart, nTPos = isVisible(char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"), origin);
            if not v then continue; end;
        end;

        if nTPart and v then tPart = nTPart; end;

        local distance = (Vector2.new(pos.X, pos.Y) - (isMobile and Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2) or UIS:GetMouseLocation())).Magnitude;
        if distance < cDistance then
            cPart = tPart;
            cPos = nTPos;
            cDistance = distance;
        end;
    end;

    return cPart, cPos;
end;

loadstring(game:HttpGet("https://sneekysscripts.uk/Scripts/UIs/silent_aim.luau"))()(getgenv().sneeky_fov_size or 300, getTarget, true);

local acnew = ac
if isfunctionhooked(acnew) then
	restorefunction(acnew)
end

local OldNew
OldNew = hookfunction(acnew, function(Caster, Origin, Direction, Velocity, ...)
    local _, HitPos = getTarget(Origin)

    if HitPos then
        Direction = HitPos - Origin
        Velocity = Direction.Unit * Velocity.Magnitude
    end

    return OldNew(Caster, Origin, Direction, Velocity, ...)
end)

SG["success"]("Silent aim successfully executed!\nIf you have any issues press F9 or type /console in chat and then send me a screenshot of the console.");
