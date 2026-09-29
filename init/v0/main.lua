local Script = shared.script

local Success, Error = pcall(function()
    task.spawn(function()
        loadstring(game:HttpGet(string.format("https://raw.githubusercontent.com/matpatz/Roblox/refs/heads/main/src/%s/main.lua", Script)))()
    end)
end); if not Success then
    warn(Error)
end
