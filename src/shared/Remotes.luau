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
}
