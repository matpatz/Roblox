-- credits: https://github.com/strawbberrys/getnamecallmethod/tree/main

local overlapParams = OverlapParams.new()
local color3 = Color3.new()

-- a namecall is dispatched by a C handler, so erroring one leaks both pieces we want:
-- the handler itself (stack level 2 of the error handler) and the method name (in the
-- "X is not a valid member of Y" message)
local function extract_handler()
    return debug.info(2, "f")
end

local function handler_for(object)
    local ok, handler = xpcall(function()
        (object :: any):__namecall()
    end, extract_handler)

    if ok then
        return nil -- no error means no handler to reuse, try the next datatype
    end

    return handler
end

local handlers = {
    handler_for(overlapParams),
    handler_for(color3),
}

local function method_from(errorMessage: string): string?
    return errorMessage:match("^(.+) is not a valid member of %w+$")
end

return function(): string
    for _, handler in next, handlers do
        if handler then
            local ok, errorMessage = pcall(handler)
            local method = if ok or type(errorMessage) ~= "string" then nil else method_from(errorMessage)

            if method then
                return method
            end
        end
    end

    return ""
end

--[[
hookmetamethod(game, "__namecall", function(self, ...)
    print(getnamecallmethod()) -- FireServer, InvokeServer, FindFirstChild, ...
    return old(self, ...)
end)
]]