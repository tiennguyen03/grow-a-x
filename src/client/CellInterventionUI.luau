-- Cell intervention UI (Epic 3, Tier 1 — organelle upgrades).
--
-- The interactive organelle/cell-management interface, mounted INSIDE the planet
-- inspect panel (PlanetInteraction). The old "Matter Core" panel is obsolete — all
-- life interventions happen here, in planet context.
--
-- It shows: a "Create Archaea Cell" button (no cap on how many you make), a summed
-- production readout, a scrollable LIST of the player's cells, and — when a cell is
-- selected — a DETAIL view of that cell's seven organelle slots with a progress bar
-- toward the Eukaryotic transformation. Purchases are server-authoritative: this UI
-- only requests them (CreateArchaea / PurchaseOrganelle) and re-renders from the
-- ConverterUpdate the server pushes back. Server state is the single source of truth.
--
-- Usage (from PlanetInteraction):
--   local CellInterventionUI = require(script.Parent:WaitForChild("CellInterventionUI"))
--   CellInterventionUI.mount(infoPanel, { layoutOrder = 13 })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local OrganelleData = require(ReplicatedStorage:WaitForChild("OrganelleData"))

local CellInterventionUI = {}

-- Palette (kept in step with the inspect panel: dark translucent + cyan accents).
local CYAN        = Color3.fromRGB(130, 205, 255)
local GREEN       = Color3.fromRGB(120, 230, 170)
local GREEN_DEEP  = Color3.fromRGB(40, 96, 64)
local GOLD        = Color3.fromRGB(255, 220, 140)
local DIM         = Color3.fromRGB(150, 170, 190)
local LOCKED_BG   = Color3.fromRGB(34, 38, 50)
local PANEL_BG    = Color3.fromRGB(20, 26, 38)
local ROW_BG      = Color3.fromRGB(24, 32, 46)

local CONTENT_HEIGHT = 184 -- fixed height of the swappable list/detail area

-- Live state, fed by the remotes.
local localMatter = 0
local cells = {}           -- array of { id, stage, purchased = {id=true}, purchasedCount, production }
local totalProduction = 0
local localDustMultiplier = 1 -- Matter awarded per dust mote (raised by tier evolutions)
local localCascadeTriggered = false -- once true, newly created cells are born Eukaryotic
local selectedCellId: number? = nil  -- nil = show the list; set = show that cell's detail
local remotesRef = nil

-- Built once in mount(); the renderers read these.
local refs = nil

-- ---- Small UI factories -------------------------------------------------------
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency or 0.5
	s.Thickness = 1
	s.Parent = parent
	return s
end

-- Destroy a frame's children except its layout/padding (so re-render is clean).
local function clearContent(frame)
	for _, child in frame:GetChildren() do
		if not (child:IsA("UIListLayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
end

local function fmtRate(rate)
	return string.format("%.1f/s", rate)
end

-- A cell's display name reflects its evolution stage.
local function cellTitle(cell)
	local kind = (cell.stage == OrganelleData.STAGE_EUKARYOTIC) and "Eukaryotic Cell" or "Archaea Cell"
	return string.format("%s #%d", kind, cell.id)
end

local function findCell(cellId)
	for _, cell in ipairs(cells) do
		if cell.id == cellId then
			return cell
		end
	end
	return nil
end

-- ---- LIST view: one row per cell ----------------------------------------------
local function buildCellRow(parent, cell, order)
	local row = Instance.new("TextButton")
	row.Name = "Cell_" .. cell.id
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundColor3 = ROW_BG
	row.BorderSizePixel = 0
	row.AutoButtonColor = true
	row.Text = ""
	row.Parent = parent
	corner(row, 8)
	stroke(row, CYAN, 0.7)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 6)
	pad.Parent = row

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 18)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = (cell.stage == OrganelleData.STAGE_EUKARYOTIC) and GREEN or Color3.fromRGB(220, 236, 248)
	title.Text = cellTitle(cell)
	title.Parent = row

	local rate = Instance.new("TextLabel")
	rate.AnchorPoint = Vector2.new(1, 0)
	rate.Position = UDim2.fromScale(1, 0)
	rate.Size = UDim2.new(0, 64, 0, 18)
	rate.BackgroundTransparency = 1
	rate.Font = Enum.Font.GothamBold
	rate.TextSize = 13
	rate.TextXAlignment = Enum.TextXAlignment.Right
	rate.TextColor3 = GOLD
	rate.Text = fmtRate(cell.production)
	rate.Parent = row

	-- Mini progress bar toward Eukaryotic.
	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.fromOffset(0, 28)
	barBg.Size = UDim2.new(1, 0, 0, 6)
	barBg.BackgroundColor3 = LOCKED_BG
	barBg.BorderSizePixel = 0
	barBg.Parent = row
	corner(barBg, 3)

	local frac = cell.purchasedCount / OrganelleData.COUNT
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(frac, 0, 1, 0)
	barFill.BackgroundColor3 = (frac >= 1) and GREEN or CYAN
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	corner(barFill, 3)

	row.Activated:Connect(function()
		selectedCellId = cell.id
		CellInterventionUI.render()
	end)
end

local function renderList(content)
	clearContent(content)

	if #cells == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 13
		empty.TextWrapped = true
		empty.TextColor3 = DIM
		empty.Text = "No cells yet. Create an Archaea Cell above to begin its evolution."
		empty.Parent = content
		return
	end

	for i, cell in ipairs(cells) do
		buildCellRow(content, cell, i)
	end
end

-- ---- DETAIL view: one cell's organelle slots ----------------------------------
local function buildOrganelleSlot(parent, cell, organelle, order)
	local index = OrganelleData.indexOf(organelle.id)
	local isOwned = cell.purchased[organelle.id] == true
	local isNext = (not isOwned) and (index == cell.purchasedCount + 1)
	local isLocked = (not isOwned) and (not isNext)

	local slot = Instance.new("Frame")
	slot.Name = "Slot_" .. organelle.id
	slot.LayoutOrder = order
	slot.Size = UDim2.new(1, 0, 0, 42)
	slot.BackgroundColor3 = isOwned and GREEN_DEEP or (isLocked and LOCKED_BG or ROW_BG)
	slot.BackgroundTransparency = isLocked and 0.35 or 0
	slot.BorderSizePixel = 0
	slot.Parent = parent
	corner(slot, 8)
	stroke(slot, isOwned and GREEN or CYAN, isLocked and 0.85 or 0.6)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 5)
	pad.Parent = slot

	-- Name + lock icon for locked slots.
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -78, 0, 17)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamSemibold
	name.TextSize = 13
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = isLocked and DIM or Color3.fromRGB(224, 236, 248)
	name.Text = (isLocked and "🔒 " or "") .. organelle.name
	name.Parent = slot

	-- Cost + production bonus subline.
	local sub = Instance.new("TextLabel")
	sub.Position = UDim2.fromOffset(0, 20)
	sub.Size = UDim2.new(1, -78, 0, 15)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 11
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.TextColor3 = DIM
	sub.Text = string.format("%d Matter   +%.1f/s", organelle.cost, organelle.productionBonus)
	sub.Parent = slot

	-- Right side: owned check, buy button, or lock state.
	if isOwned then
		local owned = Instance.new("TextLabel")
		owned.AnchorPoint = Vector2.new(1, 0.5)
		owned.Position = UDim2.new(1, 0, 0.5, 0)
		owned.Size = UDim2.fromOffset(66, 24)
		owned.BackgroundTransparency = 1
		owned.Font = Enum.Font.GothamBold
		owned.TextSize = 13
		owned.TextXAlignment = Enum.TextXAlignment.Right
		owned.TextColor3 = GREEN
		owned.Text = "✓ Owned"
		owned.Parent = slot
	elseif isNext then
		local canAfford = localMatter >= organelle.cost
		local buy = Instance.new("TextButton")
		buy.AnchorPoint = Vector2.new(1, 0.5)
		buy.Position = UDim2.new(1, 0, 0.5, 0)
		buy.Size = UDim2.fromOffset(66, 26)
		buy.BackgroundColor3 = canAfford and GREEN_DEEP or Color3.fromRGB(44, 48, 60)
		buy.BorderSizePixel = 0
		buy.AutoButtonColor = canAfford
		buy.Font = Enum.Font.GothamBold
		buy.TextSize = 13
		buy.TextColor3 = canAfford and Color3.fromRGB(220, 255, 235) or Color3.fromRGB(140, 150, 165)
		buy.Text = "Buy"
		buy.Parent = slot
		corner(buy, 6)
		stroke(buy, CYAN, 0.55)

		buy.Activated:Connect(function()
			-- Visual guard only; the server re-validates order + affordability.
			if remotesRef and localMatter >= organelle.cost then
				remotesRef.PurchaseOrganelle:FireServer({
					cellId = cell.id,
					organelleId = organelle.id,
				})
			end
		end)
	else
		local lock = Instance.new("TextLabel")
		lock.AnchorPoint = Vector2.new(1, 0.5)
		lock.Position = UDim2.new(1, 0, 0.5, 0)
		lock.Size = UDim2.fromOffset(66, 24)
		lock.BackgroundTransparency = 1
		lock.Font = Enum.Font.Gotham
		lock.TextSize = 11
		lock.TextXAlignment = Enum.TextXAlignment.Right
		lock.TextColor3 = DIM
		lock.Text = "Locked"
		lock.Parent = slot
	end
end

local function renderDetail(content, cell)
	clearContent(content)

	local complete = OrganelleData.isComplete(cell.purchasedCount)

	-- Back to the cell list.
	local back = Instance.new("TextButton")
	back.LayoutOrder = 1
	back.Size = UDim2.new(0, 92, 0, 24)
	back.BackgroundColor3 = ROW_BG
	back.BorderSizePixel = 0
	back.AutoButtonColor = true
	back.Font = Enum.Font.GothamSemibold
	back.TextSize = 13
	back.TextColor3 = CYAN
	back.Text = "‹ Cells"
	back.Parent = content
	corner(back, 6)
	stroke(back, CYAN, 0.7)
	back.Activated:Connect(function()
		selectedCellId = nil
		CellInterventionUI.render()
	end)

	-- Header: title + stage + production.
	local header = Instance.new("TextLabel")
	header.LayoutOrder = 2
	header.Size = UDim2.new(1, 0, 0, 20)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 15
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = complete and GREEN or Color3.fromRGB(224, 236, 248)
	header.Text = cellTitle(cell)
	header.Parent = content

	local meta = Instance.new("TextLabel")
	meta.LayoutOrder = 3
	meta.Size = UDim2.new(1, 0, 0, 16)
	meta.BackgroundTransparency = 1
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 12
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.TextColor3 = DIM
	meta.Text = string.format(
		"%s   ·   %s   ·   %d/%d organelles",
		cell.stage,
		fmtRate(cell.production),
		cell.purchasedCount,
		OrganelleData.COUNT
	)
	meta.Parent = content

	-- Progress bar toward Eukaryotic.
	local barBg = Instance.new("Frame")
	barBg.LayoutOrder = 4
	barBg.Size = UDim2.new(1, 0, 0, 8)
	barBg.BackgroundColor3 = LOCKED_BG
	barBg.BorderSizePixel = 0
	barBg.Parent = content
	corner(barBg, 4)
	local frac = cell.purchasedCount / OrganelleData.COUNT
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(frac, 0, 1, 0)
	barFill.BackgroundColor3 = complete and GREEN or CYAN
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	corner(barFill, 4)

	if complete then
		local done = Instance.new("TextLabel")
		done.LayoutOrder = 5
		done.Size = UDim2.new(1, 0, 0, 18)
		done.BackgroundTransparency = 1
		done.Font = Enum.Font.GothamBold
		done.TextSize = 13
		done.TextXAlignment = Enum.TextXAlignment.Left
		done.TextColor3 = GREEN
		done.Text = "✓ Fully evolved — Eukaryotic Cell"
		done.Parent = content
	end

	-- Organelle slots, in canonical order.
	for i, organelle in ipairs(OrganelleData.ORGANELLES) do
		buildOrganelleSlot(content, cell, organelle, 10 + i)
	end
end

-- ---- Render dispatch ----------------------------------------------------------
function CellInterventionUI.render()
	if not refs then
		return
	end

	-- Header line: summed production + the current dust value (Matter per mote).
	refs.summary.Text = string.format(
		"Production  %s     Dust Value  ×%d",
		fmtRate(totalProduction),
		localDustMultiplier
	)

	-- Create button affordability + label. After the Eukaryotic Cascade, new cells
	-- are born Eukaryotic, so the button reflects the life form you'd actually create.
	local createCost = GameConfig.MATTER_CONVERTER_COST_ARCHAEA
	local canCreate = localMatter >= createCost
	local createLifeform = localCascadeTriggered and "Eukaryotic" or "Archaea"
	refs.createButton.AutoButtonColor = canCreate
	refs.createButton.BackgroundColor3 = canCreate and GREEN_DEEP or Color3.fromRGB(40, 44, 56)
	refs.createButton.TextColor3 = canCreate and Color3.fromRGB(220, 255, 235) or Color3.fromRGB(140, 150, 165)
	refs.createButton.Text = string.format("+ Create %s Cell  (%d Matter)", createLifeform, createCost)

	-- A selected cell that no longer exists falls back to the list.
	local cell = selectedCellId and findCell(selectedCellId) or nil
	if selectedCellId and not cell then
		selectedCellId = nil
	end

	if cell then
		renderDetail(refs.content, cell)
	else
		renderList(refs.content)
	end
end

-- ---- Mount --------------------------------------------------------------------
function CellInterventionUI.mount(parent: Instance, opts)
	opts = opts or {}

	local container = Instance.new("Frame")
	container.Name = "CellIntervention"
	container.LayoutOrder = opts.layoutOrder or 50
	container.BackgroundColor3 = PANEL_BG
	container.BackgroundTransparency = 0.25
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Parent = parent
	corner(container, 10)
	stroke(container, CYAN, 0.7)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = container

	-- Section header.
	local heading = Instance.new("TextLabel")
	heading.LayoutOrder = 1
	heading.Size = UDim2.new(1, 0, 0, 18)
	heading.BackgroundTransparency = 1
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 15
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.TextColor3 = CYAN
	heading.Text = "Cell Cultures"
	heading.Parent = container

	-- Summed production readout.
	local summary = Instance.new("TextLabel")
	summary.LayoutOrder = 2
	summary.Size = UDim2.new(1, 0, 0, 16)
	summary.BackgroundTransparency = 1
	summary.Font = Enum.Font.GothamSemibold
	summary.TextSize = 13
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.TextColor3 = GOLD
	summary.Text = "Production  0.0/s"
	summary.Parent = container

	-- Create-cell button (no cap — make as many as you like).
	local createButton = Instance.new("TextButton")
	createButton.Name = "CreateCell"
	createButton.LayoutOrder = 3
	createButton.Size = UDim2.new(1, 0, 0, 32)
	createButton.BackgroundColor3 = GREEN_DEEP
	createButton.BorderSizePixel = 0
	createButton.AutoButtonColor = true
	createButton.Font = Enum.Font.GothamBold
	createButton.TextSize = 14
	createButton.TextColor3 = Color3.fromRGB(220, 255, 235)
	createButton.Text = "+ Create Archaea Cell"
	createButton.Parent = container
	corner(createButton, 8)
	stroke(createButton, CYAN, 0.55)

	createButton.Activated:Connect(function()
		if remotesRef and localMatter >= GameConfig.MATTER_CONVERTER_COST_ARCHAEA then
			remotesRef.CreateArchaea:FireServer()
		end
	end)

	-- Swappable content area (list or detail). A ScrollingFrame so long cell lists
	-- and the 7 organelle slots stay reachable inside the fixed-height panel.
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.LayoutOrder = 4
	content.Size = UDim2.new(1, 0, 0, CONTENT_HEIGHT)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 4
	content.ScrollBarImageColor3 = CYAN
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.Parent = container

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 6)
	contentLayout.Parent = content

	refs = {
		container = container,
		summary = summary,
		createButton = createButton,
		content = content,
	}

	CellInterventionUI.render()

	-- Subscribe to the server's pushes off the main thread so mounting never blocks
	-- on replication. Re-render on every update so affordability + state stay live.
	task.spawn(function()
		local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
		remotesRef = Remotes

		Remotes.MatterUpdate.OnClientEvent:Connect(function(data)
			localMatter = math.max(0, math.floor(data.matter))
			CellInterventionUI.render()
		end)

		Remotes.ConverterUpdate.OnClientEvent:Connect(function(data)
			cells = data.cells or {}
			totalProduction = data.totalProduction or 0
			localDustMultiplier = math.max(1, math.floor(data.dustMultiplier or 1))
			localCascadeTriggered = data.cascadeTriggered == true
			CellInterventionUI.render()
		end)

		CellInterventionUI.render()
	end)

	return container
end

return CellInterventionUI
