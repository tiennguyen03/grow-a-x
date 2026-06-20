-- ⚠️ DEV / TESTING TOOL — REMOVE BEFORE LAUNCH ⚠️
--
-- A small pop-up menu on the LEFT side of the screen that grants the local player
-- Matter on demand, so we don't have to replay every stage of the game to test
-- late-game content. The grant is server-authoritative: the buttons just ask the
-- server (DevGrantMatter), which validates + caps the amount.
--
-- To remove this entire tool before going live, delete THREE things:
--   1. this file (src/client/DevMenu.client.luau)
--   2. the `DevGrantMatter` remote in src/shared/Remotes.luau
--   3. the DevGrantMatter handler in PlayerManager.init (marked "DEV/TESTING ONLY")
--
-- Self-contained LocalScript (like the other *.client.luau views): no Main wiring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Matter grant amounts (label → amount).
local GRANTS = {
	{ label = "+100", amount = 100 },
	{ label = "+1K", amount = 1000 },
	{ label = "+10K", amount = 10000 },
	{ label = "+100K", amount = 100000 },
	{ label = "+1M", amount = 1000000 },
}

local DEV_RED = Color3.fromRGB(235, 90, 90)
local PANEL_BG = Color3.fromRGB(24, 16, 18)
local BTN_BG = Color3.fromRGB(58, 30, 34)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100 -- on top of gameplay UI
screenGui.Parent = playerGui

-- Root panel, anchored to the left edge, vertically centered.
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Position = UDim2.new(0, 12, 0.5, 0)
panel.Size = UDim2.fromOffset(150, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = PANEL_BG
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = DEV_RED
panelStroke.Transparency = 0.3
panelStroke.Thickness = 1
panelStroke.Parent = panel

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = panel

-- Header doubles as a collapse toggle.
local header = Instance.new("TextButton")
header.Name = "Header"
header.LayoutOrder = 1
header.Size = UDim2.new(1, 0, 0, 24)
header.BackgroundTransparency = 1
header.AutoButtonColor = false
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.TextColor3 = DEV_RED
header.Text = "🛠 DEV  ▾"
header.Parent = panel

local note = Instance.new("TextLabel")
note.Name = "Note"
note.LayoutOrder = 2
note.Size = UDim2.new(1, 0, 0, 13)
note.BackgroundTransparency = 1
note.Font = Enum.Font.Gotham
note.TextSize = 10
note.TextColor3 = Color3.fromRGB(150, 130, 132)
note.Text = "Grant Matter (testing)"
note.Parent = panel

-- The collapsible body holds the grant buttons.
local body = Instance.new("Frame")
body.Name = "Body"
body.LayoutOrder = 3
body.Size = UDim2.new(1, 0, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.BackgroundTransparency = 1
body.Parent = panel

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Padding = UDim.new(0, 5)
bodyLayout.Parent = body

-- Resolve the remote off the main thread so the menu builds instantly.
local devGrant
task.spawn(function()
	local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
	devGrant = Remotes.DevGrantMatter
end)

for i, grant in ipairs(GRANTS) do
	local btn = Instance.new("TextButton")
	btn.Name = "Grant_" .. grant.amount
	btn.LayoutOrder = i
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = BTN_BG
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 225, 225)
	btn.Text = grant.label .. " Matter"
	btn.Parent = body

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn

	btn.Activated:Connect(function()
		if devGrant then
			devGrant:FireServer(grant.amount)
		end
	end)
end

-- Collapse / expand on header tap.
local collapsed = false
header.Activated:Connect(function()
	collapsed = not collapsed
	body.Visible = not collapsed
	note.Visible = not collapsed
	header.Text = collapsed and "🛠 DEV  ▸" or "🛠 DEV  ▾"
end)
