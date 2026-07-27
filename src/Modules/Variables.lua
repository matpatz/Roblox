repeat
    task.wait()
until game:IsLoaded()

local Game = game

local ServiceMap = {
    Players = "Players",
    Workspace = "Workspace",
    RunService = "RunService",
    CoreGui = "CoreGui",
    UserInputService = "UserInputService",
    ReplicatedStorage = "ReplicatedStorage",
    Lighting = "Lighting",
    VirtualInputManager = "VirtualInputManager",
    TextChatService = "TextChatService",
    RbxAnalyticsService = "RbxAnalyticsService",
    MarketplaceService = "MarketplaceService",
    TeleportService = "TeleportService",
    HttpService = "HttpService",
    GuiService = "GuiService",
    StarterGui = "StarterGui",
    Teams = "Teams",
    SoundService = "SoundService",
    CollectionService = "CollectionService",
    TweenService = "TweenService",
    Stats = "Stats",
    Debris = "Debris",
    PathfindingService = "PathfindingService",
    InsertService = "InsertService",
    ContextActionService = "ContextActionService",
    PhysicsService = "PhysicsService",
    ProximityPromptService = "ProximityPromptService",
    GroupService = "GroupService",
    LocalizationService = "LocalizationService",
    Chat = "Chat",
    StarterPack = "StarterPack",
    StarterPlayer = "StarterPlayer",
    MaterialService = "MaterialService",
    AssetService = "AssetService",
    ScriptContext = "ScriptContext",
    ContentProvider = "ContentProvider"
}

local CloneRef = (typeof(cloneref) == "function" and cloneref)
    or function(Object)
        return Object
    end

local Services = {}

for VariableName, ServiceName in next, ServiceMap do
    Services[VariableName] = CloneRef(
        Game:GetService(ServiceName)
    )
end

if getgenv().PlayerHelper then
    local Player = Services.Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()

    Services.Player = Player
    Services.Character = Character
    Services.Humanoid = Character:FindFirstChildOfClass("Humanoid")
    Services.HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    Services.Camera = Services.Workspace.CurrentCamera
    Services.Mouse = Player:GetMouse()

    Player.CharacterAdded:Connect(function(Character)
        Services.Character = Character
        Services.Humanoid = Character:FindFirstChildOfClass("Humanoid")
        Services.HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    end)
end

return setmetatable(Services, {
    __index = function(_, Key)
        error(
            ("[Services] Unknown index -> %s")
                :format(tostring(Key)),
            2
        )
    end
})

-- Usage:

-- local Services = loadstring(
--     game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Variable.lua")
-- )()

-- print(Services.Workspace)
-- print(Services.HumanoidRootPart)
