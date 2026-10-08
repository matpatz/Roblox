type func = typeof(function() end)

local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local setrawmetatable = getfunction("setrawmetatable", "metatable")
local hookfunction = getfunction("hookfunction", "closures")
local clonefunction = getfunction("clonefunction", "closures")

local hooks = {}

local function lock(object)
    local object_type = type(object)
    if object_type == "table" then
        setrawmetatable(object, { -- TODO: Verify functionality. Metatables are scary, also not sure if their is a protected metatable or not, its probably executor dependent
            --__metatable = "Protected",
            __newindex = function(_, __, ___)
                globals.set("safeenv", false)
                return rawset(_, __, ___)
            end
        })
    elseif object_type == "function" then
        local old = clonefunction(object)
        old = hookfunction(hookfunction, function(func, newfunc)
            if func == object then
                newfunc = function(...)
                    return
                end
            end
            return old(func, newfunc)
        end)
    end
end

local function unlock()
    setrawmetatable(object, {})
end

return function(func: func | table | thread | boolean, safe: boolean?)
    if not object then
        object = getfenv()
    end
    globals.set("safeenv", safe)

    if safe then lock(func) else unlock() end
end

-- any overwritten object(getfenv) will break safeenv. Not sure why setsafeenv even exists but ya