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
local BOB_AMPLITUDE  = 1.5  -- studs
local BOB_SPEED      = 1.2  -- radians / second

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, mote in CollectionService:GetTagged(DUST_TAG) do
		local base = mote:GetAttribute("BasePosition")
		if base and not mote:GetAttribute("Collected") and not mote:GetAttribute("Pulling") then
			local phase = mote:GetAttribute("BobPhase") or 0
			local offset = math.sin(t * BOB_SPEED + phase) * BOB_AMPLITUDE
			mote.Position = base + Vector3.new(0, offset, 0)
		end
	end
end)
