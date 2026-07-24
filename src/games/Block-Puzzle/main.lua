local Services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local GameName = Services["marketplace"]:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GameFolder = workspace:WaitForChild("Game", 60)
local GridFolder = GameFolder:WaitForChild("Grid")
local PiecesFolder = GameFolder:WaitForChild("Pieces")
local PieceRemote = Remotes:WaitForChild("Piece")

local Grid = require(Modules:WaitForChild("Grid"))
local Piece = require(Modules:WaitForChild("Piece"))
local Values = require(Modules:WaitForChild("Values"))

local Window = Rayfield:CreateWindow({
    Name = GameName,
    LoadingTitle = "AutoPlay",
    LoadingSubtitle = "Initializing...",
})

local Tabs = {
    Main = Window:CreateTab("Main", 4483362458),
    Settings = Window:CreateTab("Settings", 4483362458),
}

local Connections = {
    Loop = nil,
}

local States = {
    Enabled = true,
    TickRate = 0.4,
    Debug = false,
    
    LastValidPositions = {},
    OverrideIndex = nil,
}

local OrigFindValid = Piece.FindValidPosition
local OrigGetClosest = Piece.GetClosestShape

local function SetState(Key, Value)
    States[Key] = Value
end

local function CloneGrid()
    local GridClone = {}
    for Row = 1, 8 do
        GridClone[Row] = {}
        for Col = 1, 8 do
            GridClone[Row][Col] = Grid.GridTable[Row][Col]
        end
    end
    return GridClone
end

local function ApplyPlacement(GridTable, Cells)
    for _, CellId in ipairs(Cells) do
        local Row, Col = Grid:GetRowAndColumn(CellId)
        if not Row or GridTable[Row][Col] then return false end
    end
    
    for _, CellId in ipairs(Cells) do
        local Row, Col = Grid:GetRowAndColumn(CellId)
        GridTable[Row][Col] = true
    end
    
    return true
end

local function CountLines(GridTable)
    local Count = 0
    
    for Row = 1, 8 do
        local Filled = true
        for Col = 1, 8 do
            if not GridTable[Row][Col] then
                Filled = false
                break
            end
        end
        if Filled then Count = Count + 1 end
    end
    
    for Col = 1, 8 do
        local Filled = true
        for Row = 1, 8 do
            if not GridTable[Row][Col] then
                Filled = false
                break
            end
        end
        if Filled then Count = Count + 1 end
    end
    
    return Count
end

local function BoardScore(GridTable)
    local Holes = 0
    local Edge = 0
    local Height = 0
    local MaxHeight = 0
    
    for Row = 1, 8 do
        for Col = 1, 8 do
            if GridTable[Row][Col] then
                Height = Height + (8 - Row)
                MaxHeight = math.max(MaxHeight, 8 - Row)
                if Row == 8 or Col == 1 or Col == 8 then
                    Edge = Edge + 1
                end
            else
                local Neighbors = 0
                if Row > 1 and GridTable[Row - 1][Col] then Neighbors = Neighbors + 1 end
                if Row < 8 and GridTable[Row + 1][Col] then Neighbors = Neighbors + 1 end
                if Col > 1 and GridTable[Row][Col - 1] then Neighbors = Neighbors + 1 end
                if Col < 8 and GridTable[Row][Col + 1] then Neighbors = Neighbors + 1 end
                if Neighbors >= 3 then Holes = Holes + 2 end
            end
        end
    end
    
    local HeightPenalty = MaxHeight > 6 and 0.5 or 0.1
    return Edge * 0.5 + Height * HeightPenalty - Holes * 1.5
end

local function FindNearCompleteLines(GridTable)
    local NearLines = {}
    
    for Row = 1, 8 do
        local Filled = 0
        for Col = 1, 8 do
            if GridTable[Row][Col] then Filled = Filled + 1 end
        end
        if Filled >= 7 then table.insert(NearLines, { Type = "Row", Index = Row, Filled = Filled }) end
    end
    
    for Col = 1, 8 do
        local Filled = 0
        for Row = 1, 8 do
            if GridTable[Row][Col] then Filled = Filled + 1 end
        end
        if Filled >= 7 then table.insert(NearLines, { Type = "Col", Index = Col, Filled = Filled }) end
    end
    
    return NearLines
end

local function ScorePlacement(Cells)
    local GridClone = CloneGrid()
    if not ApplyPlacement(GridClone, Cells) then return -math.huge end
    
    local LineCount = CountLines(GridClone)
    local LineScore = LineCount * 100
    
    if LineCount > 0 then
        return LineScore + BoardScore(GridClone)
    end
    
    return BoardScore(GridClone)
end

local function PickBestMove()
    local BestScore = -math.huge
    local BestModel = nil
    local BestIndex = nil
    
    for Model, Positions in pairs(States.LastValidPositions) do
        if not Piece.Pieces2D[Model] then continue end
        if not Positions or #Positions == 0 then continue end
        
        local MaxCheck = math.min(8, #Positions)
        for Index = 1, MaxCheck do
            local Score = ScorePlacement(Positions[Index])
            if Score > BestScore then
                BestScore = Score
                BestModel = Model
                BestIndex = Index
            end
        end
    end
    
    return BestModel, BestIndex, BestScore
end

local TweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function TryAutoPlace()
    local UI = PlayerGui:FindFirstChild("UI")
    if UI and UI:FindFirstChild("Settings") and UI.Settings.Visible then return end
    
    if not LocalPlayer:GetAttribute("Playing") then return end
    
    for Model, Piece2D in pairs(Piece.Pieces2D) do
        if not States.LastValidPositions[Model] then
            local Positions = OrigFindValid(Piece, Grid.GridTable, Piece2D)
            States.LastValidPositions[Model] = Positions
        end
    end
    
    local BestModel, BestIndex, BestScore = PickBestMove()
    if not BestModel or not BestIndex then return end
    
    local Positions = States.LastValidPositions[BestModel]
    local BestCells = Positions[BestIndex]
    local BestPiece2D = Piece.Pieces2D[BestModel]
    
    if not BestCells or not BestPiece2D then return end
    
    local Children = BestModel:GetChildren()
    for i, CellId in ipairs(BestCells) do
        local GridCell = GridFolder:FindFirstChild(tostring(CellId))
        if not GridCell then continue end
        
        GridCell:SetAttribute("Taken", true)
        
        local Part = Children[i]
        if not Part then continue end
        
        Part:SetAttribute("Brightness", Part.SurfaceGui and Part.SurfaceGui.Brightness or 1)
        Part:SetAttribute("Color", Part.SurfaceGui and Part.SurfaceGui.Frame.ImageColor3 or Color3.new(1, 1, 1))
        Part:SetAttribute("Cell", GridCell.Name)
        Part.CFrame = GridCell.CFrame * CFrame.new(0, 0, 0.501)
        Part.Parent = PiecesFolder
        Part.Name = tostring(CellId)
        
        local Row, Col = Grid:GetRowAndColumn(CellId)
        Grid.GridTable[Row][Col] = true
    end
    
    local CellCount = 0
    for _, Row in ipairs(BestPiece2D) do
        for _ in ipairs(Row) do
            CellCount = CellCount + 1
        end
    end
    
    task.spawn(function()
        PieceRemote:InvokeServer("Place", BestPiece2D, BestCells)
    end)
    
    Piece.Pieces2D[BestModel] = nil
    States.LastValidPositions[BestModel] = nil
    
    local FilledLines = Grid:GetFilledLines(BestCells)
    if FilledLines and #FilledLines > 0 then
        Values.CurrentComboLevel = Values.CurrentComboLevel + (#FilledLines // 8)
        if Values.CurrentComboLevel > 0 then
            Values.Score = Values.Score + Values.BaseComboPoints * Values.CurrentComboLevel
            Values.ComboCountdown = Values.ComboMaxMoves
        end
        for _, CellId in ipairs(FilledLines) do
            local Row, Col = Grid:GetRowAndColumn(CellId)
            Grid.GridTable[Row][Col] = false
            local Part = PiecesFolder:FindFirstChild(tostring(CellId))
            if Part then Part:Destroy() end
        end
    else
        local Countdown = math.max(0, Values.ComboCountdown - 1)
        Values.ComboCountdown = Countdown
        if Countdown == 0 then Values.CurrentComboLevel = 0 end
    end
    
    Values.Score = Values.Score + CellCount
    TweenService:Create(Values.ScoreValue, TweenInfo, { Value = Values.Score }):Play()
    
    BestModel:Destroy()
    
    local Remaining = 0
    for _ in pairs(Piece.Pieces2D) do Remaining = Remaining + 1 end
    if Remaining == 0 then
        Piece:GenerateRandomPieces()
    end
    
    for _, Cell in ipairs(GridFolder:GetChildren()) do
        local SurfaceGui = Cell:FindFirstChild("SurfaceGui")
        local SelectionBox = Cell:FindFirstChild("SelectionBox")
        if SurfaceGui then SurfaceGui.Enabled = false end
        if SelectionBox then SelectionBox.Visible = false end
    end
    
    Piece:HighlightInvalidPieces()
end

local function Stop()
    SetState("Enabled", false)
    if Connections.Loop then
        Connections.Loop:Disconnect()
        Connections.Loop = nil
    end
end

local function Start()
    if Connections.Loop then Connections.Loop:Disconnect() end
    
    SetState("Enabled", true)
    local ElapsedTime = 0
    
    Connections.Loop = RunService.Heartbeat:Connect(function(DeltaTime)
        if not States.Enabled then
            Stop()
            return
        end
        
        ElapsedTime = ElapsedTime + DeltaTime
        if ElapsedTime >= States.TickRate then
            ElapsedTime = 0
            local Success, Error = pcall(TryAutoPlace)
            if not Success and States.Debug then
                warn("[AutoPlay]", Error)
            end
        end
    end)
end

Tabs.Main:CreateLabel("Auto Placement")

Tabs.Main:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Callback = function(Value)
        if Value then
            Start()
        else
            Stop()
        end
    end,
})

Tabs.Main:CreateButton({
    Name = "Reset Cache",
    Callback = function()
        States.LastValidPositions = {}
        Rayfield:Notify({
            Title = "Cache",
            Content = "Position cache cleared.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

Tabs.Settings:CreateLabel("Configuration")

Tabs.Settings:CreateSlider({
    Name = "Tick Rate",
    Range = { 0, 2 },
    Increment = 0.1,
    CurrentValue = 0.4,
    Callback = function(Value)
		if Value == 0 then
			Value = 0.09 -- 0 is just instant lose, idk why.
		end
        SetState("TickRate", Value)
    end,
})

Tabs.Settings:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Callback = function(Value)
        SetState("Debug", Value)
    end,
})

Rayfield:Notify({
    Title = GameName,
    Content = "AutoPlay loaded successfully!",
    Duration = 5,
    Image = 4483362458,
})

OrigFindValid = hookfunction(Piece.FindValidPosition, newlclosure(function(self, GridTable, Piece2D)
    local Positions = OrigFindValid(self, GridTable, Piece2D)
    
    for Model, P2D in pairs(Piece.Pieces2D) do
        if P2D == Piece2D then
            States.LastValidPositions[Model] = Positions
            break
        end
    end
    
    return Positions
end))

OrigGetClosest = hookfunction(Piece.GetClosestShape, newlclosure(function(self, PieceModel, ValidPositions)
    if States.OverrideIndex then
        local Index = States.OverrideIndex
        States.OverrideIndex = nil
        return Index
    end
    
    return OrigGetClosest(self, PieceModel, ValidPositions)
end))

Start()