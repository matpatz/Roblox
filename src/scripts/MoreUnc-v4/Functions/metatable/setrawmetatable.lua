return function(target: table, metatable: table) -- if the metatable is not locked then yay, but otherwise it will fail silently
    local ok, err = pcall(function()
        setmetatable(target, metatable)
    end)

    if not ok then
        error(err)
    end
end