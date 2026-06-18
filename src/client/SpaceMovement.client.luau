local MOVE_SPEED     = 40
local VERTICAL_SPEED = 35
local ACCELERATION   = 8
local DECELERATION   = 10

-- Soaring / banking feel
local ORIENT_SMOOTH    = 9              -- how fast the body rotates toward its target pose
local POSE_MIN_SPEED   = 3              -- below this speed, return to an upright hover
local BANK_SENSITIVITY = 0.18          -- how hard turns translate into roll
local BANK_SMOOTH      = 6              -- how fast the bank angle eases in/out
local MAX_BANK         = math.rad(55)  -- max roll angle while turning

local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character, rootPart
local currentVelocity = Vector3.zero
local currentBank     = 0       -- current smoothed roll angle
local prevHeading     = nil     -- last horizontal travel direction, for measuring turn rate

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

	-- Mute the default footstep sound — we're floating, not walking
	local running = rootPart:FindFirstChild("Running")
	if running and running:IsA("Sound") then
		running.Volume = 0
	end

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

	-- Orientation: bank into a soaring flight pose --------------------------------
	local pos   = rootPart.Position
	local speed = currentVelocity.Magnitude
	local targetCFrame

	if speed > POSE_MIN_SPEED then
		local moveDir = currentVelocity.Unit

		-- lookAt needs an up hint that isn't parallel to moveDir (near-vertical flight)
		local upHint = Vector3.yAxis
		if math.abs(moveDir.Y) > 0.99 then
			upHint = (camForward.Magnitude > 0.01) and camForward or Vector3.zAxis
		end

		-- Stand facing travel dir, then pitch forward 90° into a head-first Superman pose
		local pose = CFrame.lookAt(pos, pos + moveDir, upHint) * CFrame.Angles(-math.pi / 2, 0, 0)

		-- Measure horizontal turn rate to drive the bank
		local horiz = Vector3.new(moveDir.X, 0, moveDir.Z)
		local bankTarget = 0
		if horiz.Magnitude > 0.05 then
			horiz = horiz.Unit
			if prevHeading then
				local turn   = math.atan2(prevHeading:Cross(horiz).Y, prevHeading:Dot(horiz))
				local angVel = turn / math.max(dt, 1e-3)
				bankTarget = math.clamp(-angVel * BANK_SENSITIVITY, -MAX_BANK, MAX_BANK)
			end
			prevHeading = horiz
		end

		currentBank += (bankTarget - currentBank) * math.clamp(BANK_SMOOTH * dt, 0, 1)
		-- After the pitch, the body's local Y axis points along travel, so rolling
		-- about local Y banks the character into the turn.
		targetCFrame = pose * CFrame.Angles(0, currentBank, 0)
	else
		-- Idle hover: stand upright facing the camera's horizontal direction
		local f = Vector3.new(camForward.X, 0, camForward.Z)
		f = (f.Magnitude > 0.01) and f.Unit or Vector3.zAxis
		currentBank += (0 - currentBank) * math.clamp(BANK_SMOOTH * dt, 0, 1)
		targetCFrame = CFrame.lookAt(pos, pos + f)
		prevHeading = nil
	end

	local alpha = math.clamp(ORIENT_SMOOTH * dt, 0, 1)
	rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, alpha)
end)
