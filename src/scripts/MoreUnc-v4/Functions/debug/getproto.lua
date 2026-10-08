type func = typeof(function() end)

return function(func: func | number, index: number, active: boolean?): func | {func} -- Impossible
    --if not debug.isvalidlevel(index) then
    --    return
    --end
    return nil
end