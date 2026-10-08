local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local folders = globals.get("folders")

return function(path: string)
    folders[path] = nil
end
