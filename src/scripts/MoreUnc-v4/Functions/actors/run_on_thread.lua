local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
--local globals = Knit.require(`{shared.script}/Modules`, "globals")

local gettenv = getfunction("gettenv")

local function validate_thread(thread: thread) -- Actor only
    local env = gettenv(thread)
    if not env then
        return false
    end
    local thread_script = env.script
    if not thread_script then
        return false
    end
    if thread_script:IsA("Actor") then
        return true
    end

    return false
end

return function(thread: thread, script: string, ...)
    if not validate_thread(thread) then
        return
    end

    local func, err = loadstring(script)
    if not func then
        error(err, 2)
    end
    setfenv(func, getgenv())
    local _execution = task.spawn(function(...)
        coroutine.resume(thread, func, ...)
    end, ...)
end