-- @param1 the object to touch that the touchinterest is connected to
-- @param2 a player object (Hrp, Head, etc)
-- @param3 a boolean to or to not touch
return function(part: Instance, target: Instance, touch: boolean)
    if touch then
        firesignal(target.Touched, part)
    else
        firesignal(target.TouchEnded,part)
    end
end