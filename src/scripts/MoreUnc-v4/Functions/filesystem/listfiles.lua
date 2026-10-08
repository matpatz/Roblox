local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local files = globals.get("files")
local folders = globals.get("folders")

return function(path: string): { string }
    local prefix = path:gsub("[\\/]+$", "") .. "/"
    local listed = {}

    for name in next, files do
        if name:sub(1, #prefix) == prefix then
            listed[#listed + 1] = name
        end
    end

    for name in next, folders do
        if name:sub(1, #prefix) == prefix then
            listed[#listed + 1] = name
        end
    end

    return listed
end
