-- concept
-- ill work out logisitcs (like basically everything here is completely non-functional) later

local function IsPlayer(object: Model)
    return object:IsA("Player") -- I think this is actually valid    
end

local function ApplyMetetable(object: Model)
    if not IsPlayer(object) then
        return
    end

    local a = {} setmetatable(a, { --  i think it is possible to set metatbale a instance, or at least there is some other way to do it 
        __index = function(a,b)
            if inrange(object.Position) then
                -- add target in closest
            end
            return rawget(a,b)
        end
    })

    object = a
end

for i, v in next, workspace:GetChildren() do
    ApplyMetetable(v)
end

workspace.ChildAdded:Connect(object)
    ApplyMetetable(object)
end