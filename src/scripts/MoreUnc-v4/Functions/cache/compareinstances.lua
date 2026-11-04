-- cloneref proxies hide the real instance behind a wrapper, so unwrap before
-- comparing or every clone reports itself as a different object
local function unwrap(object)
    if type(object) == "table" then
        return rawget(object, "__raw") or object
    end

    return object
end

return function(a: Instance, b: Instance): boolean
    return unwrap(a) == unwrap(b)
end