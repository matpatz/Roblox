local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FlagsModule = require(ReplicatedStorage.Packages.GameData.Flags)
local FlagsService = ReplicatedStorage.Packages.Knit.Services.FlagsService

local SolveRemote = FlagsService.RF.Solve
local TriggerEvent = FlagsService.RE.TriggerGameSolution

TriggerEvent.OnClientEvent:Connect(function(Identifer, data)
	task.wait(tonumber(getgenv().timer))
    if Identifer ~= "ShowFlag" then return end

    local ImageId = data.SolutionImageId
    local Rarity = data.Rarity or "Cakewalk"
    local Country

    for _, flag in ipairs(FlagsModule[Rarity] or {}) do
        if flag.ImageId == ImageId then
            Country = flag.CountryName
            break
        end
    end

    if Country then
        SolveRemote:InvokeServer(Country)
        print("Answered:", Country)
        getgenv().LastAnswer = Country
    else
        warn("failed, image Id:", ImageId)
    end
end)
