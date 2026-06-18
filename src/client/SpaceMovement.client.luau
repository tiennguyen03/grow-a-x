local MOVE_SPEED     = 40
local VERTICAL_SPEED = 35
local ACCELERATION   = 8
local DECELERATION   = 10

local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character, rootPart
local currentVelocity = Vector3.zero

local function setupCharacter(char)
	character = char
	rootPart  = char:WaitForChild("HumanoidRootPart")

	local humanoid = char:WaitForChild("Humanoid")
	humanoid.WalkSpeed   = 0
	humanoid.JumpPower   = 0
	humanoid.AutoRotate  = false

	-- Hand all physics control to this script; prevent Humanoid Freefall from fighting us
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.StateChanged:Connect(function(_, newState)
		if newState ~= Enum.HumanoidStateType.Physics then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
	end)

	-- Kill any spawn velocity so the character doesn't drift
	rootPart.AssemblyLinearVelocity  = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	currentVelocity = Vector3.zero
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end

RunService.RenderStepped:Connect(function(dt)
	if not rootPart or not character or not character.Parent then return end

	-- Read horizontal input
	local inputDir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then inputDir += Vector3.new( 0, 0, -1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then inputDir += Vector3.new( 0, 0,  1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then inputDir += Vector3.new(-1, 0,  0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then inputDir += Vector3.new( 1, 0,  0) end

	-- Read vertical input
	local verticalInput = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		verticalInput = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
		or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		verticalInput = -1
	end

	-- Project W/S/A/D onto camera's horizontal plane
	local camCF      = camera.CFrame
	local camForward = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
	local camRight   = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)

	if camForward.Magnitude > 0.001 then camForward = camForward.Unit end
	if camRight.Magnitude   > 0.001 then camRight   = camRight.Unit   end

	local horizontal = camForward * (-inputDir.Z) + camRight * inputDir.X
	local desiredVelocity = Vector3.zero

	if horizontal.Magnitude > 0.001 then
		desiredVelocity = horizontal.Unit * MOVE_SPEED
	end
	desiredVelocity += Vector3.new(0, verticalInput * VERTICAL_SPEED, 0)

	-- Smooth acceleration / deceleration
	local isMoving    = desiredVelocity.Magnitude > 0.001
	local smoothAlpha = isMoving
		and (1 - math.exp(-ACCELERATION * dt))
		or  (1 - math.exp(-DECELERATION * dt))

	currentVelocity = currentVelocity:Lerp(desiredVelocity, smoothAlpha)
	rootPart.AssemblyLinearVelocity = currentVelocity
end)
