local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local shakeEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ShakeCam")

local function shakeCamera(intensity)
	local cam = workspace.CurrentCamera
	if not cam then return end

	local originalCFrame = cam.CFrame
	local shakes = 8
	for i = 1, shakes do
		local offset = Vector3.new(
			math.random(-intensity * 100, intensity * 100) / 100,
			math.random(-intensity * 100, intensity * 100) / 100,
			math.random(-intensity * 100, intensity * 100) / 100
		)
		cam.CFrame = originalCFrame * CFrame.new(offset)
		task.wait(0.03)
	end
	cam.CFrame = originalCFrame
end

shakeEvent.OnClientEvent:Connect(shakeCamera)
