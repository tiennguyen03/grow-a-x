-- Sentience UI (Epic 7) — Complex Life: guide sentience + civilization identity.
--
-- Mounted in the inspect panel BELOW Ecosystem Interventions. Gated until Complex
-- Life (Nova's Multicellular path complete / Life Progress 100). Shows a Sentience
-- Progress bar, the emerging Civilization Identity (top tendencies), and the five
-- sentience interventions as interactive cards — each raises Sentience Progress and
-- builds a tendency. Clicking fires the server-authoritative ApplyIntervention
-- remote (same pipeline as Epic 6). At Sentience 100 a Tool Use milestone shows.
--
-- View + request layer only; the server owns all numbers. Never touches cells.
--
-- Usage (from PlanetInteraction): SentienceUI.mount(parent, { layoutOrder = 40 })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterventionData = require(ReplicatedStorage:WaitForChild("InterventionData"))

local CYAN   = Color3.fromRGB(130, 205, 255)
local PURPLE = Color3.fromRGB(186, 158, 255) -- sentience accent
local AMBER  = Color3.fromRGB(232, 196, 120)
local DIM    = "rgb(150,172,196)"

local TENDENCY_LABELS = {
	cooperative = "Cooperative", curious = "Curious", adaptive = "Adaptive",
	competitive = "Competitive", strategic = "Strategic",
}

local SentienceUI = {}

-- Live state mirrored from the server.
local localMatter = 0
local sentienceProgress = 0
local sentienceProgressMax = 100
local tendencies = {}
local complexLife = false

local refreshFns = {}
local function refreshAll()
	for _, fn in refreshFns do
		fn()
	end
end

local function identityText()
	local ranked = {}
	for id, pts in tendencies do
		if pts > 0 then
			table.insert(ranked, { id = id, pts = pts })
		end
	end
	if #ranked == 0 then
		return "Emerging…"
	end
	table.sort(ranked, function(a, b)
		return a.pts > b.pts
	end)
	local parts = {}
	for i = 1, math.min(2, #ranked) do
		table.insert(parts, TENDENCY_LABELS[ranked[i].id] or ranked[i].id)
	end
	return table.concat(parts, " · ")
end

local function makeCard(parent, order, def, fireApply)
	local card = Instance.new("Frame")
	card.Name = "Sentience_" .. def.id
	card.LayoutOrder = order
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Size = UDim2.new(1, 0, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = PURPLE
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
	title.TextColor3 = Color3.fromRGB(220, 222, 244)
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
	meta.TextColor3 = Color3.fromRGB(204, 206, 226)
	local costN = (def.cost and def.cost.Matter) or 0
	local tendLabel = def.tendency and (TENDENCY_LABELS[def.tendency] or def.tendency) or nil
	meta.Text = string.format(
		'<font color="%s">Cost</font> %d Matter   ·   %s%s',
		DIM, costN, InterventionData.effectSummary(def),
		tendLabel and ('   ·   → ' .. tendLabel) or ""
	)
	meta.Parent = card

	local button = Instance.new("TextButton")
	button.Name = "Apply"
	button.LayoutOrder = 3
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

	button.Activated:Connect(function()
		fireApply(def.id)
	end)

	return function()
		local maxed = sentienceProgress >= sentienceProgressMax
		local affordable = localMatter >= costN
		local ok = not maxed and affordable
		local text
		if maxed then
			text = "Tool Use Reached"
		elseif not affordable then
			text = string.format("Need %d Matter", costN - math.floor(localMatter))
		else
			text = "Apply"
		end
		button.Text = text
		button.AutoButtonColor = ok
		button.Active = ok
		button.BackgroundColor3 = ok and Color3.fromRGB(74, 58, 120) or Color3.fromRGB(40, 42, 54)
		button.TextColor3 = ok and Color3.fromRGB(232, 224, 255) or Color3.fromRGB(140, 145, 165)
	end
end

function SentienceUI.mount(parent: Instance, opts)
	opts = opts or {}
	local active = InterventionData.getSentienceActive()

	local section = Instance.new("Frame")
	section.Name = "Sentience"
	section.LayoutOrder = opts.layoutOrder or 40
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
	header.TextColor3 = PURPLE
	header.Text = "Sentience"
	header.Parent = section

	-- Locked note (shown until Complex Life).
	local locked = Instance.new("TextLabel")
	locked.LayoutOrder = 2
	locked.AutomaticSize = Enum.AutomaticSize.Y
	locked.Size = UDim2.new(1, 0, 0, 14)
	locked.BackgroundTransparency = 1
	locked.Font = Enum.Font.Gotham
	locked.TextSize = 12
	locked.TextWrapped = true
	locked.TextXAlignment = Enum.TextXAlignment.Left
	locked.TextColor3 = Color3.fromRGB(150, 166, 186)
	locked.Text = "Reach Complex Life — complete the Multicellular path — to guide sentience."
	locked.Parent = section

	-- Body (bar + identity + milestone + cards), hidden until Complex Life.
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.LayoutOrder = 3
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Size = UDim2.new(1, 0, 0, 0)
	body.BackgroundTransparency = 1
	body.Visible = false
	body.Parent = section
	local bodyList = Instance.new("UIListLayout")
	bodyList.SortOrder = Enum.SortOrder.LayoutOrder
	bodyList.Padding = UDim.new(0, 6)
	bodyList.Parent = body

	local subtitle = Instance.new("TextLabel")
	subtitle.LayoutOrder = 1
	subtitle.AutomaticSize = Enum.AutomaticSize.Y
	subtitle.Size = UDim2.new(1, 0, 0, 14)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 12
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextColor3 = Color3.fromRGB(150, 166, 186)
	subtitle.Text = "Shape what kind of mind — and civilization — emerges from your world."
	subtitle.Parent = body

	-- Sentience Progress bar.
	local barRow = Instance.new("Frame")
	barRow.LayoutOrder = 2
	barRow.Size = UDim2.new(1, 0, 0, 30)
	barRow.BackgroundTransparency = 1
	barRow.Parent = body
	local barLabel = Instance.new("TextLabel")
	barLabel.Size = UDim2.new(1, 0, 0, 14)
	barLabel.BackgroundTransparency = 1
	barLabel.Font = Enum.Font.GothamMedium
	barLabel.TextSize = 13
	barLabel.TextXAlignment = Enum.TextXAlignment.Left
	barLabel.RichText = true
	barLabel.TextColor3 = Color3.fromRGB(214, 226, 240)
	barLabel.Parent = barRow
	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(0, 16)
	track.Size = UDim2.new(1, 0, 0, 8)
	track.BackgroundColor3 = Color3.fromRGB(30, 28, 44)
	track.BorderSizePixel = 0
	track.Parent = barRow
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(1, 0)
	tc.Parent = track
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = PURPLE
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill

	-- Civilization Identity line.
	local identity = Instance.new("TextLabel")
	identity.LayoutOrder = 3
	identity.AutomaticSize = Enum.AutomaticSize.Y
	identity.Size = UDim2.new(1, 0, 0, 14)
	identity.BackgroundTransparency = 1
	identity.Font = Enum.Font.GothamMedium
	identity.TextSize = 13
	identity.TextXAlignment = Enum.TextXAlignment.Left
	identity.RichText = true
	identity.TextColor3 = Color3.fromRGB(214, 226, 240)
	identity.Parent = body

	-- Tool Use milestone (shown at Sentience 100).
	local milestone = Instance.new("TextLabel")
	milestone.LayoutOrder = 4
	milestone.AutomaticSize = Enum.AutomaticSize.Y
	milestone.Size = UDim2.new(1, 0, 0, 14)
	milestone.BackgroundTransparency = 1
	milestone.Font = Enum.Font.GothamBold
	milestone.TextSize = 12
	milestone.TextXAlignment = Enum.TextXAlignment.Left
	milestone.TextColor3 = AMBER
	milestone.Text = "Tool Use awakened — your species begins to shape its world."
	milestone.Visible = false
	milestone.Parent = body

	local remotesRef = nil
	local function fireApply(id)
		if remotesRef then
			remotesRef.ApplyIntervention:FireServer({ interventionId = id })
		end
	end

	-- Cards container so it sorts below the bar/identity.
	local cards = Instance.new("Frame")
	cards.LayoutOrder = 5
	cards.AutomaticSize = Enum.AutomaticSize.Y
	cards.Size = UDim2.new(1, 0, 0, 0)
	cards.BackgroundTransparency = 1
	cards.Parent = body
	local cardsList = Instance.new("UIListLayout")
	cardsList.SortOrder = Enum.SortOrder.LayoutOrder
	cardsList.Padding = UDim.new(0, 6)
	cardsList.Parent = cards

	for i, def in active do
		table.insert(refreshFns, makeCard(cards, i, def, fireApply))
	end

	-- Section-level refresher: gate, bar, identity, milestone.
	table.insert(refreshFns, function()
		locked.Visible = not complexLife
		body.Visible = complexLife
		barLabel.Text = string.format(
			'<font color="%s">Sentience</font>  %d / %d', DIM, sentienceProgress, sentienceProgressMax
		)
		fill.Size = UDim2.fromScale(math.clamp(sentienceProgress / sentienceProgressMax, 0, 1), 1)
		identity.Text = string.format('<font color="%s">Civilization Identity</font>  %s', DIM, identityText())
		milestone.Visible = sentienceProgress >= sentienceProgressMax
	end)

	refreshAll()

	task.spawn(function()
		local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
		remotesRef = Remotes
		Remotes.MatterUpdate.OnClientEvent:Connect(function(data)
			localMatter = math.max(0, math.floor(data.matter))
			refreshAll()
		end)
		Remotes.ConverterUpdate.OnClientEvent:Connect(function(data)
			sentienceProgress = data.sentienceProgress or sentienceProgress
			sentienceProgressMax = data.sentienceProgressMax or sentienceProgressMax
			tendencies = data.tendencies or tendencies
			if data.complexLifeReached ~= nil then
				complexLife = data.complexLifeReached
			end
			refreshAll()
		end)
	end)

	return section
end

return SentienceUI
