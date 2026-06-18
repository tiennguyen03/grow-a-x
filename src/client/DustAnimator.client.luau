-- Gently bobs the collectible dust motes with a per-mote sine oscillation.
--
-- Runs entirely client-side: animating 80 anchored parts here costs zero
-- network traffic, whereas moving them on the server would replicate a
-- position change for every mote every frame. The server keeps each mote at
-- its un-bobbed home position (the "BasePosition" attribute), which is what
-- collection and respawn use — the bob is purely cosmetic.
--
-- A mote being pulled by the collection magnet is flagged "Pulling" by the
-- server, which drives its position directly — the bob yields to it so the two
-- don't fight over the mote's position.
--
-- Self-contained LocalScript (like SpaceMovement), so it needs no init wiring.

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local DUST_TAG       = "DustParticle"
local BOB_AMPLITUDE  = 1.5   -- studs
local BOB_SPEED      = 1.2   -- radians / second
local HUE_SPEED      = 0.15  -- iridescence: full hue cycles per second
local HUE_SATURATION = 0.55  -- keep it a soft oil-slick shimmer, not garish neon

local TAU = math.pi * 2

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, mote in CollectionService:GetTagged(DUST_TAG) do
		if mote:GetAttribute("Collected") then continue end
		local phase = mote:GetAttribute("BobPhase") or 0

		-- Iridescent shimmer: slowly sweep the neon hue, offset per mote so the
		-- field reads as shifting oil-slick colors rather than one flat tint.
		local hue = (t * HUE_SPEED + phase / TAU) % 1
		local color = Color3.fromHSV(hue, HUE_SATURATION, 1)
		mote.Color = color
		local light = mote:FindFirstChildWhichIsA("PointLight")
		if light then light.Color = color end

		-- Bob in place, but yield while the server is pulling the mote in.
		local base = mote:GetAttribute("BasePosition")
		if base and not mote:GetAttribute("Pulling") then
			local offset = math.sin(t * BOB_SPEED + phase) * BOB_AMPLITUDE
			mote.Position = base + Vector3.new(0, offset, 0)
		end
	end
end)
