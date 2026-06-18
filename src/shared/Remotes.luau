local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()

local folder
if isServer then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes", 10)
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
