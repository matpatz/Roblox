The domains: https://roblox-alpha-murex.vercel.app and https://www.voltex.website are the same as this folder
    so Modules are located at src/Modules, no webfetch required

if I didnt tell you to do something dont do it, no stupid ui

potassium workspace: C:\Users\$env:USERPROFILE\AppData\Local\Potassium\workspace
    instead of reading the workspace contents with some commandprompt command just use execute_script: listfiles("")

when modying GetTargets dont forget GetClosest (of the Aimbot Module) filters hp and such already

the chance Aimbot.GetClosest is the issue is almost zero, I have likely checked if a target is actually found

avoid:
```lua
local a = request({
    Url = "https://example.com",
    Method = "GET"
})
if not a or type(a.Body) ~= "string" then
    error("bad lil body")
end
``` -- because body will never not exist/not be a string if a does not exist

the MCP may shutdown any time so it would be preferable to write any useful files locally (in the Scripts folder of whatever game)