local utils = {}

local Knit = shared.Knit
local scriptmanager = Knit.scriptmanager

utils.GetClosest = function()
    return nil
end
    
scriptmanager.set("utils", utils)

return utils