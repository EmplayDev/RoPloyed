local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MedallionController = require(ReplicatedStorage:WaitForChild("MedallionController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("ScreenGui")

local dialogueHolder = gui:WaitForChild("DialogueHolder")
local viewport = dialogueHolder:WaitForChild("Character")
local dialogueFrame = dialogueHolder:WaitForChild("Dialogue")

local medallionScreen = gui:WaitForChild("MedallionScreen")
local jobHolder = medallionScreen:WaitForChild("JobButtonHolder")

local baseDialoguePos = dialogueFrame.Position
local FLOAT_STRENGTH = 12
local FOLLOW_SPEED = 0.15

local nameLabel = dialogueFrame:WaitForChild("Name")
local textLabel = dialogueFrame:WaitForChild("TextField")
local continueArrow = dialogueFrame:WaitForChild("ContinueArrow")

local choicesFrame = dialogueHolder.Choices
local choicesHolder = choicesFrame:WaitForChild("ChoicesHolder")
local choiceTemplate = choicesHolder:WaitForChild("ChoiceTemplate")

local waitingForClick = false
local finalAcknowledged = false

dialogueHolder.Visible = false
continueArrow.Visible = false
choicesFrame.Visible = false

local DEFAULT_WALK = 16
local DEFAULT_JUMP = 50

local typing = false
local canContinue = false
local inputConnection

local currentDialogue
local currentNode
local talkSound

local lineIndex = 0

local camera = workspace.CurrentCamera
local originalCF = camera.CFrame

local playerViewport = dialogueHolder:WaitForChild("PlayerCharacter")
playerViewport.Visible = false

local function zoomIn()
	TweenService:Create(
		camera,
		TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ FieldOfView = 55 }
	):Play()
end

local function zoomOut()
	TweenService:Create(
		camera,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ FieldOfView = 70 }
	):Play()
end

local function setupPlayerViewport()
	playerViewport.Visible = true
	playerViewport.ZIndex = 10

	local oldCam = playerViewport.CurrentCamera
	if oldCam then
		oldCam:Destroy()
	end

	for _, child in ipairs(playerViewport:GetChildren()) do
		if child:IsA("Model") then
			child:Destroy()
		end
	end

	local cam = Instance.new("Camera")
	cam.Parent = playerViewport
	playerViewport.CurrentCamera = cam

	local char = player.Character or player.CharacterAdded:Wait()
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
		or char:WaitForChild("HumanoidRootPart", 2)

	if not hrp then
		warn("Character not ready for viewport clone")
		return
	end

	local oldArchivable = char.Archivable
	char.Archivable = true

	local clone = char:Clone()

	char.Archivable = oldArchivable

	if not clone then
		warn("Character clone failed")
		return
	end

	clone.Parent = playerViewport

	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end

	clone.PrimaryPart = clone:FindFirstChild("HumanoidRootPart")
	if not clone.PrimaryPart then return end
	
	clone:PivotTo(
		clone.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(180), 0)
	)

	cam.CFrame = CFrame.lookAt(
		clone.PrimaryPart.Position + Vector3.new(0, 1.5, 4),
		clone.PrimaryPart.Position + Vector3.new(0, 1.2, 0)
	)
end

local function typeText(text)
	typing = true
	waitingForClick = false
	continueArrow.Visible = false
	textLabel.Text = ""

	text = text:gsub("{PLAYER}", player.Name)

	for i = 1, #text do
		textLabel.Text = text:sub(1, i)

		if talkSound then
			local s = talkSound:Clone()
			s.Parent = textLabel
			s:Play()
			game:GetService("Debris"):AddItem(s, 0.5)
		end

		task.wait(0.03)
	end

	typing = false
	waitingForClick = true
	continueArrow.Visible = true
	
	TweenService:Create(
		continueArrow,
		TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = continueArrow.Position + UDim2.fromOffset(0, -6) }
	):Play()
end

local function showChoices(choices)
	choicesFrame.Visible = true

	playerViewport.Visible = true
	setupPlayerViewport()

	for _, child in ipairs(choicesHolder:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, choice in ipairs(choices) do
		local button = choiceTemplate:Clone()
		button.Visible = true
		button.Text = choice.Text
		button.Parent = choicesHolder

		button.MouseButton1Click:Connect(function()
			playerViewport.Visible = false
			choicesFrame.Visible = false
			loadNode(choice.Next)
		end)
	end
end

local function faceNPC(playerChar, npc)
	local root = playerChar:FindFirstChild("HumanoidRootPart")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	if not root or not npcRoot then return end

	local lookPos = Vector3.new(
		npcRoot.Position.X,
		root.Position.Y,
		npcRoot.Position.Z
	)

	local goalCF = CFrame.lookAt(root.Position, lookPos)

	TweenService:Create(
		root,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ CFrame = goalCF }
	):Play()
end

function loadNode(nodeId)
	currentNode = currentDialogue.Nodes[nodeId]
	textLabel.Text = ""
	choicesFrame.Visible = false
	finalAcknowledged = false

	lineIndex = 1
	typeText(currentNode.Lines[lineIndex])
end

local function closeDialogue()
	dialogueHolder.Visible = false
	choicesFrame.Visible = false
	
	zoomOut()

	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = DEFAULT_WALK
		hum.JumpPower = DEFAULT_JUMP
	end

	if currentDialogue and currentDialogue.OnEnd == "Medallion" then
		jobHolder.Visible = true
		
		task.delay(0.3, function()
			MedallionController.Play()
		end)
	end
end

local function onPromptTriggered(prompt, npc)
	dialogueHolder.Visible = true
	continueArrow.Visible = false
	
	zoomIn()

	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
	end
	
	local character = player.Character
	if character then
		faceNPC(character, npc)
	end

	local module = npc:FindFirstChild("Dialogue")
	if not module then return end

	currentDialogue = require(module)
	nameLabel.Text = currentDialogue.Name

	viewport:ClearAllChildren()
	local camera = Instance.new("Camera", viewport)
	viewport.CurrentCamera = camera

	local clone = npc:Clone()
	clone.Parent = viewport

	for _, p in ipairs(clone:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
		end
	end

	clone:PivotTo(CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.rad(200), 0))

	local humanoidClone = clone:FindFirstChildOfClass("Humanoid")
	if humanoidClone then
		local animator = humanoidClone:FindFirstChildOfClass("Animator")
			or Instance.new("Animator", humanoidClone)

		local idle = clone:FindFirstChild("Idle", true)
		if idle then
			local track = animator:LoadAnimation(idle)
			track.Looped = true
			track.Priority = Enum.AnimationPriority.Idle
			track:Play()
		end
	end

	local root = clone:FindFirstChild("HumanoidRootPart")
	if root then
		camera.CFrame = CFrame.new(
			root.Position + Vector3.new(0, 1.2, 4),
			root.Position + Vector3.new(0, 0.8, 0)
		)
	end

	TweenService:Create(
		camera,
		TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = camera.CFrame * CFrame.new(0.1, 0, 0) }
	):Play()

	talkSound = clone:FindFirstChild("TalkEffect", true)

	loadNode(currentDialogue.Start)
	
	RunService.RenderStepped:Connect(function()
		if not dialogueHolder.Visible then return end

		local mousePos = UserInputService:GetMouseLocation()
		local viewportSize = workspace.CurrentCamera.ViewportSize

		local center = viewportSize / 2
		local offset = (mousePos - center) / center

		local targetPos = baseDialoguePos
			+ UDim2.fromOffset(offset.X * FLOAT_STRENGTH, offset.Y * FLOAT_STRENGTH)

		dialogueFrame.Position = dialogueFrame.Position:Lerp(targetPos, FOLLOW_SPEED)
	end)

	if inputConnection then inputConnection:Disconnect() end

	inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or typing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not waitingForClick then return end

		waitingForClick = false
		continueArrow.Visible = false

		lineIndex += 1

		if lineIndex <= #currentNode.Lines then
			typeText(currentNode.Lines[lineIndex])
			return
		end

		if currentNode.Choices then
			showChoices(currentNode.Choices)
			return
		end

		if currentNode.End then
			closeDialogue()
		end
	end)
end

for _, npc in ipairs(workspace.Characters:GetChildren()) do
	local prompt = npc:FindFirstChild("Chat", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function()
			onPromptTriggered(prompt, npc)
		end)
	end
end
