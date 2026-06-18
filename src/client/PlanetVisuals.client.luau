-- Slow, purely-visual rotation of player planets (Epic 7).
--
-- Self-contained LocalScript (like SpaceMovement) — no module pattern. It spins
-- every planet model under workspace.SpaceEnvironment.PlayerPlanets client-side
-- only; it never touches gameplay, collision, or server state. Rotation speed
-- comes from each model's RotationSeconds attribute.

local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local DEFAULT_ROTATION_SECONDS = 160

-- model -> { angle, center, speed }
local spin = setmetatable({}, { __mode = "k" }) -- weak keys: entries drop when models are GC'd

local function spinDataFor(model)
	local data = spin[model]
	if not data then
		data = {
			angle = 0,
			center = model:GetPivot().Position,
			speed = (2 * math.pi) / (model:GetAttribute("RotationSeconds") or DEFAULT_ROTATION_SECONDS),
		}
		spin[model] = data
	end
	return data
end

RunService.RenderStepped:Connect(function(dt)
	local env = Workspace:FindFirstChild("SpaceEnvironment")
	local planets = env and env:FindFirstChild("PlayerPlanets")
	if not planets then
		return
	end

	for _, model in planets:GetChildren() do
		if model:IsA("Model") and model.PrimaryPart then
			local data = spinDataFor(model)
			data.angle += data.speed * dt
			-- Rotate the whole model rigidly about its center's Y axis (visual only)
			model:PivotTo(CFrame.new(data.center) * CFrame.Angles(0, data.angle, 0))
		end
	end
end)
