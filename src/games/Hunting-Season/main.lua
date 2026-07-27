local remote = require(game:GetService("ReplicatedStorage").Common.Replica.ReplicaShared.Remote)

local get = (type(cloneref) == "function") and cloneref or function(x) return x end
local marketplace = get(game:GetService("MarketplaceService"))
local players = get(game:GetService("Players"))
local rep = get(game:GetService("ReplicatedStorage"))
local tweens = get(game:GetService("TweenService"))
local lighting = get(game:GetService("Lighting"))
local uis = get(game:GetService("UserInputService"))
local cas = get(game:GetService("ContextActionService"))
local runs = get(game:GetService("RunService"))

local hrp = players.LocalPlayer.Character.HumanoidRootPart
local cam = workspace.CurrentCamera

rep["Modules"]["Velocity"]["Settings"]["BanServiceSettings"]["BanDatastoreName"].Value = tostring(math.random(1e9, 2e9))
rep["Modules"]["Velocity"]["Settings"]["BanServiceSettings"]["BanDefaultReason"].Value = "Sorry! but atleast I know this worked"

--[[ -- the module is broken
    local ban = require(rep.Modules.Velocity.Services.BanService)
    local old; old = hookfunction(ban.BanPlayer, function(...)
        return nil
    end)
    local old2; old2 = hookfunction(ban.CheckBan, function(...)
        return false
    end)
]]

pcall(function()
    local kbp = game["ReplicatedStorage"]["InbuiltEvents"]["kickedBannedPlayer"]
    if kbp then kbp:Destroy() end
end)

local gname = marketplace:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))(); --local flags = Rayfield.Flags
local Window = Rayfield:CreateWindow({
	Name = gname,
	LoadingTitle = "fuh you",
	LoadingSubtitle = "subtitle",
})

local combat = Window:CreateTab("Combat")

combat:CreateLabel("Shoot")

local aimbot = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/aimbot.lua"))()

local function gclosest()
    local nearest, nearestDist = nil, math.huge
    local pos = hrp.Position

    for _, item in ipairs(Workspace.Animals:GetChildren()) do
        local root = item:FindFirstChild("RootPart")
        if root then
            local dist = (root.Position - pos).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = root
            end
        end
    end

    return nearest
end

local sam, projh, rifle = false, require(rep["Modules"]["ProjectileHandler"]), require(rep["Classes"]["Rifle"])
combat:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "sa",
    Callback = function(v)
        sam = v
    end,
})

local old
old = hookfunction(rifle.Fire, function(self, ...)
    
    if sam then
        local target = gclosest()
        if target then
            local camera = workspace.CurrentCamera
            local oldCF = camera.CFrame
            
            camera.CFrame = CFrame.new(
                oldCF.Position,
                target.Position
            )

            local result = old(self, ...)
            camera.CFrame = oldCF
            return result
        end
    end

    return old(self, ...)
end)

--[[
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if silentAim and method == "Fire" and self == projh then
            local origin, direction, speed = args[1], args[2], args[3]
            local target = gclosest()
            if targfet then
                -- dir vector
                args[2] = (target.Position - origin).Unit
            end
            return old(self, unpack(args))
        end

        return old(self, ...)
    end)
--]]

combat:CreateLabel("Weapon Mods")

local function restore(func)
    if isfunctionhooked(func) then
        restorefunction(func)
        func = nil
    end
end

local rmod = require(rep["Classes"]["Rifle"])

local ogAmmo = function() end
combat:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Flag = "ia",
    Callback = function(v)
        if v then
            ogAmmo = hookfunction(rmod.Fire, function(self, ...)
                print(v)
                print("mag:", self.BulletsInMagazine)

                if v then self.BulletsInMagazine = self.MagazineCapacity + 1 end
                self.CanReload = v

                return ogAmmo(self, ...)
            end)
        else
            restore(ogAmmo)
        end
    end,
})

local ogHit = function() end
combat:CreateToggle({
    Name = "Insta Hit",
    CurrentValue = false,
    Flag = "ih",
    Callback = function(v)
        if v then
            ogHit = hookfunction(rmod.Fire, function(self, ...)
                local oldVelocity = self.MuzzleVelocity
                self.MuzzleVelocity = 1e4
                local result = ogHit(self, ...)
                --self.MuzzleVelocity = oldVelocity -- restored
                return result
            end)
        else
            restore(ogHit)
        end
    end,
})

local ogFire = function() end
combat:CreateToggle({
    Name = "Fast Firerate",
    CurrentValue = false,
    Flag = "ffr",
    Callback = function(v)
        if v then
            ogFire = hookfunction(rmod.Fire, function(self, ...)
                local oldRate = self.FireRate
                self.FireRate = 1e2
                local result = ogFire(self, ...)
                --self.FireRate = oldRate -- restored
                return result
            end)
        else
            restore(ogFire)
        end
    end,
})

combat:CreateToggle({
    Name = "No Shoot Sound",
    CurrentValue = false,
    Flag = "nss",
    Callback = function(v)
        if rmod and rmod.LoadedSounds then
            for _, snd in ipairs(rmod.LoadedSounds:GetDescendants()) do
                print(snd)
                if snd:IsA("Sound") and string.find(string.lower(snd.Name), "fire") then
                    snd.Volume = v and 0 or 1
                end
            end
        end
    end,
})

combat:CreateLabel("Hitbox")

local size = 2; local expanded = false; freeze = false
combat:CreateToggle({
    Name = "Expand",
    CurrentValue = false,
    Flag = "he",
    Callback = function(v)
        expanded = v
        for _, item in ipairs(workspace["Animals"]:GetChildren()) do
            local root = item["Organs"]["Heart"] or item["RootPart"]
            root.CanCollide = freeze
            if expanded then
                root.Size = root.Size + Vector3.new(size, size, size)
            else
                root.Size = root.Size - Vector3.new(size, size, size)
            end
        end
    end,
})

combat:CreateSlider({
    Name = "Size",
    Range = {1, 15},
    Increment = 1,
    Suffix = "",
    CurrentValue = 2,
    Flag = "hs",
    Callback = function(v)
        size = v
    end,
})

combat:CreateToggle({
    Name = "Freeze Animals",
    CurrentValue = false,
    Flag = "fa",
    Callback = function(v)
        freeze = v
    end,
})

local visuals = Window:CreateTab("Visuals")
visuals:CreateLabel("Animals")

local ESP = {Cache = {}}

local function newText(color)
    local t = Drawing.new("Text")
    t.Visible = false
    t.Center = true
    t.Outline = false
    --t.Font = Drawing.Fonts.UI
    t.Size = 13
    t.Color = color or Color3.fromRGB(255, 255, 255)
    return t
end

local function getItem(obj, color)
    if not ESP.Cache[obj] then
        ESP.Cache[obj] = newText(color)
    end
    return ESP.Cache[obj]
end

local function removeItem(obj)
    local esp = ESP.Cache[obj]
    if esp then
        esp:Destroy()
        ESP.Cache[obj] = nil
    end
end

local function refresh(livingEnabled, deadEnabled)
    for obj, _ in pairs(ESP.Cache) do
        removeItem(obj)
    end

    if livingEnabled then
        for _, a in ipairs(workspace.Animals:GetChildren()) do
            getItem(a, Color3.fromRGB(255, 255, 255))
        end
    end

    if deadEnabled then
        for _, a in ipairs(workspace.DeadAnimals:GetChildren()) do
            getItem(a, Color3.fromRGB(255, 0, 0))
        end
    end
end

runs.RenderStepped:Connect(function()
    local cpos = cam.CFrame.Position
    for obj, text in pairs(ESP.Cache) do
        if not obj.Parent then
            removeItem(obj)
            continue
        end

        local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if not root then
            text.Visible = false
            continue
        end

        local pos, onscreen = cam:WorldToViewportPoint(root.Position)
        if not onscreen then
            text.Visible = false
            continue
        end

        local dist = (cpos - root.Position).Magnitude
        text.Position = Vector2.new(pos.X, pos.Y)
        text.Text = string.format("%s | %.0fm", obj:GetAttribute("DisplayName") or obj.Name, dist)
        text.Visible = true
    end
end)

local living, dead = false, false
visuals:CreateToggle({
    Name = "Living Esp",
    CurrentValue = false,
    Flag = "le",
    Callback = function(v)
        living = v
        refresh(living, dead)
    end,
})

visuals:CreateToggle({
    Name = "Dead Esp",
    CurrentValue = false,
    Flag = "de",
    Callback = function(v)
        dead = v
        refresh(living, dead)
    end,
})

-- make organ esp

task.spawn(function()
    while task.wait(5) do
        refresh(living, dead)
    end
end)

--[[
    visuals:CreateLabel("Footprints")

    local footprints = {}
    visuals:CreateToggle({
        Name = "Footprints",
        CurrentValue = false,
        Flag = "fp",
        Callback = function()
            for _, item in ipairs(workspace.Footprints:GetChildren()) do
                table.insert(footprints, item)
            end
            -- im not to sure but theirs an 'id' attr you can use to differincate animals
        end,
    })
--]]

local movement = Window:CreateTab("Movement")

movement:CreateLabel("Movement")

local flying, grav = false, workspace.Gravity
movement:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Flag = "fly",
	Callback = function(v)
		flying = v
	end,
})

local flySpeed = 50
movement:CreateSlider({
	Name = "Fly Speed",
	Range = {0,200},
	Increment = 1,
	Suffix = " s",
	CurrentValue = flySpeed,
	Flag = "flySpeed",
	Callback = function(v)
		flySpeed = v
	end,
})

local walkfaster = false
movement:CreateToggle({
	Name = "Walk Faster",
	CurrentValue = false,
	Flag = "wf",
	Callback = function(v)
		walkfaster = v
	end,
})

local walkSpeed = 16
movement:CreateSlider({
	Name = "Walk Speed",
	Range = {0,200},
	Increment = 1,
	Suffix = " s",
	CurrentValue = walkSpeed,
	Flag = "walkSpeed",
	Callback = function(v)
		walkSpeed = v
	end,
})

local mkeys = {W=true, A=true, S=true, D=true, Space=true, LeftShift=true}; local keys = {}
uis.InputBegan:Connect(function(i,gpe)
	if gpe then return end
	if mkeys[i.KeyCode.Name] then keys[i.KeyCode.Name]=true end
end)
uis.InputEnded:Connect(function(i)
	if mkeys[i.KeyCode.Name] then keys[i.KeyCode.Name]=nil end
end)

runs.RenderStepped:Connect(function(dt)
	local dir = Vector3.new()
	if keys.W then dir = dir + Vector3.new(0,0,1) end -- flip Z
	if keys.S then dir = dir + Vector3.new(0,0,-1) end -- flip Z
	if keys.A then dir = dir + Vector3.new(-1,0,0) end
	if keys.D then dir = dir + Vector3.new(1,0,0) end
	if keys.Space then dir = dir + Vector3.new(0,1,0) end
	if keys.LeftShift then dir = dir + Vector3.new(0,-1,0) end

	if dir.Magnitude>0 then
		dir = dir.Unit
		local cam = workspace.CurrentCamera
		if flying then
            workspace.Gravity = 12

			local move = (cam.CFrame.LookVector*dir.Z + cam.CFrame.RightVector*dir.X + Vector3.new(0,dir.Y,0))*flySpeed*dt
			hrp.CFrame = hrp.CFrame + move
		elseif walkfaster then
			local forward = Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z).Unit
			local right = Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z).Unit
			local move = (forward*dir.Z + right*dir.X)*walkSpeed*dt
			hrp.CFrame = hrp.CFrame + move
		elseif not flying then
            workspace.Gravity = grav
        end
	end
end)

--[[
    local sspeed, ssspeed = false, 15
    movement:CreateToggle({
        Name = "Sprint Speed",
        CurrentValue = false,
        Flag = "sst",
        Callback = function(v)
            sspeed = v
            games.BaseRunSpeed = ssspeed
        end,
    })

    movement:CreateSlider({
        Name = "Sprint Speed",
        Range = {0, 120},
        Increment = 1,
        Suffix = " s",
        CurrentValue = 15,
        Flag = "ss",
        Callback = function(v)
            ssspeed = v
        end,
    })
--]]

if gname ~= "Thabisa Valley" then
    movement:CreateLabel("Teleports")

    local listed = {}; local sstore
    for _, folder in ipairs(workspace["Stores"]:GetChildren()) do
        for _, desc in ipairs(folder:GetDescendants()) do
            if desc:IsA("Part") and (desc.Name == "TeleportName" or desc.Name == "Interior Wall") or desc.Name == "Part" then
                table.insert(listed, {Name = folder.Name, Part = desc})
                break
            end
        end
    end

    sstore = listed[1].Part

    local options = {}
    for _, entry in ipairs(listed) do
        table.insert(options, entry.Name)
    end

    movement:CreateDropdown({
        Name = "Selected",
        Options = options,
        CurrentOption = listed[1].Name,
        MultipleOptions = false,
        Flag = "ss",
        Callback = function(v)
            if listed[v] and listed[v].Part then
                sstore = listed[v].Part
            end
        end,
    })

    movement:CreateButton({
        Name = "Teleport to store",
        Callback = function()
            if sstore and sstore.CFrame then
                hrp.CFrame = sstore.CFrame
            end
        end,
    })

    movement:CreateDivider()

    movement:CreateButton({
        Name = "Teleport to lodge",
        Callback = function()
            for _, item in ipairs(workspace["Lodges"]:GetChildren()) do
                if item:GetAttribute("Owner") == players["LocalPlayer"].UserId then
                    hrp.CFrame = item["BoundingBox"].CFrame
                end
            end
        end,
    })

    local sanimal; local animals, animalMap = {}, {}; local curBest = nil;
    local function score_animal(animal)
        local age = animal:GetAttribute("Age") or 0;
        local sex = animal:GetAttribute("Sex") or "Unknown";
        local variant = animal:GetAttribute("Variant") or "Default";
        local weight = animal:GetAttribute("Weight") or 0;

        local score = 0;
        score = score + age * 2;
        if sex == "Male" then score = score + 5; end;
        if variant ~= "Default" then score = score + 60; end;
        score = score + weight;
        return score;
    end;

    local function get_animals(best)
        animals = {}; animalMap = {}; curBest = nil;

        for _, item in ipairs(workspace["Animals"]:GetChildren()) do
            local root = item:FindFirstChild("RootPart");
            if root then
                animals[#animals + 1] = item.Name;
                animalMap[item.Name] = item;

                if best then
                    local s = score_animal(item);
                    if not curBest or s > score_animal(curBest) then
                        curBest = item;
                    end;
                end;
            end;
        end;

        sanimal = curBest;
    end;

    get_animals(); -- populate

    local animal_drop = movement:CreateDropdown({
        Name = "Selected";
        Options = animals;
        CurrentOption = {animals[1]};
        MultipleOptions = false;
        Flag = "sa";
        Callback = function(v)
            local name = v[1];
            sanimal = animalMap[name];
        end;
    });

    movement:CreateButton({
        Name = "Teleport to animal";
        Callback = function()
            get_animals();
            animal_drop:Set(animals);
            if sanimal and sanimal:FindFirstChild("RootPart") then
                hrp.CFrame = sanimal.RootPart.CFrame;
            end;
        end;
    });

    movement:CreateButton({
        Name = "Teleport to best animal";
        Callback = function()
            get_animals(true);
            if sanimal and sanimal:FindFirstChild("RootPart") then
                hrp.CFrame = sanimal.RootPart.CFrame;
            end;
        end;
    });

    movement:CreateDivider()

    local sdefault; local defaults, defaulttMap = {}, {}
    for _, item in ipairs(workspace["ReplicatedInstances"]:GetChildren()) do
        table.insert(defaults, item.Name)
        defaulttMap[item.Name] = item
    end

    movement:CreateDropdown({
        Name = "Selected",
        Options = defaults,
        CurrentOption = {defaults[1]},
        MultipleOptions = false,
        Flag = "sa",
        Callback = function(v)
            local name = v[1]
            sdefault = defaulttMap[name]
        end,
    })

    movement:CreateButton({
        Name = "Teleport to default",
        Callback = function()
            hrp.CFrame = sdefault.CFrame
        end,
    })
end

local misc = Window:CreateTab("Misc")

misc:CreateLabel("Misc")

local games = require(rep["GameSettings"])

local inchav = false; local oldharv
misc:CreateToggle({
	Name = "Increased Harvest",
	CurrentValue = false,
	Flag = "ih",
	Callback = function(v)
        local inchav = v
        if inchav then
            oldFunc = hookfunction(game.GetHarvestValue, function(p29)
                return p29 * 100
            end)
        else
            if isfunctionhooked(oldharv) then
                restorefunction(oldhav)
            end
        end
	end,
})

--[[
    misc:CreateButton({
        Name = "Spawn Car",
        Callback = function()
            local new = rep.Vehicles.ATV:Clone()
            new.Parent = workspace["Vehicles"]; new.Name = "ATV"; new:SetAttribute("Id", ""); new:SetAttribute("Owner", players.LocalPlayer.UserId)
            for _, item in ipairs(new["Wheels"]:GetChildren()) do
                item.Anchored = false
            end

            new:PivotTo(hrp.CFrame * CFrame.new(0, 0, -1))
        end,
    })
--]]

misc:CreateLabel("Lighting")

local light; local lv = false; local conl; local oldl = lighting.ClockTime
misc:CreateToggle({
	Name = "Lighting",
	CurrentValue = false,
	Flag = "fb",
	Callback = function(v)
        lv = v; oldl = lighting.ClockTime;
        conl = lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
            lighting.ClockTime = light
        end)
        if not v then lighting.ClockTime = oldl; conl = nil end
	end,
})

misc:CreateSlider({
    Name = "Lighting Value";
    Range = {0, 24};
    Increment = 1;
    Suffix = " s";
    CurrentValue = oldl;
    Flag = "ss";
    Callback = function(v)
        light = v
    end;
})

misc:CreateLabel("Audio")

local sounds, ogVolumes = {}, {}

for _, item in ipairs(rep:GetDescendants()) do
    if item:IsA("Sound") and not table.find(sounds, item) and not item.Name:find("_") then
        table.insert(sounds, item)
        ogVolumes[item] = item.Volume
    end
end

local soundNames = {}
for _, sound in ipairs(sounds) do
    table.insert(soundNames, sound.Name)
end

local function getSound(name)
    for _, sound in ipairs(sounds) do
        if sound.Name == name then
            return sound
        end
    end
end

local applyVolume = true; local svolume = 1; local sselected
misc:CreateDropdown({
    Name = "Sounds",
    Options = soundNames,
    CurrentOption = soundNames[1],
    MultipleOptions = false,
    Flag = "s",
    Callback = function(selectedName)
        sselected = getSound(selectedName)
        if sselected then
            sselected.Volume = applyVolume and svolume or ogVolumes[sselected]
        end
    end,
})

misc:CreateSlider({
    Name = "Volume";
    Range = {0, 15};
    Increment = 0.1;
    Suffix = " s";
    CurrentValue = 1;
    Flag = "ss";
    Callback = function(v)
        svolume = v
        if applyVolume and sselected then
            sselected.Volume = svolume
        end
    end;
})

misc:CreateToggle({
    Name = "Change Volume",
    CurrentValue = false,
    Flag = "svt",
    Callback = function(v)
        applyVolume = v
        if sselected then
            sselected.Volume = applyVolume and svolume or ogVolumes[sselected]
        end
    end,
})

misc:CreateLabel("Trees")

local wind
misc:CreateToggle({
    Name = "Disable Wind",
    CurrentValue = false,
    Flag = "dw",
    Callback = function(v)
        wind = task.spawn(function()
            for _, tree in ipairs(workspace.Trees:GetChildren()) do
                if tree:FindFirstChildWhichIsA("MeshPart") and tree:GetAttribute("WindPower") then
                    tree:SetAttribute("WindPower", v and 0 or 0.15)
                end
            end
        end)
        if not v then task.cancel(wind) end
    end,
})

local unrender
misc:CreateDropdown({
	Name = "Options",
	Options = {"Leaf", "Trunk"},
	CurrentOption = {"Leaf"},
	MultipleOptions = true,
	Flag = "tm",
	Callback = function(v) unrender = v end,
})

misc:CreateToggle({
	Name = "Unrender",
	CurrentValue = false,
	Flag = "tu",
	Callback = function(v)
		local p = "Meshes/Dogwood Trees 01_"

		for _, item in ipairs(workspace.Trees:GetChildren()) do
			for _, name in ipairs(unrender) do
				local obj = item:FindFirstChild(p .. name)
                if obj then
                    obj.Transparency = v and 1 or 0
                    obj.CanCollide = v and false or true
                end
			end
		end
	end,
})
