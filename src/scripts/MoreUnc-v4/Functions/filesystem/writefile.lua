local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local files = globals.get("files")

return function(path: string, data: string)
    files[path] = data
end
