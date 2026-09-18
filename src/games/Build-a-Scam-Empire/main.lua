local Knit = shared.Knit
local services = Knit.services

getgenv().Autofarm = true 
getgenv().SellAll = true

local ReplicatedStorage = services.ReplicatedStorage
local Players = services.Players

local LocalPlayer = Players.LocalPlayer

local plotid = tostring(LocalPlayer.Values.Plot.Value)
local Plot = workspace.Main.Plots:FindFirstChild(plotid)

local ClaimFunction = ReplicatedStorage.Communication.Functions[""]
local SellFunciton = ReplicatedStorage.Communication.Functions:GetChildren()[3]

while task.wait(2) do
	if not Plot then
		print("wee are cooked")
		break
	end

	if getgenv().Autofarm then
		for _, Item in ipairs(Plot.Items:GetChildren()) do
			pcall(function()
				ClaimFunction:InvokeServer(Item)
			end)
		end
	end
	if getgenv().SellAll and SellFunciton then
		SellAll:InvokeServer()
	end
end
