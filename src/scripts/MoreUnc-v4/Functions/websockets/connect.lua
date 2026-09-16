local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")

local Messages = instances.new("BindableEvent")
local Closed = instances.new("BindableEvent")

return function(url: string)
    local Warned   = false
    local IsClosed = false

    return {
        OnMessage = Messages.Event,
        OnClose = Closed.Event,

        Send = function(_, Message)
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