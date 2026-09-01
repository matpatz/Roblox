const ReplicatedStorage = game:GetService("ReplicatedStorage")
const _GrowCharacter = ReplicatedStorage.GrowCharacter

local Character = game.Players.LocalPlayer.Character
local HumanoidRootPart = Character.HumanoidRootPart

const FolderChildren = workspace:QueryDescendants("Folder > #Button > MeshPart#button1")
local function Activate(Child)
	firetouchinterest(HumanoidRootPart, Child, true)
	firetouchinterest(HumanoidRootPart, Child, false)
end

local function _ClaimWins()
	for _, Child in next, FolderChildren do
		Activate(Child)
	end
end

local function GrowCharacter()
	for i = 1, 20 do
		_GrowCharacter:FireServer()
	end
end

while task.wait() do
	task.spawn(GrowCharacter)

	task.delay(3, _ClaimWins) -- large queue will prolly error sometime
end