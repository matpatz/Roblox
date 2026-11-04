local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")

return function(url: string)
    -- per connection, otherwise every socket fires everyone elses handlers
    local Messages = instances.new("BindableEvent", true)
    local Closed = instances.new("BindableEvent", true)

    local Warned = false
    local IsClosed = false

    return {
        OnMessage = Messages.Event,
        OnClose = Closed.Event,

        Send = function(_, Message)
            if IsClosed then
                return
            end

            if Warned then
                return
            end

            Warned = true
            warn("WebSocket is not implemented, message was not sent: " .. Message)
        end,

        Close = function(_)
            if IsClosed then return end

            IsClosed = true
            Closed:Fire()

            task.delay(0, function()
                Messages:Destroy()
                Closed:Destroy()
            end)
        end,
    }
end

--[[
local ws = WebSocket.connect("wss://echo.websocket.org")

ws.OnMessage:Connect(function(message)
    print("received:", message)
end)

ws.OnClose:Connect(function()
    print("closed")
end)

ws:Send("Hello, WebSocket!")
ws:Close()
]]