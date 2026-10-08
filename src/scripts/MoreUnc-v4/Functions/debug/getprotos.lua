type func = typeof(function() end)

return function(func: func | number): {func} -- Impossible
    return {}
end