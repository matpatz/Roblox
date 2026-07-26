local rep = game:GetService("ReplicatedStorage")

local answersm = require(rep.Common.Modules.Databases.Questions)

local function longest(question)
    for _, q in pairs(answersm) do
        if string.lower(q.value) == string.lower(question) then
            local longest
            for _, ans in ipairs(q.answers or {}) do
                if not longest or #ans.value > #longest then
                    longest = ans.value
                end
            end
            return longest
        end
    end
end

local lp = game:GetService("Players").LocalPlayer
local question = lp:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Question").Bg.QuestionTxt

local function solve()
    if question.Visible then
        local qText = question.Text
        local answer = longest(qText)

        if answer then
            task.delay(getgenv().delay or 10, function()
                rep.Common.Library.Network.RemoteFunction:InvokeServer("S_System_NewSubmitAnswer", { answer })
                print("Answered:", qText, "->", answer)
            end)
        else
            warn("No answer found for:", qText)
        end
    end
end

question:GetPropertyChangedSignal("Text"):Connect(solve)
