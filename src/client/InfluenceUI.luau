local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local MatterUI = {}

local function buildGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MatterGui"
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

	local matterLabel = Instance.new("TextLabel")
	matterLabel.Name = "MatterLabel"
	matterLabel.Size = UDim2.new(1, 0, 0.55, 0)
	matterLabel.Position = UDim2.new(0, 0, 0, 0)
	matterLabel.BackgroundTransparency = 1
	matterLabel.TextColor3 = Color3.fromRGB(210, 190, 255)
	matterLabel.TextXAlignment = Enum.TextXAlignment.Left
	matterLabel.Text = "Matter: 0"
	matterLabel.Font = Enum.Font.GothamBold
	matterLabel.TextSize = 18
	matterLabel.Parent = frame

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

	return matterLabel, rateLabel
end

function MatterUI.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local matterLabel, rateLabel = buildGui(playerGui)

	Remotes.MatterUpdate.OnClientEvent:Connect(function(data)
		matterLabel.Text = string.format("Matter: %d", math.max(0, math.floor(data.matter)))
		rateLabel.Text = string.format("+%g / sec", data.matterPerSec)
	end)
end

return MatterUI
