-- Matter Core UI (Epic 8 / Sprint 8B, unified with Epic 4 inspect — see
-- docs/Plans/MatterCore-Inspect-Integration.md).
--
-- A toggleable status panel — opened with the C key — showing the player's Matter
-- balance, how many Archaea Cells they own, and the production rate. It also shows
-- the current planet context from PlanetInspectContext. (The old always-on-screen
-- "Matter Core" banner button was removed; this panel is obsolete now that all life
-- interventions live in the planet inspect panel.)
--
-- The actual "Create Life" intervention now lives in the PLANET INSPECT panel
-- (PlanetInteraction), so there's a single, planet-contextual create path instead
-- of a detached global button. This panel is an overview + shortcut, not a second
-- create button — it points the player to inspect their planet to create life.
--
-- Follows the module + .init() pattern (wired from Main.client.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
-- Planet context published by the inspect UI (so this panel can name the planet).
local PlanetInspectContext = require(script.Parent:WaitForChild("PlanetInspectContext"))

local TOGGLE_KEY = Enum.KeyCode.C

local MatterConverterUI = {}

-- Cached local view of the server-owned numbers, refreshed by the remotes.
local localMatter = 0
local localArchaea = 0
local localDustMultiplier = 1 -- Matter awarded per dust mote (raised by tier evolutions)

local function buildGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MatterConverterGui"
	screenGui.ResetOnSpawn = false
	-- The ScreenGui stays enabled; only the (hidden) panel is shown/hidden. The
	-- old always-on-screen "Matter Core" banner (top-right) was removed — this
	-- panel is obsolete (all life interventions now live in the planet inspect
	-- panel) so the banner was just screen clutter. Desktop players can still
	-- toggle the panel with C.
	screenGui.Parent = playerGui

	-- Centered panel (hidden until opened via C).
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
	title.Text = "Matter Core"
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

	-- Dust Value: how much Matter each collected dust mote is worth right now (the
	-- player's permanent Dust Multiplier). Sits at the right of the balance row.
	local dustValue = Instance.new("TextLabel")
	dustValue.Name = "DustValue"
	dustValue.AnchorPoint = Vector2.new(1, 0)
	dustValue.Position = UDim2.new(1, 0, 0, 30)
	dustValue.Size = UDim2.fromOffset(150, 22)
	dustValue.BackgroundTransparency = 1
	dustValue.TextXAlignment = Enum.TextXAlignment.Right
	dustValue.Font = Enum.Font.GothamBold
	dustValue.TextSize = 16
	dustValue.TextColor3 = Color3.fromRGB(140, 230, 255)
	dustValue.Text = "Dust Value: ×1"
	dustValue.Parent = panel

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

	-- Where the create action now lives (bottom of the card). Create Life is a
	-- planet intervention in the inspect panel, so this panel just points there.
	local guide = Instance.new("TextLabel")
	guide.Name = "CreateGuide"
	guide.AnchorPoint = Vector2.new(0, 1)
	guide.Position = UDim2.new(0, 0, 1, 0)
	guide.Size = UDim2.new(1, 0, 0, 34)
	guide.BackgroundTransparency = 1
	guide.TextXAlignment = Enum.TextXAlignment.Left
	guide.TextYAlignment = Enum.TextYAlignment.Bottom
	guide.TextWrapped = true
	guide.Font = Enum.Font.GothamMedium
	guide.TextSize = 13
	guide.TextColor3 = Color3.fromRGB(170, 255, 200)
	guide.Text = "Create Life from the planet inspect panel — press E near your Origin World."
	guide.Parent = card

	-- Bottom line: shows the current planet context (set when inspecting).
	local context = Instance.new("TextLabel")
	context.Name = "Context"
	context.AnchorPoint = Vector2.new(0, 1)
	context.Position = UDim2.new(0, 0, 1, 0)
	context.Size = UDim2.new(1, 0, 0, 16)
	context.BackgroundTransparency = 1
	context.TextXAlignment = Enum.TextXAlignment.Left
	context.Font = Enum.Font.Gotham
	context.TextSize = 12
	context.TextColor3 = Color3.fromRGB(120, 120, 150)
	context.Text = "No planet inspected"
	context.Parent = panel

	return screenGui, {
		panel = panel,
		closeButton = closeButton,
		balance = balance,
		dustValue = dustValue,
		owned = owned,
		context = context,
	}
end

function MatterConverterUI.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui, refs = buildGui(playerGui)

	-- Re-render the live numbers (read-only overview; the spend happens in inspect).
	local function refresh()
		refs.balance.Text = string.format("Matter: %d", localMatter)
		refs.owned.Text = string.format("Owned: %d", localArchaea)
		refs.dustValue.Text = string.format("Dust Value: ×%d", localDustMultiplier)
	end
	refresh()

	-- Reflect the inspected-planet context published by the inspect UI.
	local function refreshContext()
		local ctx = PlanetInspectContext.get()
		if ctx and ctx.displayName then
			refs.context.Text = "Planet: " .. ctx.displayName
		else
			refs.context.Text = "No planet inspected — press E near your Origin World"
		end
	end
	refreshContext()
	PlanetInspectContext.Changed:Connect(refreshContext)
	-- If the inspect panel asks to open the converter, surface this panel.
	PlanetInspectContext.OpenRequested:Connect(function()
		refs.panel.Visible = true
		refreshContext()
	end)

	-- Show/hide the panel.
	local function setOpen(open)
		refs.panel.Visible = open
	end

	-- Close button (X): tap to close.
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
			localDustMultiplier = math.max(1, math.floor(data.dustMultiplier or 1))
			refresh()
		end)
	end)
end

return MatterConverterUI
