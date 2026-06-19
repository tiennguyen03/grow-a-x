-- Planet inspect context — the seam between Tien's planet inspection (Epic 4)
-- and Nova's Matter Converter / economy UI.
--
-- Tien's side (PlanetInteraction) PUBLISHES which planet is currently being
-- inspected and fires an "open requested" signal when the player asks to open
-- the Matter Converter. Nova's side CONSUMES this: connect to `Changed` to track
-- the active planet, and to `OpenRequested` to open the Converter in that planet's
-- context. Until Nova connects a listener, nothing happens (no errors) — the seam
-- is intentionally inert on its own.
--
-- This is a client-only ModuleScript (ReplicatedStorage is not involved). It does
-- NOT touch Matter, costs, remotes, or server state — it only carries a small
-- context table between two client systems.
--
-- Context payload shape:
--   {
--     type = "Planet",
--     planetModel = <Model>,        -- live client reference (not sent over remotes)
--     planetId = <string?>,
--     ownerUserId = <number?>,
--     displayName = <string>,
--   }

local PlanetInspectContext = {}

local current: { [string]: any }? = nil

local changedBindable = Instance.new("BindableEvent")
local openRequestedBindable = Instance.new("BindableEvent")

-- Fired with the new context table when inspection starts, or `nil` when it ends.
PlanetInspectContext.Changed = changedBindable.Event
-- Fired with the current context when the player asks to open the Matter Converter.
PlanetInspectContext.OpenRequested = openRequestedBindable.Event

-- Set the active planet context (called by PlanetInteraction on inspect enter).
function PlanetInspectContext.set(context: { [string]: any })
	current = context
	changedBindable:Fire(context)
end

-- Clear the context (called on inspect exit).
function PlanetInspectContext.clear()
	current = nil
	changedBindable:Fire(nil)
end

-- The current context, or nil if not inspecting anything.
function PlanetInspectContext.get(): { [string]: any }?
	return current
end

-- Ask any listener (Nova's Converter UI) to open for the current planet. No-op if
-- there's no active context.
function PlanetInspectContext.requestOpen()
	if current then
		openRequestedBindable:Fire(current)
	end
end

return PlanetInspectContext
