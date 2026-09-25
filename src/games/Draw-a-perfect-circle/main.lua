local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
	Name = "Draw",
	LoadingTitle = "drawin",
	LoadingSubtitle = "Subtitle",
})

local config = {
    Accuracy = 80,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Main = Window:CreateTab("Main")
local a = Window:CreateTab("a")

local Accuracy = config.Accuracy
Main:CreateSlider({
	Name = "Accuracy",
	Range = {1, 100},
	Increment = 1,
	Suffix = "%",
	CurrentValue = Accuracy,
	Flag = "a",
	Callback = function(v)
		config.Accuracy = v
	end,
})

Main:CreateButton({
	Name = "Draw",
	Callback = function()
        ReplicatedStorage.sendScore:InvokeServer(
            config.Accuracy / math.random(1.2, 1.5),
            tonumber(workspace:FindFirstChild("Canvas").Parent.Name)
        )
	end,
})
