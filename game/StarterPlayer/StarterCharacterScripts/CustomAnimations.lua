local humanoid = script.Parent:WaitForChild("Humanoid")

local idleAnimations = {
	"rbxassetid://88816813753960",
	"rbxassetid://74549975427280",
	"rbxassetid://124055922934804",
	"rbxassetid://108175482811213",
	"rbxassetid://130459373341877",
	"rbxassetid://92804179832910"
}

local idleTracks = {}
for i, animId in ipairs(idleAnimations) do
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	idleTracks[i] = humanoid:LoadAnimation(anim)
end

local walkAnim = Instance.new("Animation")
walkAnim.AnimationId = "rbxassetid://82442955735029"
local runAnim = Instance.new("Animation")
runAnim.AnimationId = "rbxassetid://102481123412107"
local sprintJumpAnim = Instance.new("Animation")
sprintJumpAnim.AnimationId = "rbxassetid://131301000737294"
local jumpAnim = Instance.new("Animation")
jumpAnim.AnimationId = "rbxassetid://139625210682476"

local walkTrack = humanoid:LoadAnimation(walkAnim)
local runTrack = humanoid:LoadAnimation(runAnim)
local sprintJumpTrack = humanoid:LoadAnimation(sprintJumpAnim)

local jumpTrack = humanoid:LoadAnimation(jumpAnim)

local currentTrack = nil

local function play(track)
	if currentTrack == track then return end
	if currentTrack then
		currentTrack:Stop(0.2)
	end
	currentTrack = track
	currentTrack:Play(0.2)
end

local function playRandomIdle()
	local randomTrack = idleTracks[math.random(1, #idleTracks)]
	play(randomTrack)
end

local lastSpeed = 0

humanoid.Running:Connect(function(speed)
	lastSpeed = speed

	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		return
	end

	if speed == 0 then
		playRandomIdle()
	elseif speed < 18 then
		play(walkTrack)
	else
		play(runTrack)
	end
end)

humanoid.Jumping:Connect(function(isJumping)
	if isJumping then
		if lastSpeed > 18 then
			play(sprintJumpTrack)
		else
			play(jumpTrack)
		end
	end
end)

local animateScript = script.Parent:FindFirstChild("Animate")
if animateScript then
	animateScript.Disabled = true
end
