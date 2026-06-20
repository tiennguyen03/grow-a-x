-- Ecosystem Interventions UI (Epic 6) — interactive planet-level interventions.
--
-- Mounted into the planet inspect panel BELOW Nova's Cell Cultures UI. Shows the
-- planet's Life Progress + Stability (from the server's ConverterUpdate) and the
-- three live interventions (Nourish Microbes / Stabilize Oceans / Accelerate
-- Mutation) as interactive cards. Clicking one fires the server-authoritative
-- ApplyIntervention remote; all validation/cost/effects live on the server. This
-- module is a view + request layer only and never touches the cell economy.
--
-- Usage (from PlanetInteraction):
--   EcosystemInterventionUI.mount(parent, { layoutOrder = 30 })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterventionData = require(ReplicatedStorage:WaitForChild("InterventionData"))

local CYAN  = Color3.fromRGB(130, 205, 255)
local GREEN = Color3.fromRGB(96, 224, 184)
local AMBER = Color3.fromRGB(232, 196, 120)
local DIM   = "rgb(150,172,196)"

local EcosystemInterventionUI = {}

-- Live state mirrored from the server.
local localMatter = 0
local lifeProgress = 0
local lifeProgressMax = 100
local stability = 75
local cellCount = 0

local refreshFns = {} -- card/bar refreshers registered at build time
local function refreshAll()
	for _, fn in refreshFns do
		fn()
	end
end

-- A labeled progress bar: returns a refresher that sets fill + text.
local function makeBar(parent, order: number, name: string, color: Color3, getValue)
	local row = Instance.new("Frame")
	row.Name = name .. "Bar"
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.RichText = true
	label.TextColor3 = Color3.fromRGB(214, 226, 240)
	label.Parent = row

	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(0, 16)
	track.Size = UDim2.new(1, 0, 0, 8)
	track.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
	track.BorderSizePixel = 0
	track.Parent = row
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(1, 0)
	tc.Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill

	return function()
		local value, max, suffix = getValue()
		label.Text = string.format('<font color="%s">%s</font>  %d%s', DIM, name, value, suffix)
		fill.Size = UDim2.fromScale(math.clamp(max > 0 and value / max or 0, 0, 1), 1)
	end
end

local function makeCard(parent, order: number, def, fireApply)
	local card = Instance.new("Frame")
	card.Name = "Eco_" .. def.id
	card.LayoutOrder = order
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Size = UDim2.new(1, 0, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = CYAN
	stroke.Transparency = 0.6
	stroke.Thickness = 1
	stroke.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = card
	local rows = Instance.new("UIListLayout")
	rows.SortOrder = Enum.SortOrder.LayoutOrder
	rows.Padding = UDim.new(0, 3)
	rows.Parent = card

	local title = Instance.new("TextLabel")
	title.LayoutOrder = 1
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Size = UDim2.new(1, 0, 0, 16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(214, 228, 244)
	title.Text = def.displayName
	title.Parent = card

	local meta = Instance.new("TextLabel")
	meta.LayoutOrder = 2
	meta.AutomaticSize = Enum.AutomaticSize.Y
	meta.Size = UDim2.new(1, 0, 0, 14)
	meta.BackgroundTransparency = 1
	meta.Font = Enum.Font.GothamMedium
	meta.TextSize = 13
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.RichText = true
	meta.TextColor3 = Color3.fromRGB(198, 210, 226)
	local costN = (def.cost and def.cost.Matter) or 0
	meta.Text = string.format('<font color="%s">Cost</font> %d Matter   ·   %s', DIM, costN, InterventionData.effectSummary(def))
	meta.Parent = card

	local flavor = Instance.new("TextLabel")
	flavor.LayoutOrder = 3
	flavor.AutomaticSize = Enum.AutomaticSize.Y
	flavor.Size = UDim2.new(1, 0, 0, 12)
	flavor.BackgroundTransparency = 1
	flavor.Font = Enum.Font.Gotham
	flavor.TextSize = 11
	flavor.TextWrapped = true
	flavor.TextXAlignment = Enum.TextXAlignment.Left
	flavor.TextColor3 = Color3.fromRGB(140, 156, 176)
	flavor.Text = def.flavor or ""
	flavor.Parent = card

	local button = Instance.new("TextButton")
	button.Name = "Apply"
	button.LayoutOrder = 4
	button.Size = UDim2.new(1, 0, 0, 28)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.AutoButtonColor = false
	button.Text = "Apply"
	button.Parent = card
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = button

	local e = def.effects or {}
	button.Activated:Connect(function()
		fireApply(def.id)
	end)

	-- Refresher: derive the card's state from the mirrored server values.
	return function()
		local lifeMaxed = (e.addLifeProgress or 0) > 0 and lifeProgress >= lifeProgressMax
		local stabMaxed = (e.addStability or 0) > 0 and not e.addLifeProgress and stability >= 100
		local locked = cellCount <= 0
		local affordable = localMatter >= costN
		local enabled = not (locked or lifeMaxed or stabMaxed) and affordable

		local text, ok
		if locked then
			text, ok = "Create a cell first", false
		elseif lifeMaxed then
			text, ok = "Ecosystem Matured", false
		elseif stabMaxed then
			text, ok = "Stability Maxed", false
		elseif not affordable then
			text, ok = string.format("Need %d Matter", costN - math.floor(localMatter)), false
		else
			text, ok = "Apply", true
		end

		button.Text = text
		button.AutoButtonColor = ok
		button.Active = ok
		button.BackgroundColor3 = ok and Color3.fromRGB(40, 96, 64) or Color3.fromRGB(38, 42, 54)
		button.TextColor3 = ok and Color3.fromRGB(224, 255, 238) or Color3.fromRGB(140, 150, 166)
		card.BackgroundTransparency = locked and 0.4 or 0.1
	end
end

function EcosystemInterventionUI.mount(parent: Instance, opts)
	opts = opts or {}
	local active = InterventionData.getEcosystemActive()

	local section = Instance.new("Frame")
	section.Name = "EcosystemInterventions"
	section.LayoutOrder = opts.layoutOrder or 30
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Size = UDim2.new(1, 0, 0, 0)
	section.BackgroundTransparency = 1
	section.Parent = parent

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = section

	local header = Instance.new("TextLabel")
	header.LayoutOrder = 1
	header.AutomaticSize = Enum.AutomaticSize.Y
	header.Size = UDim2.new(1, 0, 0, 18)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 14
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = CYAN
	header.Text = "Ecosystem Interventions"
	header.Parent = section

	local subtitle = Instance.new("TextLabel")
	subtitle.LayoutOrder = 2
	subtitle.AutomaticSize = Enum.AutomaticSize.Y
	subtitle.Size = UDim2.new(1, 0, 0, 14)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 12
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextColor3 = Color3.fromRGB(150, 166, 186)
	subtitle.Text = "Shape the world around your cells so life can grow, stabilize, and evolve."
	subtitle.Parent = section

	-- Milestone line (shown when Life Progress is maxed; Design C — no transition).
	local milestone = Instance.new("TextLabel")
	milestone.LayoutOrder = 3
	milestone.AutomaticSize = Enum.AutomaticSize.Y
	milestone.Size = UDim2.new(1, 0, 0, 14)
	milestone.BackgroundTransparency = 1
	milestone.Font = Enum.Font.GothamBold
	milestone.TextSize = 12
	milestone.TextXAlignment = Enum.TextXAlignment.Left
	milestone.TextColor3 = AMBER
	milestone.Text = "Ecosystem Matured — ready for Multicellular Life."
	milestone.Visible = false
	milestone.Parent = section
	table.insert(refreshFns, function()
		milestone.Visible = lifeProgress >= lifeProgressMax
	end)

	-- Life Progress + Stability bars.
	table.insert(refreshFns, makeBar(section, 4, "Life Progress", GREEN, function()
		return lifeProgress, lifeProgressMax, " / " .. lifeProgressMax
	end))
	table.insert(refreshFns, makeBar(section, 5, "Stability", CYAN, function()
		return stability, 100, "%"
	end))

	-- The fire function resolves the remote lazily off the main thread.
	local remotesRef = nil
	local function fireApply(id)
		if remotesRef then
			remotesRef.ApplyIntervention:FireServer({ interventionId = id })
		end
	end

	for i, def in active do
		table.insert(refreshFns, makeCard(section, 10 + i, def, fireApply))
	end

	refreshAll()

	task.spawn(function()
		local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
		remotesRef = Remotes
		Remotes.MatterUpdate.OnClientEvent:Connect(function(data)
			localMatter = math.max(0, math.floor(data.matter))
			refreshAll()
		end)
		Remotes.ConverterUpdate.OnClientEvent:Connect(function(data)
			cellCount = data.archaeaCount or cellCount
			lifeProgress = data.lifeProgress or lifeProgress
			lifeProgressMax = data.lifeProgressMax or lifeProgressMax
			stability = data.stability or stability
			refreshAll()
		end)
	end)

	return section
end

return EcosystemInterventionUI
