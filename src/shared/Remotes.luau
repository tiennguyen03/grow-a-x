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
}
