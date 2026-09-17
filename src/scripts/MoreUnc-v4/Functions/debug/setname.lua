type func = typeof(function() end)

local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local setinfo = getfunction("setinfo", "debug")

return function(target: func | number, newname: string)
    --local func = type(target) == "function" and target or debug.info(target, "n") -- the calling function
    if type(target) == "function" then
        setinfo(target, {
            name = newname -- I hope this doesnt overwrite any other info
        })
    else
        -- fuck you
    end
end