--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager
local playermanager = Knit.player

local utils = scriptmanager.get("utils")

local name = scriptmanager.name
local config = scriptmanager.config.set(
    {
        SilentAim = {
            Value = false
        }
    }
)

--// Services
local ReplicatedStorage = services.ReplicatedStorage
local Players = services.Players

--// Events
local FireEvent = ReplicatedStorage:WaitForChild("networkEvents"):WaitForChild("rE")

--// player
local LocalPlayer = playermanager.LocalPlayer

--// core
local core = {}

core = scriptmanager.set("core", core)

--// Silent aim

-- The client resolves every shot itself and reports the result to the server
-- through networkEvents.rE (source/shoot_remote_example.lua):
--
--     (weapon key, player key, hit part, hit position, hit normal, hit material, ...)
--
-- The server takes that report as the shot, so writing the aim part into those
-- four fields is the whole trick: the camera keeps pointing wherever the player
-- is looking and the shot still lands on the target.

-- TEMP tracing: the client cannot be read from here, so what actually goes out
-- on a shot is written to sc_rE.log in the executor workspace. Remove later.
local Traces = 0
local function Trace(Message: string)
    if appendfile and Traces < 80 then
        Traces += 1
        appendfile("sc_rE.log", Message .. "\n")
    end
end

type PackedArgs = { [number]: any, n: number }

local function Describe(Args: PackedArgs): string
    local Fields = {}

    for Index = 1, math.min(Args.n or 0, 9) do
        local Value = Args[Index]
        local Text = if typeof(Value) == "string"
            then Value
            elseif typeof(Value) == "Instance"
            then Value:GetFullName()
            elseif typeof(Value) == "Vector3"
            then tostring(Value)
            else typeof(Value)

        table.insert(Fields, `[${Index}] ${typeof(Value)} ${Text}`)
    end

    return table.concat(Fields, " | ")
end

-- The four fields the server reads the hit from, or the arguments untouched
-- when there is nothing to aim at.
local function Redirect(Source: string, Args: PackedArgs): (PackedArgs, number)
    local AimPart = if config.SilentAim.Value then utils["Aimbot"].GetClosest() else nil
    local HumanoidRootPart = playermanager.HumanoidRootPart

    Trace(`{Source} enabled=${config.SilentAim.Value} aim=${if AimPart then AimPart:GetFullName() else "nil"} root=${if HumanoidRootPart then "yes" else "nil"} ${Describe(Args)}`)

    if not AimPart or not HumanoidRootPart then
        return Args, Args.n or 0
    end

    Args[3] = AimPart
    Args[4] = AimPart.Position
    Args[5] = (AimPart.Position - HumanoidRootPart.Position).Unit
    Args[6] = AimPart.Material

    Trace(`  rewritten ${Describe(Args)}`)

    return Args, Args.n or 0
end

if writefile then
    writefile("sc_rE.log", `installed ${FireEvent:GetFullName()}\n`)
end

-- an instance method called with `:` goes through __namecall, which is why a
-- hook on FireServer itself never sees the shot
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
    if Self ~= FireEvent or getnamecallmethod() ~= "FireServer" then
        return OldNamecall(Self, ...)
    end

    local Args, Count = Redirect("namecall", table.pack(...))

    return OldNamecall(Self, table.unpack(Args, 1, Count))
end)

-- kept for executors that hand the call to the method itself instead
if isfunctionhooked(FireEvent.FireServer) then
    restorefunction(FireEvent.FireServer)
end

local OldFireServer
OldFireServer = hookfunction(FireEvent.FireServer, function(Self, ...)
    if Self ~= FireEvent then
        return OldFireServer(Self, ...)
    end

    local Args, Count = Redirect("fireserver", table.pack(...))

    return OldFireServer(Self, table.unpack(Args, 1, Count))
end)

return core