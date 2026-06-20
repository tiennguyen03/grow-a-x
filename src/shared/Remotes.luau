local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()

-- The folder name must differ from this ModuleScript's name ("Remotes"), or
-- the client's WaitForChild("Remotes") finds the ModuleScript instead of the
-- folder and times out looking for the events inside it.
local FOLDER_NAME = "RemoteEvents"

local folder
if isServer then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 10)
end

local function get(name, className)
	if isServer then
		local inst = Instance.new(className)
		inst.Name = name
		inst.Parent = folder
		return inst
	else
		return folder:WaitForChild(name, 10)
	end
end

return {
	MatterUpdate = get("MatterUpdate", "RemoteEvent"),

	-- Matter Converter (Epic 8). CreateArchaea: client asks the server to spend
	-- Matter on one Archaea Cell (no payload; server validates cost). ConverterUpdate:
	-- server pushes the player's current converter state — now
	-- { archaeaCount, totalProduction, cells = { {id, stage, purchased, purchasedCount, production}, … } }.
	CreateArchaea   = get("CreateArchaea", "RemoteEvent"),
	ConverterUpdate = get("ConverterUpdate", "RemoteEvent"),

	-- Organelle upgrades (Epic 3, Tier 1). PurchaseOrganelle: client asks to buy the
	-- next organelle for a specific cell — payload { cellId, organelleId }; the server
	-- validates order + affordability. CellEvolved: server announces a cell finished
	-- the path and became a Eukaryotic Cell — payload { cellId } (drives the celebration).
	PurchaseOrganelle = get("PurchaseOrganelle", "RemoteEvent"),
	CellEvolved       = get("CellEvolved", "RemoteEvent"),

	-- Eukaryotic Cascade (Epic 3, Tier 1). Fired once, the first time a player ever
	-- completes a Eukaryotic Cell: the server instantly evolves all the player's other
	-- cells too and unlocks a permanent Dust Multiplier. Payload
	-- { triggerCellId, cellIds = { …others… }, count, dustMultiplier } — drives the
	-- "Eukaryotic Evolution Cascade!" celebration (bursts across every cell) and the
	-- "Dust Value ×N" announcement. The authoritative state already arrived via
	-- ConverterUpdate (which now also carries dustMultiplier); this is feedback only.
	CascadeTriggered = get("CascadeTriggered", "RemoteEvent"),

	-- Multicellular upgrades (Epic 3, Tier 1C). PurchaseUpgrade: client asks to buy the
	-- next player-wide Eukaryotic→Multicellular upgrade — no payload; the server
	-- validates order + (dynamic) cost. The new global state (multicellularUpgrades +
	-- the next dynamic cost) rides back on ConverterUpdate; UpgradePurchased fires as a
	-- one-shot feedback signal — payload { step, upgradeId } — to drive the biosphere
	-- visual progression + a toast.
	PurchaseUpgrade  = get("PurchaseUpgrade", "RemoteEvent"),
	UpgradePurchased = get("UpgradePurchased", "RemoteEvent"),

	-- ⚠️ DEV/TESTING ONLY — remove before launch. DevGrantMatter: the dev menu asks the
	-- server to grant the requesting player Matter (payload: amount:number). Server caps
	-- it so a stray value can't break things. See PlayerManager dev handler + DevMenu.client.
	DevGrantMatter = get("DevGrantMatter", "RemoteEvent"),
}
