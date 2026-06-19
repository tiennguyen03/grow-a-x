-- Screen-space navigation marker for the local player's own planet (Epic 7).
--
-- When you fly far enough from your planet, a marker shows where it is so you
-- can always find your way back as it orbits the star. The marker:
--   * tracks ONLY the local player's planet (matched by the OwnerUserId attribute)
--   * follows the planet live as it orbits
--   * sits over the planet when it's on screen, and clamps to the screen edge as
--     an arrow pointing toward it when it's off screen / behind you
--   * hides when you're close, or when your planet hasn't spawned yet
--
-- Self-contained LocalScript (like SpaceMovement / DustAnimator) — no init wiring.
-- A single ScreenGui is built once with ResetOnSpawn = false, so respawning never
-- spawns a duplicate marker.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("WorldConfig"))

local MIN_DISTANCE = 150  -- hide the marker when closer than this (studs)
local EDGE_MARGIN  = 64   -- keep the marker this far from the screen edge
local LABEL_TEXT   = WorldConfig.HOME_PLANET_DISPLAY_NAME or "Origin World"

local player = Players.LocalPlayer

-- ---- Build the marker UI once -------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "PlanetMarker"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Marker"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Size = UDim2.fromOffset(0, 0) -- zero-size anchor; children position around it
root.BackgroundTransparency = 1
root.Parent = gui

-- Directional arrow (only shown when the planet is off screen).
local arrow = Instance.new("TextLabel")
arrow.Name = "Arrow"
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.Position = UDim2.fromScale(0.5, 0.5)
arrow.Size = UDim2.fromOffset(34, 34)
arrow.BackgroundTransparency = 1
arrow.Font = Enum.Font.GothamBold
arrow.Text = "▲"
arrow.TextScaled = true
arrow.TextColor3 = Color3.fromRGB(150, 220, 255)
arrow.TextStrokeTransparency = 0.4
arrow.Parent = root

-- "Origin World • 420 studs" label, sat just below the anchor.
local label = Instance.new("TextLabel")
label.Name = "Label"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0.5, 22)
label.Size = UDim2.fromOffset(180, 20)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.TextSize = 15
label.TextColor3 = Color3.fromRGB(220, 240, 255)
label.TextStrokeTransparency = 0.4
label.Text = LABEL_TEXT
label.Parent = root

-- ---- Tracking -----------------------------------------------------------------
local function findLocalPlanet()
	local env = Workspace:FindFirstChild("SpaceEnvironment")
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

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	local planet = findLocalPlanet()
	local body = planet and planet.PrimaryPart
	if not (camera and body) then
		gui.Enabled = false
		return
	end

	local planetPos = body.Position
	local dist = (planetPos - camera.CFrame.Position).Magnitude
	if dist < MIN_DISTANCE then
		gui.Enabled = false
		return
	end
	gui.Enabled = true

	local viewport = camera.ViewportSize
	local cx, cy = viewport.X / 2, viewport.Y / 2
	local screenPos, onScreen = camera:WorldToViewportPoint(planetPos)

	if screenPos.Z > 0 and onScreen then
		-- On screen: park the marker over the planet, hide the arrow.
		root.Position = UDim2.fromOffset(
			math.clamp(screenPos.X, EDGE_MARGIN, viewport.X - EDGE_MARGIN),
			math.clamp(screenPos.Y, EDGE_MARGIN, viewport.Y - EDGE_MARGIN)
		)
		arrow.Visible = false
	else
		-- Off screen / behind: clamp to the screen edge and point the arrow at it.
		local dx, dy = screenPos.X - cx, screenPos.Y - cy
		if screenPos.Z < 0 then -- behind the camera: the projection is mirrored
			dx, dy = -dx, -dy
		end
		if dx == 0 and dy == 0 then
			dy = -1
		end
		-- Scale the direction so it just touches the screen-edge rectangle.
		local scale = math.min(
			(cx - EDGE_MARGIN) / math.max(math.abs(dx), 1e-3),
			(cy - EDGE_MARGIN) / math.max(math.abs(dy), 1e-3)
		)
		root.Position = UDim2.fromOffset(cx + dx * scale, cy + dy * scale)
		arrow.Visible = true
		-- The "▲" glyph points up (-Y); rotate it to face (dx, dy).
		arrow.Rotation = math.deg(math.atan2(dy, dx)) + 90
	end

	label.Text = string.format("%s • %d studs", LABEL_TEXT, dist)
end)
