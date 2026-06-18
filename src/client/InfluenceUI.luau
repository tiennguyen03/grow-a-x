local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local InfluenceUI = {}

local function buildGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InfluenceGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 220, 0, 72)
	frame.Position = UDim2.new(0, 16, 0, 16)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 24)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = frame

	local influenceLabel = Instance.new("TextLabel")
	influenceLabel.Name = "InfluenceLabel"
	influenceLabel.Size = UDim2.new(1, 0, 0.55, 0)
	influenceLabel.Position = UDim2.new(0, 0, 0, 0)
	influenceLabel.BackgroundTransparency = 1
	influenceLabel.TextColor3 = Color3.fromRGB(210, 190, 255)
	influenceLabel.TextXAlignment = Enum.TextXAlignment.Left
	influenceLabel.Text = "Influence: 0"
	influenceLabel.Font = Enum.Font.GothamBold
	influenceLabel.TextSize = 18
	influenceLabel.Parent = frame

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.TextColor3 = Color3.fromRGB(140, 120, 190)
	rateLabel.TextXAlignment = Enum.TextXAlignment.Left
	rateLabel.Text = "+1 / sec"
	rateLabel.Font = Enum.Font.Gotham
	rateLabel.TextSize = 14
	rateLabel.Parent = frame

	return influenceLabel, rateLabel
end

function InfluenceUI.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local influenceLabel, rateLabel = buildGui(playerGui)

	Remotes.InfluenceUpdate.OnClientEvent:Connect(function(data)
		influenceLabel.Text = string.format("Influence: %d", math.floor(data.influence))
		rateLabel.Text = string.format("+%g / sec", data.influencePerSec)
	end)
end

return InfluenceUI
