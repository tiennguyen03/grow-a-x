-- Matter Converter UI (Epic 8, Sprint 8B).
--
-- A toggleable panel — opened by an always-on-screen "Create Life" button
-- (so touch/mobile players can use it) or the C key on desktop — where the
-- player spends Matter to create life forms that then produce Matter passively.
-- The first creation is the Archaea
-- Cell. This UI is purely a view + request layer: it shows the server-pushed
-- Matter balance and cell count, and asks the server to create a cell via the
-- CreateArchaea remote. The server validates and owns all the numbers, so this
-- module never decides whether a purchase is allowed — it only enables/greys the
-- button as a hint and lets the server be the final word.
--
-- Follows the module + .init() pattern (wired from Main.client.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local TOGGLE_KEY = Enum.KeyCode.C

local MatterConverterUI = {}

-- Cached local view of the server-owned numbers, refreshed by the remotes.
local localMatter = 0
local localArchaea = 0

local function buildGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MatterConverterGui"
	screenGui.ResetOnSpawn = false
	-- The ScreenGui stays enabled; the persistent open button below is always
	-- visible (so mobile players with no keyboard can open the menu by tapping),
	-- and only the panel itself is shown/hidden.
	screenGui.Parent = playerGui

	-- Persistent on-screen open button — always visible, top-right (clear of the
	-- Matter HUD top-left and of the mobile movement controls in the bottom
	-- corners). Works for touch and mouse; desktop players can also use the C key.
	local openButton = Instance.new("TextButton")
	openButton.Name = "OpenButton"
	openButton.AnchorPoint = Vector2.new(1, 0)
	openButton.Position = UDim2.new(1, -16, 0, 16)
	openButton.Size = UDim2.fromOffset(150, 44)
	openButton.BackgroundColor3 = Color3.fromRGB(70, 120, 90)
	openButton.BorderSizePixel = 0
	openButton.Font = Enum.Font.GothamBold
	openButton.TextSize = 16
	openButton.TextColor3 = Color3.fromRGB(240, 255, 245)
	openButton.Text = "Create Life"
	openButton.Parent = screenGui

	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 10)
	openCorner.Parent = openButton

	-- Centered panel (hidden until opened via the button or C).
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Visible = false
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(360, 280)
	panel.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel

	local panelPad = Instance.new("UIPadding")
	panelPad.PaddingTop = UDim.new(0, 16)
	panelPad.PaddingBottom = UDim.new(0, 16)
	panelPad.PaddingLeft = UDim.new(0, 18)
	panelPad.PaddingRight = UDim.new(0, 18)
	panelPad.Parent = panel

	-- Title.
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 26)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(210, 190, 255)
	title.Text = "Matter Converter"
	title.Parent = panel

	-- Tappable close button (mobile players have no Esc/C); top-right of the panel.
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 64)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 16
	closeButton.TextColor3 = Color3.fromRGB(220, 220, 240)
	closeButton.Text = "X"
	closeButton.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Current Matter balance, shown prominently under the title.
	local balance = Instance.new("TextLabel")
	balance.Name = "Balance"
	balance.Position = UDim2.fromOffset(0, 30)
	balance.Size = UDim2.new(1, 0, 0, 22)
	balance.BackgroundTransparency = 1
	balance.TextXAlignment = Enum.TextXAlignment.Left
	balance.Font = Enum.Font.GothamSemibold
	balance.TextSize = 16
	balance.TextColor3 = Color3.fromRGB(255, 230, 150)
	balance.Text = "Matter: 0"
	balance.Parent = panel

	-- Recipe card: Archaea Cell.
	local card = Instance.new("Frame")
	card.Name = "ArchaeaCard"
	card.Position = UDim2.fromOffset(0, 62)
	card.Size = UDim2.new(1, 0, 0, 130)
	card.BackgroundColor3 = Color3.fromRGB(22, 24, 46)
	card.BorderSizePixel = 0
	card.Parent = panel

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardPad = Instance.new("UIPadding")
	cardPad.PaddingTop = UDim.new(0, 10)
	cardPad.PaddingBottom = UDim.new(0, 10)
	cardPad.PaddingLeft = UDim.new(0, 12)
	cardPad.PaddingRight = UDim.new(0, 12)
	cardPad.Parent = card

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.new(1, 0, 0, 20)
	name.BackgroundTransparency = 1
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.TextColor3 = Color3.fromRGB(170, 255, 200)
	name.Text = "Archaea Cell"
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Position = UDim2.fromOffset(0, 22)
	desc.Size = UDim2.new(1, 0, 0, 18)
	desc.BackgroundTransparency = 1
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 13
	desc.TextColor3 = Color3.fromRGB(150, 160, 190)
	desc.Text = string.format(
		"Produces +%d Matter every %ds",
		GameConfig.ARCHAEA_PRODUCTION_AMOUNT,
		GameConfig.ARCHAEA_PRODUCTION_INTERVAL
	)
	desc.Parent = card

	local owned = Instance.new("TextLabel")
	owned.Name = "Owned"
	owned.Position = UDim2.fromOffset(0, 44)
	owned.Size = UDim2.new(1, 0, 0, 18)
	owned.BackgroundTransparency = 1
	owned.TextXAlignment = Enum.TextXAlignment.Left
	owned.Font = Enum.Font.GothamMedium
	owned.TextSize = 14
	owned.TextColor3 = Color3.fromRGB(200, 210, 235)
	owned.Text = "Owned: 0"
	owned.Parent = card

	-- Create button (bottom of the card).
	local button = Instance.new("TextButton")
	button.Name = "CreateButton"
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.new(0, 0, 1, 0)
	button.Size = UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = Color3.fromRGB(70, 120, 90)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(240, 255, 245)
	button.Text = string.format("Create  —  %d Matter", GameConfig.MATTER_CONVERTER_COST_ARCHAEA)
	button.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	-- Hint at the bottom of the panel.
	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.Position = UDim2.new(0, 0, 1, 0)
	hint.Size = UDim2.new(1, 0, 0, 16)
	hint.BackgroundTransparency = 1
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 12
	hint.TextColor3 = Color3.fromRGB(120, 120, 150)
	hint.Text = "Tap X or press C to close"
	hint.Parent = panel

	return screenGui, {
		panel = panel,
		openButton = openButton,
		closeButton = closeButton,
		balance = balance,
		owned = owned,
		button = button,
	}
end

function MatterConverterUI.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui, refs = buildGui(playerGui)

	-- Re-render the affordable state of the button + the live numbers.
	local cost = GameConfig.MATTER_CONVERTER_COST_ARCHAEA
	local function refresh()
		refs.balance.Text = string.format("Matter: %d", localMatter)
		refs.owned.Text = string.format("Owned: %d", localArchaea)

		local canAfford = localMatter >= cost
		refs.button.AutoButtonColor = canAfford
		refs.button.BackgroundColor3 = canAfford
			and Color3.fromRGB(70, 120, 90)   -- green: affordable
			or Color3.fromRGB(55, 58, 74)     -- grey: not enough Matter
		refs.button.TextColor3 = canAfford
			and Color3.fromRGB(240, 255, 245)
			or Color3.fromRGB(140, 145, 165)
	end
	refresh()

	-- Show/hide the panel. The persistent open button stays on screen either way,
	-- so touch players always have a way back in.
	local function setOpen(open)
		refs.panel.Visible = open
	end

	-- Open button (always visible): tap to toggle. Close button (X): tap to close.
	refs.openButton.Activated:Connect(function()
		setOpen(not refs.panel.Visible)
	end)
	refs.closeButton.Activated:Connect(function()
		setOpen(false)
	end)

	-- Desktop convenience: C toggles the panel too (ignore the keypress if the
	-- game already used it, e.g. the player is typing in a text box).
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == TOGGLE_KEY then
			setOpen(not refs.panel.Visible)
		end
	end)

	-- Ask the server to create an Archaea Cell. The server validates affordability;
	-- if the player can't afford it, the request is simply ignored server-side.
	refs.button.Activated:Connect(function()
		local Remotes = require(ReplicatedStorage.Remotes)
		Remotes.CreateArchaea:FireServer()
	end)

	-- Subscribe to the server's state pushes. Resolve the remotes off the main
	-- thread so the panel is built instantly and never waits on replication.
	task.spawn(function()
		local Remotes = require(ReplicatedStorage.Remotes)

		Remotes.MatterUpdate.OnClientEvent:Connect(function(data)
			localMatter = math.max(0, math.floor(data.matter))
			refresh()
		end)

		Remotes.ConverterUpdate.OnClientEvent:Connect(function(data)
			localArchaea = math.max(0, math.floor(data.archaeaCount))
			refresh()
		end)
	end)
end

return MatterConverterUI
