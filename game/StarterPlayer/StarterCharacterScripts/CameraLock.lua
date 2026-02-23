local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

camera.CameraType = Enum.CameraType.Scriptable

local cameraYOffset = 0.5
local cameraZOffset = 15
local smoothness = 0.3

game:GetService("RunService").RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root then
		local desiredCameraPos = Vector3.new(
			root.Position.X,
			root.Position.Y + cameraYOffset,
			root.Position.Z + cameraZOffset
		)

		camera.CFrame = camera.CFrame:Lerp(
			CFrame.new(desiredCameraPos, root.Position),
			smoothness
		)
	end
end)

local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

humanoid.JumpPower = 50
humanoid.UseJumpPower = true

local moveForward = false

local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
controls:Disable()

local function updateMovement()
	local moveDirection = Vector3.zero

	if UIS:IsKeyDown(Enum.KeyCode.A) then
		moveDirection += Vector3.new(-1, 0, 0)
	end
	if UIS:IsKeyDown(Enum.KeyCode.D) then
		moveDirection += Vector3.new(1, 0, 0)
	end

	humanoid:Move(moveDirection, true)
end

game:GetService("RunService").RenderStepped:Connect(updateMovement)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.W then
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)
