-- Movement
local MOVE_SPEED        = 40
local BOOST_SPEED       = 95
local VERTICAL_SPEED    = 35
local ACCELERATION      = 8
local BOOST_ACCELERATION = 6
local DECELERATION      = 10

-- Camera feel
local NORMAL_FOV = 70
local BOOST_FOV  = 84
local FOV_SMOOTH = 8

-- Soaring / banking feel
local ORIENT_SMOOTH    = 9              -- how fast the body rotates toward its target pose
local POSE_MIN_SPEED   = 3              -- below this speed, return to an upright hover
local BANK_SENSITIVITY = 0.18          -- how hard turns translate into roll
local BANK_SMOOTH      = 6              -- how fast the bank angle eases in/out
local MAX_BANK         = math.rad(55)  -- max roll angle while turning

local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Find the local player's own planet (it orbits, so its position changes).
local function findLocalPlanet()
	local env = workspace:FindFirstChild("SpaceEnvironment")
	local planets = env and env:FindFirstChild("PlayerPlanets")
	if not planets then
		return nil
	end
	for _, model in planets:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId then
			return model
		end
	end
	return nil
end

-- Where R should drop the player: just outside their planet on the side facing
-- away from the star, so they land looking back at the system. Falls back to a
-- fixed point if the planet hasn't spawned yet.
local function returnHomePosition()
	local planet = findLocalPlanet()
	local body = planet and planet.PrimaryPart
	if not body then
		return WorldConfig.RETURN_HOME_FALLBACK
	end
	local planetPos = body.Position
	local radius = planet:GetAttribute("Radius") or 40
	local awayFromStar = planetPos - WorldConfig.CENTERPIECE_STAR_POS
	awayFromStar = (awayFromStar.Magnitude > 1e-3) and awayFromStar.Unit or Vector3.yAxis
	return planetPos + awayFromStar * (radius + WorldConfig.RETURN_HOME_CLEARANCE) + Vector3.new(0, 20, 0)
end

local character, rootPart
local currentVelocity = Vector3.zero
local currentBank     = 0       -- current smoothed roll angle
local prevHeading     = nil     -- last horizontal travel direction, for measuring turn rate
local boostParticles  = nil     -- ParticleEmitter, recreated per character
local inspectAnchorOffset = nil -- player offset from planet center, captured on inspect

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
		-- Keep us in Physics for flight — but never fight a Dead state, or sun-death
		-- (and any future death) couldn't complete / respawn.
		if newState ~= Enum.HumanoidStateType.Physics and newState ~= Enum.HumanoidStateType.Dead then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
	end)

	-- Mute the default locomotion sounds — we float through space, not walk.
	-- A one-time Volume = 0 doesn't stick: the engine's RbxCharacterSounds may
	-- create the "Running" sound AFTER this runs, and it rewrites that sound's
	-- Volume every frame from our AssemblyLinearVelocity (so it thinks we're
	-- running). So we catch the sound whenever it appears and re-zero its volume
	-- whenever the engine raises it.
	local function muteSound(sound)
		if not sound:IsA("Sound") then return end
		if sound.Name ~= "Running" and sound.Name ~= "Climbing" then return end
		sound.Volume = 0
		sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if sound.Volume > 0 then
				sound.Volume = 0
			end
		end)
	end
	for _, child in rootPart:GetChildren() do
		muteSound(child)
	end
	rootPart.ChildAdded:Connect(muteSound)

	-- Boost VFX: a particle trail that only emits while boosting.
	-- Parented to the new rootPart, so the old one is cleaned up with the old character.
	local boostAttachment = Instance.new("Attachment")
	boostAttachment.Name = "BoostVFXAttachment"
	boostAttachment.Parent = rootPart

	boostParticles = Instance.new("ParticleEmitter")
	boostParticles.Name = "BoostParticles"
	boostParticles.Enabled = false
	boostParticles.Rate = 40
	boostParticles.Lifetime = NumberRange.new(0.25, 0.45)
	boostParticles.Speed = NumberRange.new(8, 14)
	boostParticles.SpreadAngle = Vector2.new(15, 15)
	boostParticles.LightEmission = 0.8
	boostParticles.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	boostParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	boostParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	boostParticles.Parent = boostAttachment

	-- Kill any spawn velocity so the character doesn't drift
	rootPart.AssemblyLinearVelocity  = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	currentVelocity = Vector3.zero

	-- Don't leave the camera stuck at boost FOV after a respawn
	if camera then
		camera.FieldOfView = NORMAL_FOV
	end
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end

-- Return-home key: edge-triggered, so it fires once per press (not every frame held)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.R and rootPart then
		rootPart.AssemblyLinearVelocity  = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = CFrame.new(returnHomePosition())
		currentVelocity = Vector3.zero
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not rootPart or not character or not character.Parent then return end

	-- Sun death: diving into the center star kills you. The kill zone is a small
	-- margin beyond the star surface (WorldConfig.SUN_KILL_MARGIN); normal flight
	-- and planet orbit are hundreds of studs away, so this only fires on a real dive.
	local toStar = (rootPart.Position - WorldConfig.CENTERPIECE_STAR_POS).Magnitude
	if toStar <= WorldConfig.CENTERPIECE_STAR_RADIUS + WorldConfig.SUN_KILL_MARGIN then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0 -- respawns at origin (far from the star)
		end
		return
	end

	-- Inspect mode (Epic 4): while the player is inspecting their planet,
	-- PlanetInteraction sets this attribute. Rather than freezing the player in
	-- absolute space (the planet keeps orbiting the star and would slide out of
	-- frame), we CARRY the player along with the planet — we lock their position
	-- relative to the planet center, so they ride the orbit and stay framed. Only
	-- the orbital translation is followed (planet center), not the planet's own
	-- spin, so the player isn't spun around. Input + pose updates are skipped.
	if player:GetAttribute("PlanetInspectLocked") then
		local planet = findLocalPlanet()
		local body = planet and planet.PrimaryPart
		if body then
			if not inspectAnchorOffset then
				inspectAnchorOffset = rootPart.Position - body.Position
			end
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
			-- Keep the captured offset; preserve the player's current orientation.
			rootPart.CFrame = CFrame.new(body.Position + inspectAnchorOffset) * rootPart.CFrame.Rotation
		else
			rootPart.AssemblyLinearVelocity = Vector3.zero
		end
		currentVelocity = Vector3.zero
		if boostParticles then
			boostParticles.Enabled = false
		end
		return
	end
	inspectAnchorOffset = nil -- not inspecting → recapture offset next time

	-- Read horizontal input
	local inputDir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then inputDir += Vector3.new( 0, 0, -1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then inputDir += Vector3.new( 0, 0,  1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then inputDir += Vector3.new(-1, 0,  0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then inputDir += Vector3.new( 1, 0,  0) end

	-- Read vertical input — Space up, Left Ctrl down (Left Shift is boost now, not descend)
	local verticalInput = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		verticalInput = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		verticalInput = -1
	end

	-- Movement directions from the camera.
	-- W/S follow the FULL look vector (including pitch) so looking down flies you
	-- down and looking up climbs — real 3D flight. A/D strafe horizontally.
	-- Space / Left Ctrl add world-vertical on top for fine altitude control.
	local camCF    = camera.CFrame
	local camLook  = camCF.LookVector
	local camForward = Vector3.new(camLook.X, 0, camLook.Z)              -- flattened, used by the pose/idle code below
	local camRight   = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)

	if camLook.Magnitude    > 0.001 then camLook    = camLook.Unit    end
	if camForward.Magnitude > 0.001 then camForward = camForward.Unit end
	if camRight.Magnitude   > 0.001 then camRight   = camRight.Unit   end

	local moveDir = camLook * (-inputDir.Z) + camRight * inputDir.X
	local hasMoveInput = moveDir.Magnitude > 0.001

	-- Boost only applies when there's directional input
	local isBoosting   = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and hasMoveInput
	local moveSpeed    = isBoosting and BOOST_SPEED or MOVE_SPEED
	local accel        = isBoosting and BOOST_ACCELERATION or ACCELERATION

	local desiredVelocity = Vector3.zero
	if hasMoveInput then
		desiredVelocity = moveDir.Unit * moveSpeed
	end
	desiredVelocity += Vector3.new(0, verticalInput * VERTICAL_SPEED, 0)

	-- Smooth acceleration / deceleration
	local isMoving    = desiredVelocity.Magnitude > 0.001
	local smoothAlpha = isMoving
		and (1 - math.exp(-accel * dt))
		or  (1 - math.exp(-DECELERATION * dt))

	currentVelocity = currentVelocity:Lerp(desiredVelocity, smoothAlpha)
	rootPart.AssemblyLinearVelocity = currentVelocity

	-- Camera FOV: widen smoothly while boosting, ease back when not
	if camera then
		local targetFov = isBoosting and BOOST_FOV or NORMAL_FOV
		local fovAlpha  = math.clamp(FOV_SMOOTH * dt, 0, 1)
		camera.FieldOfView += (targetFov - camera.FieldOfView) * fovAlpha
	end

	-- Boost VFX toggles with boost state
	if boostParticles then
		boostParticles.Enabled = isBoosting
	end

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
