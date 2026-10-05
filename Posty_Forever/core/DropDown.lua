-- DropDown.lua - Posty (Forever) - par Daeler
-- Remplacant des menus deroulants de Blizzard (UIDropDownMenu).
--
-- Postal construit tous ses menus avec UIDropDownMenu, qui n'existe plus sur
-- le moteur de Forever (API 12.x). Ce fichier en reproduit la partie utilisee
-- par Postal, sous des noms propres a Posty pour ne rien casser chez les
-- autres addons :
--   UIDropDownMenu_AddButton   -> PostyDDM_AddButton
--   ToggleDropDownMenu         -> PostyDDM_Toggle
--   CloseDropDownMenus         -> PostyDDM_Close
--   UIDROPDOWNMENU_MENU_VALUE  -> PostyDDM_MENU_VALUE
--   UIDROPDOWNMENU_OPEN_MENU   -> PostyDDM_OPEN_MENU
--   DropDownList<n>Button<m>   -> PostyDDList<n>Button<m>

local BUTTON_HEIGHT = 18
local MIN_WIDTH = 100
local BACKDROP = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

PostyDDM_MENU_VALUE = nil
PostyDDM_OPEN_MENU = nil

local lists = {}

local function ButtonOnEnter(self)
	local list = self:GetParent()
	-- Ferme les sous-menus plus profonds, puis ouvre celui de ce bouton.
	PostyDDM_Close(list.level + 1)
	if self.hasArrow and self:IsEnabled() then
		PostyDDM_Toggle(list.level + 1, self.value, nil, nil, nil, nil, nil, self)
	end
	if self.tooltipTitle then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltipTitle)
		GameTooltip:Show()
	end
end

local function ButtonOnLeave()
	GameTooltip:Hide()
end

local function IsChecked(self)
	local checked = self.checked
	if type(checked) == "function" then checked = checked(self) end
	return checked and true or false
end

local function UpdateCheck(self, checked)
	local check, uncheck = self.Check, self.UnCheck
	if self.notCheckable then
		check:Hide()
		uncheck:Hide()
		return
	end
	if self.isNotRadio then
		check:SetTexture("Interface/Buttons/UI-CheckBox-Check")
		check:SetTexCoord(0, 1, 0, 1)
		uncheck:SetTexture("Interface/Buttons/UI-CheckBox-Up")
		uncheck:SetTexCoord(0, 1, 0, 1)
	else
		check:SetTexture("Interface/Buttons/UI-RadioButton")
		check:SetTexCoord(0.25, 0.5, 0, 1)
		uncheck:SetTexture("Interface/Buttons/UI-RadioButton")
		uncheck:SetTexCoord(0, 0.25, 0, 1)
	end
	check:SetShown(checked)
	uncheck:SetShown(not checked)
end

local function ButtonOnClick(self)
	if self.hasArrow and not self.func then
		PostyDDM_Toggle(self:GetParent().level + 1, self.value, nil, nil, nil, nil, nil, self)
		return
	end
	local checked = IsChecked(self)
	if self.keepShownOnClick then
		if not self.notCheckable then
			checked = not checked
			self.checked = checked
			UpdateCheck(self, checked)
		end
	end
	if self.func then
		self.func(self, self.arg1, self.arg2, checked)
	end
	if not self.keepShownOnClick then
		PostyDDM_Close()
	end
end

local function CreateButton(list, index)
	local name = list:GetName() .. "Button" .. index
	local b = CreateFrame("Button", name, list)
	b:SetHeight(BUTTON_HEIGHT)
	b:SetID(index)

	local hl = b:CreateTexture(nil, "BACKGROUND")
	hl:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
	hl:SetBlendMode("ADD")
	hl:SetAllPoints()
	b:SetHighlightTexture(hl)

	b.Check = b:CreateTexture(name .. "Check", "ARTWORK")
	b.Check:SetSize(16, 16)
	b.Check:SetPoint("LEFT", 0, 0)
	b.UnCheck = b:CreateTexture(name .. "UnCheck", "ARTWORK")
	b.UnCheck:SetSize(16, 16)
	b.UnCheck:SetPoint("LEFT", 0, 0)

	b.Arrow = b:CreateTexture(name .. "ExpandArrow", "ARTWORK")
	b.Arrow:SetTexture("Interface/ChatFrame/ChatFrameExpandArrow")
	b.Arrow:SetSize(16, 16)
	b.Arrow:SetPoint("RIGHT", 0, 0)

	b.Text = b:CreateFontString(name .. "NormalText", "ARTWORK", "GameFontHighlightLeft")
	b.Text:SetPoint("LEFT", 20, 0)
	b:SetFontString(b.Text)
	b:SetNormalFontObject("GameFontHighlightLeft")
	b:SetHighlightFontObject("GameFontHighlightLeft")
	b:SetDisabledFontObject("GameFontDisableLeft")

	-- Bouton invisible utilise par Postal pour griser une ligne.
	local inv = CreateFrame("Button", name .. "InvisibleButton", b)
	inv:SetAllPoints()
	inv:Hide()

	b:SetScript("OnClick", ButtonOnClick)
	b:SetScript("OnEnter", ButtonOnEnter)
	b:SetScript("OnLeave", ButtonOnLeave)
	return b
end

local function GetList(level)
	if lists[level] then return lists[level] end
	local list = CreateFrame("Frame", "PostyDDList" .. level, UIParent, "BackdropTemplate")
	list:SetFrameStrata("FULLSCREEN_DIALOG")
	list:SetToplevel(true)
	list:SetClampedToScreen(true)
	list:EnableMouse(true)
	list:SetBackdrop(BACKDROP)
	list:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	list:SetBackdropBorderColor(0.6, 0.6, 0.6)
	list:Hide()
	list.level = level
	list.numButtons = 0
	list.buttons = {}
	if level == 1 then tinsert(UISpecialFrames, list:GetName()) end
	list:SetScript("OnHide", function(self)
		if self.level == 1 then
			PostyDDM_Close(2)
			PostyDDM_OPEN_MENU = nil
		end
	end)
	lists[level] = list
	return list
end

function PostyDDM_AddButton(info, level)
	level = level or 1
	local list = GetList(level)
	local index = list.numButtons + 1
	local b = list.buttons[index]
	if not b then
		b = CreateButton(list, index)
		list.buttons[index] = b
	end
	list.numButtons = index

	b:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -10 - (index - 1) * BUTTON_HEIGHT)
	b.text = info.text
	b.func = info.func
	b.arg1, b.arg2 = info.arg1, info.arg2
	b.value = info.value
	b.hasArrow = info.hasArrow
	b.keepShownOnClick = info.keepShownOnClick
	b.notCheckable = info.notCheckable or info.isTitle
	b.isNotRadio = info.isNotRadio
	b.checked = info.checked
	b.tooltipTitle = info.tooltipTitle
	_G[b:GetName() .. "InvisibleButton"]:Hide()

	b:SetText(info.text or "")
	b.Text:ClearAllPoints()
	b.Text:SetPoint("LEFT", b.notCheckable and 0 or 20, 0)
	if info.isTitle then
		b:Disable()
		b.Text:SetTextColor(1, 0.82, 0)
	elseif info.disabled then
		b:Disable()
		b.Text:SetTextColor(0.5, 0.5, 0.5)
	else
		b:Enable()
		b.Text:SetTextColor(1, 1, 1)
	end
	-- Une ligne vide et desactivee sert de separateur.
	if not info.text and info.disabled then b:Disable() end

	UpdateCheck(b, IsChecked(b))
	b.Arrow:SetShown(info.hasArrow and true or false)
	b:Show()
end

local function Layout(list)
	local width = MIN_WIDTH
	for i = 1, list.numButtons do
		local b = list.buttons[i]
		local w = b.Text:GetStringWidth() + (b.notCheckable and 0 or 20) + (b.hasArrow and 20 or 0) + 8
		if w > width then width = w end
	end
	for i = 1, list.numButtons do list.buttons[i]:SetWidth(width) end
	for i = list.numButtons + 1, #list.buttons do list.buttons[i]:Hide() end
	list:SetWidth(width + 24)
	list:SetHeight(list.numButtons * BUTTON_HEIGHT + 20)
end

-- Meme signature que ToggleDropDownMenu. Pour les sous-menus, le dernier
-- argument est le bouton parent.
function PostyDDM_Toggle(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button)
	level = level or 1
	if level == 1 then
		local list = GetList(1)
		if list:IsShown() and PostyDDM_OPEN_MENU == dropDownFrame then
			PostyDDM_Close()
			return
		end
		PostyDDM_Close()
		PostyDDM_OPEN_MENU = dropDownFrame
	else
		dropDownFrame = PostyDDM_OPEN_MENU
	end
	if not dropDownFrame or not dropDownFrame.initialize then return end

	PostyDDM_Close(level)
	local list = GetList(level)
	list.numButtons = 0
	PostyDDM_MENU_VALUE = value
	dropDownFrame.initialize(dropDownFrame, level, menuList)
	if list.numButtons == 0 then return end
	Layout(list)

	list:ClearAllPoints()
	if level == 1 then
		local anchor = type(anchorName) == "string" and _G[anchorName] or anchorName or UIParent
		dropDownFrame.ownerButton = anchor
		list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOffset or 0, yOffset or 0)
	else
		list:SetPoint("TOPLEFT", button, "TOPRIGHT", 12, 10)
	end
	list:Show()
end

-- Sans argument, ferme tout. Avec un niveau, ferme ce niveau et les suivants.
function PostyDDM_Close(level)
	level = level or 1
	for i = level, #lists do
		if lists[i] then lists[i]:Hide() end
	end
end

-- Un clic en dehors des menus les ferme, comme ceux de Blizzard.
local watcher = CreateFrame("Frame")
if pcall(watcher.RegisterEvent, watcher, "GLOBAL_MOUSE_DOWN") then
	watcher:SetScript("OnEvent", function()
		if not (lists[1] and lists[1]:IsShown()) then return end
		for _, list in ipairs(lists) do
			if list:IsShown() and list:IsMouseOver() then return end
		end
		local owner = PostyDDM_OPEN_MENU and PostyDDM_OPEN_MENU.ownerButton
		if owner and owner:IsMouseOver() then return end
		PostyDDM_Close()
	end)
end
