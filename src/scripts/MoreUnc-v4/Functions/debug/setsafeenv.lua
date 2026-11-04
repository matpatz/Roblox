type func = typeof(function() end)

local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local setrawmetatable = getfunction("setrawmetatable", "metatable")
local hookfunction = getfunction("hookfunction", "closures")
local restorefunction = getfunction("restorefunction", "closures")

local function lock(object)
    local object_type = type(object)

    if object_type == "table" then
        setrawmetatable(object, {
            __newindex = function(self, key, value)
                globals.set("safeenv", false)
                return rawset(self, key, value)
            end,
        })
    elseif object_type == "function" then
        -- a locked function swallows the call, writes are what safeenv guards
        hookfunction(object, function(...)
            return
        end)
    end
end

local function unlock(object)
    if type(object) == "table" then
        setrawmetatable(object, {})
    elseif type(object) == "function" then
        local hooks = globals.get("hooks")

        if hooks[object] then
            restorefunction(object)
        end
    end
end

return function(object: func | table | thread?, safe: boolean?)
    object = object or getfenv()
    globals.set("safeenv", safe == true)

    if safe == true then
        lock(object)
    else
        unlock(object)
    end
end

-- any overwritten object(getfenv) will break safeenv. Not sure why setsafeenv even exists but ya