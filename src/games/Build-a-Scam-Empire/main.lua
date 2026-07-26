getgenv().Autofarm = getgenv().Autofarm or true 
getgenv().SellAll = getgenv().SellAll or true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Plot = workspace.Main.Plots:FindFirstChild(tostring(LocalPlayer.Values.Plot.Value))

local Claim = ReplicatedStorage.Communication.Functions[""]
local SellAll = ReplicatedStorage.Communication.Functions:GetChildren()[3]

while task.wait(2) do
	if not Plot then
		print("wee are cooked")
		break
	end

	if getgenv().Autofarm then
		for _, Item in ipairs(Plot.Items:GetChildren()) do
			pcall(function()
				Claim:InvokeServer(Item)
			end)
		end
	end
	if getgenv().SellAll and SellAll then
		SellAll:InvokeServer()
	end
end
