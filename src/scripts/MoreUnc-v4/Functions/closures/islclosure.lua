return function(func: function)
    return debug.info(func, "s") ~= "[C]"
end