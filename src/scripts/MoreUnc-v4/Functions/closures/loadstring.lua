type func = typeof(function() end)

return function(source: string, chunkname: string?): (func?, string?)
    return loadstring(source, chunkname) -- loadstring exists bro dont even lie
end