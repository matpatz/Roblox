local git = {}

-- @param1 shared.script ("scripts/Moreunc-v4")
-- @param2 module name ("Functions")
function git.clone(script: string, module: string)
    return listfiles(script .. "/" .. module)
end

return git