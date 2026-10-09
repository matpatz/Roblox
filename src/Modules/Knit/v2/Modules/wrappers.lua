local Knit = shared.Knit

local wrappers = {}

setmetatable(wrappers, {
    __index = function(_, index)
        local type = index.type
        local name = index.name

        local func = getgenv()[name]
        if func then
            return func
        end

        func = Knit.require(`scripts/MoreUnc-v4/Functions/{type}`, name)
        return func
    end
})

--[[
local get = wrappers[{
    type = "instance",
    name = "gethui"
}]
print(get)
]]