local Knit = shared.Knit
local init = Knit.require(`{shared.script}/Functions`, "init")
    
local base64encode = init.getfunction("base64encode", "crypt")

local RNG = Random.new(workspace:GetServerTimeNow())

return function(length)
    local Generated = table.create(length)
    for i = 1, length do
        Generated[i] = string.char(RNG:NextInteger(0, 255))
    end
    return base64encode(table.concat(Generated))
end