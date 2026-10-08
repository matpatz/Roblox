local Knit = shared.Knit
local services = Knit.services

local Players = services.Players
local Player = Players.LocalPlayer
local cam = workspace.CurrentCamera

local states = {
	Spectating = false,
	TargetPlayer = nil,
	RenderConnection = nil,
	MovementFrozen = false
}

local Rayfield = Knit.ui.new("Rayfield")()
local Window = Rayfield:CreateWindow({
   Name = "Spectaction",
   LoadingTitle = "1 != 2",
   LoadingSubtitle = "fuhh you",
   ConfigurationSaving = { Enabled = false }
})

local function GetPlayerNames()
	local List = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player then
			table.insert(List, p.Name)
		end
	end
	return List
end

local function StartSpectate(plr)
	if not plr then return end

	states.TargetPlayer = plr
	states.Spectating = true

	cam.CameraType = Enum.CameraType.Scriptable

	states.RenderConnection = services.RunService.RenderStepped:Connect(function()
		if not states.Spectating then return end
		if not states.TargetPlayer or not states.TargetPlayer.Character then return end

		local hrp = states.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local goal = hrp.CFrame * CFrame.new(0, 5, 12)

		cam.CFrame = cam.CFrame:Lerp(goal, 0.15)
	end)
end

local function StopSpectate()
	states.Spectating = false
	states.TargetPlayer = nil

	if states.RenderConnection then
		states.RenderConnection:Disconnect()
		states.RenderConnection = nil
	end

	cam.CameraType = Enum.CameraType.Custom
end

local function SetMovementBlocked(state)
	if state then
		services.ContextActionService:BindAction(
			"BlockMovement",
			function()
				return Enum.ContextActionResult.Sink
			end,
			false,
			Enum.PlayerActions.CharacterForward,
			Enum.PlayerActions.CharacterBackward,
			Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight,
			Enum.PlayerActions.CharacterJump
		)
	else
		services.ContextActionService:UnbindAction("BlockMovement")
	end
end

local SpectateTab = Window:CreateTab("Spectate")

local Dropdown = SpectateTab:CreateDropdown({
   Name = "Select Player",
   Options = GetPlayerNames(),
   CurrentOption = {},
   MultipleOptions = false,
   Flag = "",

   Callback = function(Options)
      local name = Options[1]
      local plr = Players:FindFirstChild(name)

      if plr then
         StartSpectate(plr)
      end
   end,
})

SpectateTab:CreateButton({
   Name = "Stop Spectate",
   Callback = function()
      StopSpectate()
   end,
})

local function Refresh()
	Dropdown:Refresh(GetPlayerNames())
end

Players.PlayerAdded:Connect(Refresh)
Players.PlayerRemoving:Connect(Refresh)

local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateToggle({
   Name = "Freeze Movement",
   CurrentValue = false,
   Flag = "FreezeMovement",

   Callback = function(Value)
      states.MovementFrozen = Value
      SetMovementBlocked(Value)
   end,
})

Player.CharacterAdded:Connect(function()
	task.wait(1)
	if states.MovementFrozen then
		SetMovementBlocked(true)
	end
end)