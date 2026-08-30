local functions = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Desert-Storm/functions.lua"))()
--[[
return {
	SpectateFunction = SpectateFunction,
	getArmorSpeedReduction = getArmorSpeedReduction,
	AnticheatThread = AnticheatThread
	MessageOut = MessageOut
}
--]]

local SpectateFunction; SpectateFunction = hoookfunction(functions.SpectateFunction, function(...)
    print("The user is being spectated.")
    return {...}
end)

if NoArmor then
    local getArmorSpeedReduction; getArmorSpeedReduction = hookfunction(functions.getArmorSpeedReduction, function()
        return 0
    end)
end

-- only contains cloneref detections
if NoCloneref then
    task.cancel(funcitons.AnticheatThread)
end

if NoFootStpes then
    local FootStepHeartbeat; FootStepHeartbeat = hookfunction(functions.FootStepHeartbeat, function()
        
    end)
end -- debug.setconstant(functions.FootStepHeartbeat, 1, "1000") : uf HP <= 1000 then return end

if MessageOut then
    local MessageOut; MessageOut = hookfunction(functions.MessageOut, function(p1, p2)
        -- FUCKKKK you
    end)
end