local Knit = {}

Knit.require = function(script, module)
    return require(script:WaitForChild(module))
end

return Knit