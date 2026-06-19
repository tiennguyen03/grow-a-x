local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
	-- Set immediately so the HUD never shows blank before the first remote fires.
	matterLabel.Text = "Matter: 0"
	matterLabel.Font = Enum.Font.GothamBold
	matterLabel.TextSize = 18
	matterLabel.Parent = frame

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "HintLabel"
	hintLabel.Size = UDim2.new(1, 0, 0.45, 0)
	hintLabel.Position = UDim2.new(0, 0, 0.55, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.TextColor3 = Color3.fromRGB(140, 120, 190)
	hintLabel.TextXAlignment = Enum.TextXAlignment.Left
	hintLabel.Text = "Fly through dust to collect"
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextSize = 13
	hintLabel.Parent = frame

	return screenGui, matterLabel
end

-- Floating "+N" that drifts up and fades out next to the HUD panel.
local function showPopup(screenGui, amount)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(0, 90, 0, 28)
	popup.Position = UDim2.new(0, 200, 0, 24)
	popup.BackgroundTransparency = 1
	popup.TextColor3 = Color3.fromRGB(255, 230, 150)
	popup.TextStrokeTransparency = 0.4
	popup.TextXAlignment = Enum.TextXAlignment.Left
	popup.Font = Enum.Font.GothamBold
	popup.TextSize = 22
	popup.Text = string.format("+%d", amount)
	popup.Parent = screenGui

	local tween = TweenService:Create(
		popup,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = popup.Position - UDim2.new(0, 0, 0, 40),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end

function MatterUI.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui, matterLabel = buildGui(playerGui)

	local lastMatter = 0

	-- Build the HUD first, then resolve the remote. This way the "Matter: 0"
	-- panel is on screen instantly and never waits on remote replication.
	task.spawn(function()
		local Remotes = require(ReplicatedStorage.Remotes)
		Remotes.MatterUpdate.OnClientEvent:Connect(function(data)
			local matter = math.max(0, math.floor(data.matter))
			matterLabel.Text = string.format("Matter: %d", matter)
			if matter > lastMatter then
				showPopup(screenGui, matter - lastMatter)
			end
			lastMatter = matter
		end)
	end)
end

return MatterUI
