-- Future-intervention preview cards (Epic 5, additive).
--
-- Read-only "Coming Soon" cards for interventions that arrive in Epic 6 (Life
-- Progress / Stability), shown in the planet inspect panel BELOW Nova's live
-- cell/organelle UI. Pure preview — no server calls, no economy, no buttons — so
-- players can see where planet progression is headed without any new spend path.
-- Data comes from the shared InterventionData definitions.
--
-- Usage (from PlanetInteraction, which owns the inspect panel):
--   InterventionPreviewUI.mount(infoPanel, { layoutOrder = 30 })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterventionData = require(ReplicatedStorage:WaitForChild("InterventionData"))

local CYAN     = Color3.fromRGB(130, 205, 255)
local AMBER    = Color3.fromRGB(232, 196, 120)
local DIM      = "rgb(150,172,196)"

local InterventionPreviewUI = {}

local function makeCard(def, order: number): Frame
	local card = Instance.new("Frame")
	card.Name = "Preview_" .. def.id
	card.LayoutOrder = order
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Size = UDim2.new(1, 0, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	card.BackgroundTransparency = 0.25 -- slightly faded => reads as "not yet active"
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = CYAN
	stroke.Transparency = 0.7
	stroke.Thickness = 1
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = card

	local rows = Instance.new("UIListLayout")
	rows.FillDirection = Enum.FillDirection.Vertical
	rows.SortOrder = Enum.SortOrder.LayoutOrder
	rows.Padding = UDim.new(0, 2)
	rows.Parent = card

	-- Title line: name (left) + a "Coming Soon · Epic N" badge feel via RichText.
	local title = Instance.new("TextLabel")
	title.LayoutOrder = 1
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Size = UDim2.new(1, 0, 0, 18)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.RichText = true
	title.TextColor3 = Color3.fromRGB(210, 224, 240)
	local badge = def.state == "ComingSoon" and def.unlockEpic
		and string.format('  <font color="rgb(232,196,120)" size="12">Coming Soon · Epic %d</font>', def.unlockEpic)
		or '  <font color="rgb(232,196,120)" size="12">Locked</font>'
	title.Text = def.displayName .. badge
	title.Parent = card

	-- Cost + effect line.
	local meta = Instance.new("TextLabel")
	meta.LayoutOrder = 2
	meta.AutomaticSize = Enum.AutomaticSize.Y
	meta.Size = UDim2.new(1, 0, 0, 16)
	meta.BackgroundTransparency = 1
	meta.Font = Enum.Font.GothamMedium
	meta.TextSize = 13
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.RichText = true
	meta.TextColor3 = Color3.fromRGB(200, 212, 228)
	local cost = (def.cost and def.cost.Matter) and string.format("%d Matter", def.cost.Matter) or "—"
	meta.Text = string.format('<font color="%s">Cost</font> %s   ·   %s', DIM, cost, InterventionData.effectSummary(def))
	meta.Parent = card

	-- Flavor line (wrapped, dim).
	if def.flavor then
		local flavor = Instance.new("TextLabel")
		flavor.LayoutOrder = 3
		flavor.AutomaticSize = Enum.AutomaticSize.Y
		flavor.Size = UDim2.new(1, 0, 0, 14)
		flavor.BackgroundTransparency = 1
		flavor.Font = Enum.Font.Gotham
		flavor.TextSize = 12
		flavor.TextWrapped = true
		flavor.TextXAlignment = Enum.TextXAlignment.Left
		flavor.TextColor3 = Color3.fromRGB(140, 156, 176)
		flavor.Text = def.flavor
		flavor.Parent = card
	end

	return card
end

-- Build the preview section into `parent` (the inspect info panel).
function InterventionPreviewUI.mount(parent: Instance, opts)
	opts = opts or {}
	local previews = InterventionData.getPreviews()
	if #previews == 0 then
		return
	end

	local section = Instance.new("Frame")
	section.Name = "FutureInterventions"
	section.LayoutOrder = opts.layoutOrder or 30
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Size = UDim2.new(1, 0, 0, 0)
	section.BackgroundTransparency = 1
	section.Parent = parent

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = section

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.LayoutOrder = 1
	header.AutomaticSize = Enum.AutomaticSize.Y
	header.Size = UDim2.new(1, 0, 0, 18)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 14
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = CYAN
	header.Text = "Future Interventions"
	header.Parent = section

	for i, def in previews do
		makeCard(def, i + 1).Parent = section
	end

	return section
end

return InterventionPreviewUI
