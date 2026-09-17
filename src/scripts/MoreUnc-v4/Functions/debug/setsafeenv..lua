type func = typeof(function() end)

local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local setrawmetatable = getfunction("setrawmetatable")

local function lock(object)
    setrawmetatable(object, { -- TODO: Verify functionality. Metatables are scary, also not sure if their is a protected metatable or not, its probably executor dependent
        --__metatable = "Protected",
        __newindex = function(_, __,)
            globals.set("safeenv", false)
            return rawset(_, __,)
        end
    })
end

local function unlock()
    setrawmetatable(object, {})
end

return function(func: func | table | thread | boolean, safe: boolean?)
    if not object then
        object = getfenv()
    end
    globals.set("safeenv", safe)

    if type(func) ~= "table" then
        return -- amazing work team
    end

    if safe then lock() else unlock()
end

-- any overwritten object(getfenv) will break safeenv. Not sure why setsafeenv even exists but ya