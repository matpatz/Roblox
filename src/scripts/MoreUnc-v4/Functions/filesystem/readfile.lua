local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local files = globals.get("files")

return function(path: string): string
    local data = files[path]

    if not data then
        error(`file does not exist: {path}`, 2)
    end

    return data
end
