local rep = game:GetService("ReplicatedStorage"); local l = 0
local function g()
    rep.GiveLevel:FireServer()
end

while task.wait() do
    task.spawn(function()
        for i = 1, 20 do
            l += 1
            task.delay(l, g)
            rep.GiveMoney:FireServer(i * math.random(2, 3))
        end
        l = l
    end)
end
