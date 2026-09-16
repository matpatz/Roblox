AddFunction("firetouchinterest", function(Part, Target, Touch)
    if not (typeof(Part) == "Instance" and Part:IsA("BasePart")) then error("expected BasePart at argument #1, got " .. typeof(Part), 2) end
    if not (typeof(Target) == "Instance" and Target:IsA("BasePart")) then error("expected BasePart at argument #2, got " .. typeof(Target), 2) end
    if Touch ~= nil and type(Touch) ~= "boolean" then error("expected boolean or nil at argument #3, got " .. type(Touch), 2) end
    if Touch == false then
        firesignal(Target.TouchEnded, Part)
    else
        firesignal(Target.Touched, Part)
    end
end)


-- @param1 the object to touch that the touchinterest is connected to
-- @param2 a player object (Hrp, Head, etc)
-- 
return function(part, target, touch)
end