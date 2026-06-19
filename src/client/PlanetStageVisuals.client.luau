-- Planet stage visuals — early life-stage feedback hook (Epic 4, Sprint 4E).
--
-- Watches the local player's planet for an evolution stage/tier attribute and
-- adds a subtle visual overlay when life appears. This is the FIRST visual hook,
-- not the full 9-tier system — right now it only handles the Archaea (tier 1)
-- stage: a faint teal-green ForceField shimmer just outside the planet body that
-- gently pulses. When the stage is below that (default/prebiotic), no overlay
-- exists. Nova's progression system drives this purely by setting an attribute:
--   * EvolutionTier  = 0,1,2,…   (preferred, numeric)
--   * EvolutionStage = "Archaea" (string alternative)
--
-- The planet is moved server-side via PivotTo, which does NOT carry a client-only
-- part — so the overlay (a client part) follows the body's live CFrame each frame.
--
-- Self-contained LocalScript (like PlanetMarker / DustAnimator) — no init wiring.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local OVERLAY_NAME  = "LifeOverlay_Archaea"
local ARCHAEA_COLOR = Color3.fromRGB(96, 224, 184) -- teal-green microbial tint
local OVERLAY_SCALE = 1.09  -- diameter relative to the planet body
local PULSE_MIN     = 0.80  -- transparency range for the gentle pulse
local PULSE_MAX     = 0.93
local PULSE_SPEED   = 1.3   -- pulse radians/sec

local player = Players.LocalPlayer

local function findLocalPlanet(): Model?
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

-- Should the Archaea overlay be showing, per the planet's attributes?
local function archaeaActive(planet: Model): boolean
	local tier = planet:GetAttribute("EvolutionTier")
	if typeof(tier) == "number" and tier >= 1 then
		return true
	end
	local stage = planet:GetAttribute("EvolutionStage")
	return typeof(stage) == "string" and stage:lower() == "archaea"
end

local function ensureOverlay(planet: Model, body: BasePart): BasePart
	local existing = planet:FindFirstChild(OVERLAY_NAME)
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local overlay = Instance.new("Part")
	overlay.Name = OVERLAY_NAME
	overlay.Shape = Enum.PartType.Ball
	overlay.Size = body.Size * OVERLAY_SCALE
	overlay.Anchored = true
	overlay.CanCollide = false
	overlay.CanQuery = false
	overlay.CastShadow = false
	overlay.Material = Enum.Material.ForceField
	overlay.Color = ARCHAEA_COLOR
	overlay.Transparency = PULSE_MAX
	overlay.Parent = planet
	return overlay
end

local function removeOverlay(planet: Model)
	local existing = planet:FindFirstChild(OVERLAY_NAME)
	if existing then
		existing:Destroy()
	end
end

RunService.Heartbeat:Connect(function()
	local planet = findLocalPlanet()
	local body = planet and planet.PrimaryPart
	if not (planet and body) then
		return
	end

	if archaeaActive(planet) then
		local overlay = ensureOverlay(planet, body)
		overlay.CFrame = body.CFrame -- follow the orbiting/spinning planet
		local mid = (PULSE_MIN + PULSE_MAX) * 0.5
		local amp = (PULSE_MAX - PULSE_MIN) * 0.5
		overlay.Transparency = mid + amp * math.sin(os.clock() * PULSE_SPEED)
	else
		removeOverlay(planet)
	end
end)
