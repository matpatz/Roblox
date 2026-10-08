type func = typeof(function() end)

return function (func: func | number): { any }
    return {}
end