local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "init").getfunction

local setinfo = getfunction("setinfo", "debug")

return function(target: function | number, newname: string)
    --local func = type(target) == "function" and target or debug.info(target, "n") -- the calling function
    if type(target) == "function" then
        setinfo(target, {
            name = newname -- I hope this doesnt overwrite any other info
        })
    else
        -- fuck you
    end
end