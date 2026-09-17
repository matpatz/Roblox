type func = typeof(function() end)

return function(func: func)
    return debug.info(func, "s") == "[C]"
end