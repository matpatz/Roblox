local ReplicatedStorage = game:GetService("ReplicatedStorage")
const _GiveLevel = ReplicatedStorage.GiveLevel 
const _GiveMoney = ReplicatedStorage.GiveMoney

local function GiveLevel()
    _GiveLevel:FireServer()
end

local Delay = 0
local function GiveMoney()
	for Money = 1, 20 do
		Delay += 1
		task.delay(Delay, GiveLevel)
		_GiveMoney:FireServer(Money * math.random(5, 8))
	end
	Delay = 0
end

while task.wait() do
    task.spawn(GiveMoney)
end
