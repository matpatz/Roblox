-- Block Blast AutoPlay v3 - Lookahead + All v2 Improvements
-- v2: Combo priority, adaptive penalties, column balance, well strategy, full search, aggression
-- v3: Recursive lookahead, cache system, large-piece awareness, inaccessible space detection, board analysis

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
    LoadingSubtitle = "Initializing v3...",
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
    TickRate = 0.5,       -- [v3] Increased from 0.4 to give lookahead time
    Debug = false,
    Aggression = 1,        -- [v2] Scoring multiplier
    LookaheadDepth = 2,    -- [v3] 1=faster, 2=balanced, 3=optimal

    LastValidPositions = {},
    OverrideIndex = nil,
}

-- [v3] Lookahead cache
local LookaheadCache = {}
local CacheSize = 0
local MaxCacheSize = 5000

local OrigFindValid = Piece.FindValidPosition
local OrigGetClosest = Piece.GetClosestShape

local function SetState(Key, Value)
    States[Key] = Value
end

-----------------------------------------------------------------------------
-- Grid Utilities
-----------------------------------------------------------------------------

-- Clone from an arbitrary source grid (needed by lookahead recursion)
local function CloneGridFrom(SourceGrid)
    local GridClone = {}
    for Row = 1, 8 do
        GridClone[Row] = {}
        for Col = 1, 8 do
            GridClone[Row][Col] = SourceGrid[Row][Col]
        end
    end
    return GridClone
end

-- Convenience: clone the live game grid
local function CloneGrid()
    return CloneGridFrom(Grid.GridTable)
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

-- [v3] Extracted helper - simulates clearing all complete rows/columns in-place
-- Returns true if any lines were cleared
local function SimulateLineClears(GridTable)
    local Cleared = false

    for Row = 1, 8 do
        local Filled = true
        for Col = 1, 8 do
            if not GridTable[Row][Col] then
                Filled = false
                break
            end
        end
        if Filled then
            Cleared = true
            for Col = 1, 8 do
                GridTable[Row][Col] = false
            end
        end
    end

    for Col = 1, 8 do
        local Filled = true
        for Row = 1, 8 do
            if not GridTable[Row][Col] then
                Filled = false
                break
            end
        end
        if Filled then
            Cleared = true
            for Row = 1, 8 do
                GridTable[Row][Col] = false
            end
        end
    end

    return Cleared
end

-----------------------------------------------------------------------------
-- Board Analysis
-----------------------------------------------------------------------------

-- [v2] Lines that are 7/8 filled - combo setup detection
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

-- [v3] Check if a 3x3 block can fit anywhere (prevents the 3x3 trap)
local function CanFitLargePieces(GridTable)
    for Row = 1, 6 do
        for Col = 1, 6 do
            local Fits = true
            for r = 0, 2 do
                for c = 0, 2 do
                    if GridTable[Row + r][Col + c] then
                        Fits = false
                        break
                    end
                end
                if not Fits then break end
            end
            if Fits then return true end
        end
    end
    return false
end

-- [MERGED v2+v3] Enhanced BoardScore
--   v2: Adaptive height penalty tiers
--   v3: Inaccessible spaces (4-neighbor), ColumnVariance (statistical balance)
local function BoardScore(GridTable)
    local Holes = 0
    local Edge = 0
    local Height = 0
    local MaxHeight = 0
    local InaccessibleSpaces = 0
    local ColumnVariance = 0

    local Heights = {}
    for Col = 1, 8 do
        Heights[Col] = 0
    end

    for Row = 1, 8 do
        for Col = 1, 8 do
            if GridTable[Row][Col] then
                Height = Height + (8 - Row)
                MaxHeight = math.max(MaxHeight, 8 - Row)
                Heights[Col] = Heights[Col] + 1

                if Row == 8 or Col == 1 or Col == 8 then
                    Edge = Edge + 1
                end
            else
                local Neighbors = 0
                if Row > 1 and GridTable[Row - 1][Col] then Neighbors = Neighbors + 1 end
                if Row < 8 and GridTable[Row + 1][Col] then Neighbors = Neighbors + 1 end
                if Col > 1 and GridTable[Row][Col - 1] then Neighbors = Neighbors + 1 end
                if Col < 8 and GridTable[Row][Col + 1] then Neighbors = Neighbors + 1 end

                if Neighbors == 4 then
                    -- [v3] Completely enclosed empty cell - almost impossible to fill
                    InaccessibleSpaces = InaccessibleSpaces + 1
                end
                if Neighbors >= 3 then
                    Holes = Holes + 2
                end
            end
        end
    end

    -- [v3] Column variance - penalizes uneven column heights
    local AvgHeight = 0
    for _, H in ipairs(Heights) do
        AvgHeight = AvgHeight + H
    end
    AvgHeight = AvgHeight / 8

    for _, H in ipairs(Heights) do
        ColumnVariance = ColumnVariance + math.pow(H - AvgHeight, 2)
    end

    -- [v2] 3-tier dynamic height penalty
    local HeightPenalty
    if MaxHeight > 7 then
        HeightPenalty = 5.0   -- [v3] Increased from 2.0 - critical danger zone
    elseif MaxHeight > 6 then
        HeightPenalty = 2.0
    elseif MaxHeight > 5 then
        HeightPenalty = 0.5
    else
        HeightPenalty = 0.1
    end

    return Edge * 0.5
         + Height * HeightPenalty
         - Holes * 3.0
         - InaccessibleSpaces * 10.0
         - ColumnVariance * 0.5
end

-----------------------------------------------------------------------------
-- Scoring: Fast Path (v2 combo + well + v3 large-piece)
-----------------------------------------------------------------------------

-- [v2] Well-Building Strategy
local function CalculateWellPotential(GridTable, Cells)
    local Bonus = 0
    for _, CellId in ipairs(Cells) do
        local Row, Col = Grid:GetRowAndColumn(CellId)
        if Col > 1 and Col < 8 then
            if GridTable[Row][Col - 1] and GridTable[Row][Col + 1] then
                Bonus = Bonus + 25
            end
        end
    end
    return Bonus
end

-- Fast scoring: used for non-lookahead candidates and as first-pass filter
-- Combines v2 (combo + well + aggression) with v3 (large-piece awareness)
local function ScorePlacement(Cells)
    local GridClone = CloneGrid()
    if not ApplyPlacement(GridClone, Cells) then return -math.huge end

    local LineCount = CountLines(GridClone)
    local LineScore = LineCount * 100

    -- [v2] Bonus for near-complete lines (sets up combos)
    local NearLines = FindNearCompleteLines(GridClone)
    local ComboBonus = #NearLines * 50

    -- [v3] Large-piece survival check
    local CanFitLarge = CanFitLargePieces(GridClone)
    local LargePieceBonus = CanFitLarge and 500 or -1000

    -- [v2] Well-building bonus
    local WellBonus = CalculateWellPotential(GridClone, Cells)

    if LineCount > 0 then
        local Total = (LineScore * (1 + LineCount * 0.5)) + ComboBonus + LargePieceBonus + WellBonus + BoardScore(GridClone)
        return Total * States.Aggression
    end

    local Total = BoardScore(GridClone) + ComboBonus + LargePieceBonus + WellBonus
    return Total * States.Aggression
end

-----------------------------------------------------------------------------
-- [v3] Lookahead Engine
-----------------------------------------------------------------------------

local function GridToString(GridTable)
    local Key = {}
    for Row = 1, 8 do
        for Col = 1, 8 do
            table.insert(Key, GridTable[Row][Col] and "1" or "0")
        end
    end
    return table.concat(Key)
end

local function GetCachedScore(GridString, Depth)
    return LookaheadCache[GridString .. "_" .. Depth]
end

local function CacheScore(GridString, Depth, Score)
    local CacheKey = GridString .. "_" .. Depth

    if CacheSize >= MaxCacheSize then
        local Count = 0
        for Key in pairs(LookaheadCache) do
            LookaheadCache[Key] = nil
            Count = Count + 1
            if Count >= 1000 then break end
        end
        CacheSize = math.max(0, CacheSize - 1000)
    end

    if not LookaheadCache[CacheKey] then
        CacheSize = CacheSize + 1
    end
    LookaheadCache[CacheKey] = Score
end

-- Recursive board evaluation with simulated future moves
local function EvaluateBoardState(GridTable, Depth)
    if Depth == 0 then
        return BoardScore(GridTable)
    end

    local GridString = GridToString(GridTable)
    local CachedScore = GetCachedScore(GridString, Depth)
    if CachedScore then
        return CachedScore
    end

    local BestScore = -math.huge
    local LineCount = CountLines(GridTable)

    -- Simulate all possible placements with current available pieces
    for Model, Piece2D in pairs(Piece.Pieces2D) do
        local ValidPositions = OrigFindValid(Piece, GridTable, Piece2D)

        if ValidPositions and #ValidPositions > 0 then
            -- [v3] Limit per-piece positions in lookahead to control CPU
            local EvalLimit = math.min(8, #ValidPositions)
            for Index = 1, EvalLimit do
                local Cells = ValidPositions[Index]
                local TestGrid = CloneGridFrom(GridTable)

                if ApplyPlacement(TestGrid, Cells) then
                    local TestLineCount = CountLines(TestGrid)
                    local LineClears = TestLineCount - LineCount

                    -- Simulate line clearing after this placement
                    if LineClears > 0 then
                        SimulateLineClears(TestGrid)
                    end

                    local Score = (LineClears * 100) + EvaluateBoardState(TestGrid, Depth - 1)
                    if Score > BestScore then
                        BestScore = Score
                    end
                end
            end
        end
    end

    -- If no moves were possible, fall back to static board eval
    if BestScore == -math.huge then
        BestScore = BoardScore(GridTable)
    end

    CacheScore(GridString, Depth, BestScore)
    return BestScore
end

-- Full scoring with lookahead: immediate evaluation + recursive future projection
local function ScorePlacementWithLookahead(Cells)
    local GridClone = CloneGrid()
    if not ApplyPlacement(GridClone, Cells) then return -math.huge end

    local ImmediateLineCount = CountLines(GridClone)
    local ImmediateScore = ImmediateLineCount * 100

    -- [v2] Combo and well bonuses on the immediate state
    local NearLines = FindNearCompleteLines(GridClone)
    local ComboBonus = #NearLines * 50
    local WellBonus = CalculateWellPotential(GridClone, Cells)

    -- [v3] Large-piece check on the immediate state
    local CanFitLarge = CanFitLargePieces(GridClone)
    local LargePieceBonus = CanFitLarge and 500 or -1000

    -- Simulate line clearing before evaluating the future
    if ImmediateLineCount > 0 then
        SimulateLineClears(GridClone)
    end

    -- Recursive future evaluation
    local FutureScore = EvaluateBoardState(GridClone, States.LookaheadDepth)

    local Total = ImmediateScore + ComboBonus + WellBonus + LargePieceBonus + FutureScore

    -- [v2] Apply aggression multiplier
    if ImmediateLineCount > 0 then
        Total = Total * (1 + ImmediateLineCount * 0.5)
    end

    return Total * States.Aggression
end

-----------------------------------------------------------------------------
-- [MERGED] Move Selection: Two-Pass Lookahead
--   Pass 1: Quick ScorePlacement on ALL positions (v2 full-search improvement)
--   Pass 2: Re-evaluate top 15 candidates with expensive lookahead (v3)
-----------------------------------------------------------------------------

local function PickBestMoveWithLookahead()
    -- Pass 1: Fast eval on ALL valid positions
    local Candidates = {}

    for Model, Positions in pairs(States.LastValidPositions) do
        if not Piece.Pieces2D[Model] then continue end
        if not Positions or #Positions == 0 then continue end

        for Index = 1, #Positions do
            local Score = ScorePlacement(Positions[Index])
            table.insert(Candidates, {
                Model = Model,
                Index = Index,
                Score = Score,
            })
        end
    end

    if #Candidates == 0 then
        return nil, nil, -math.huge
    end

    -- Sort by fast score descending
    table.sort(Candidates, function(a, b) return a.Score > b.Score end)

    -- Pass 2: Re-evaluate top candidates with lookahead
    local BestScore = -math.huge
    local BestModel = nil
    local BestIndex = nil
    local ReEvalCount = math.min(15, #Candidates)

    for i = 1, ReEvalCount do
        local Candidate = Candidates[i]
        local Positions = States.LastValidPositions[Candidate.Model]
        local Score = ScorePlacementWithLookahead(Positions[Candidate.Index])

        if States.Debug then
            print(string.format(
                "[Lookahead] Candidate %d/%d (piece %d, pos %d): fast=%.1f -> lookahead=%.1f",
                i, ReEvalCount, Candidate.Index, Candidate.Index,
                Candidate.Score, Score
            ))
        end

        if Score > BestScore then
            BestScore = Score
            BestModel = Candidate.Model
            BestIndex = Candidate.Index
        end
    end

    return BestModel, BestIndex, BestScore
end

-----------------------------------------------------------------------------
-- Placement Execution
-----------------------------------------------------------------------------

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

    -- [v3] Use two-pass lookahead move selection
    local BestModel, BestIndex, BestScore = PickBestMoveWithLookahead()
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

    -- [v3] Clear lookahead cache after placement (board state changed)
    if BestScore > 0 then
        LookaheadCache = {}
        CacheSize = 0
    end

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

    if States.Debug then
        print(string.format("[AutoPlay] Placed piece | Score: %.1f | Cache: %d/%d",
            BestScore or 0, CacheSize, MaxCacheSize))
    end
end

-----------------------------------------------------------------------------
-- Loop Control
-----------------------------------------------------------------------------

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

-----------------------------------------------------------------------------
-- UI
-----------------------------------------------------------------------------

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
    Name = "Reset Position Cache",
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

-- [v3] Board analysis button
Tabs.Main:CreateButton({
    Name = "Analyze Current Board",
    Callback = function()
        local EmptySpaces = 0
        local Holes = 0
        local MaxH = 0

        for Row = 1, 8 do
            for Col = 1, 8 do
                if not Grid.GridTable[Row][Col] then
                    EmptySpaces = EmptySpaces + 1
                    local N = 0
                    if Row > 1 and Grid.GridTable[Row-1][Col] then N = N + 1 end
                    if Row < 8 and Grid.GridTable[Row+1][Col] then N = N + 1 end
                    if Col > 1 and Grid.GridTable[Row][Col-1] then N = N + 1 end
                    if Col < 8 and Grid.GridTable[Row][Col+1] then N = N + 1 end
                    if N >= 3 then Holes = Holes + 1 end
                else
                    MaxH = math.max(MaxH, 8 - Row)
                end
            end
        end

        local CanFit3x3 = CanFitLargePieces(Grid.GridTable)
        local NearLines = FindNearCompleteLines(Grid.GridTable)

        Rayfield:Notify({
            Title = "Board Analysis",
            Content = string.format(
                "Empty: %d | Holes: %d | Peak: %d\n3x3 Fits: %s | Near-Lines: %d\nLookahead Cache: %d/%d",
                EmptySpaces, Holes, MaxH,
                CanFit3x3 and "YES" or "NO",
                #NearLines,
                CacheSize, MaxCacheSize
            ),
            Duration = 6,
            Image = 4483362458,
        })
    end,
})

Tabs.Settings:CreateLabel("Configuration")

Tabs.Settings:CreateSlider({
    Name = "Tick Rate",
    Range = { 0, 2 },
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(Value)
        if Value == 0 then
            Value = 0.09
        end
        SetState("TickRate", Value)
    end,
})

-- [v2] Aggression slider
Tabs.Settings:CreateSlider({
    Name = "Aggression",
    Range = { 0.1, 2 },
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(Value)
        SetState("Aggression", Value)
    end,
})

-- [v3] Lookahead depth control
Tabs.Settings:CreateSlider({
    Name = "Lookahead Depth",
    Range = { 0, 3 },
    Increment = 1,
    CurrentValue = 2,
    Callback = function(Value)
        States.LookaheadDepth = Value
        -- Clear cache since depth changed, all entries are now invalid
        LookaheadCache = {}
        CacheSize = 0
    end,
})

Tabs.Settings:CreateButton({
    Name = "Clear Lookahead Cache",
    Callback = function()
        LookaheadCache = {}
        CacheSize = 0
        Rayfield:Notify({
            Title = "Cache",
            Content = "Lookahead cache cleared.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

Tabs.Settings:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Callback = function(Value)
        SetState("Debug", Value)
    end,
})

-----------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------

Rayfield:Notify({
    Title = GameName,
    Content = "AutoPlay v3 loaded! (Lookahead Engine)",
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
