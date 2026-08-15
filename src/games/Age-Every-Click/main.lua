-- https://rscripts.net/script/auto-max-age-saUF

getgenv().AUTO_AGE = true

const ReplicatedStorage = game:GetService'ReplicatedStorage'
const SpinRequest = ReplicatedStorage:WaitForChild('SpinRequest', 5)
const SpinWheelEvents = ReplicatedStorage:WaitForChild'SpinWheelEvents':WaitForChild('Age500Event', 5)

task.spawn(function()
	while task.wait() do
		if not getgenv().AUTO_AGE then
			continue
		end

        SpinRequest:FireServer()
        SpinWheelEvents:FireServer()
	end
end)
