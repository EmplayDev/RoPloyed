local Player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local character = Player.Character or Player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

humanoid.AutoRotate = false

local moveLeft = false
local moveRight = false
local moveSpeed = 16

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		moveLeft = true
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		moveRight = true
	end
end)

UIS.InputEnded:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		moveLeft = false
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		moveRight = false
	end
end)

RunService.RenderStepped:Connect(function()
	local dir = 0
	if moveLeft then dir = dir - 1 end
	if moveRight then dir = dir + 1 end

	humanoid:Move(Vector3.new(dir, 0, 0), true)

	if dir ~= 0 then
		local angle = dir < 0 and math.rad(90) or math.rad(-90)
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, angle, 0)
	end
end)
