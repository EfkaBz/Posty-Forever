-- Posty (Forever) - portage de Postal pour World of Warcraft: Forever.
-- Postal v4.3.4 : Xinhuan, Ammo, Rabbit, Grennon, Mikk, oscarucb,
-- Jonny aka The_Original_Manbot - https://www.curseforge.com/wow/addons/postal
-- Code de Postal : All Rights Reserved (voir LICENSE.txt). Adaptation
-- Forever (menus, noms avec nom de famille, fonctions absentes) : Daeler.

local Postal = LibStub("AceAddon-3.0"):NewAddon("Posty_Forever", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Posty_Forever")
_G["PostyForever"] = Postal

-- defaults for storage
local defaults = {
	profile = {
		ModuleEnabledState = {
			["*"] = true
		},
		OpenSpeed = 0.50,
		ChatOutput = 1,
		Select = {
			SpamChat = true,
			KeepFreeSpace = 1,
		},
		OpenAll = {
			AHCancelled = true,
			AHExpired = true,
			AHOutbid = true,
			AHSuccess = true,
			AHWon = true,
			NeutralAHCancelled = true,
			NeutralAHExpired = true,
			NeutralAHOutbid = true,
			NeutralAHSuccess = true,
			NeutralAHWon = true,
			Postmaster = true,
			Attachments = true,
			SpamChat = true,
			KeepFreeSpace = 1,
		},
		Express = {
			EnableAltClick = true,
			AutoSend = true,
			BulkSend = true,
			MouseWheel = true,
			MultiItemTooltip = true,
		},
		BlackBook = {
			AutoFill = true,
			contacts = {},
			recent = {},
			AutoCompleteAlts = true,
			AutoCompleteAllAlts = true,
			AutoCompleteRecent = true,
			AutoCompleteContacts = true,
			AutoCompleteFriends = true,
			AutoCompleteGuild = true,
			ExcludeRandoms = true,
			DisableBlizzardAutoComplete = false,
			UseAutoComplete = true,
		},
		QuickAttach = {
			EnableBag0 = true,
			EnableBag1 = true,
			EnableBag2 = true,
			EnableBag3 = true,
			EnableBag4 = true,
			EnableBag5 = true,
		},
	},
	global = {
		BlackBook = {
			alts = {},
		EnableDefault = false,
		},
	},
}
local _G = getfenv(0)
local t = {}
PostyForeverDB = {}
Postal.keepFreeOptions = {0, 1, 2, 3, 5, 10, 15, 20, 25, 30}

Postal.WOWClassic = false
Postal.WOWBCClassic = false
Postal.WOWWotLKClassic = false
Postal.WOWCataClassic = false
Postal.WOWMists = false
Postal.WOWRetail = false

-- Use a common frame and setup some common functions for the Postal dropdown menus
local Postal_DropDownMenu = CreateFrame("Frame", "Postal_DropDownMenu")
Postal_DropDownMenu.displayMode = "MENU"
Postal_DropDownMenu.info = {}
Postal_DropDownMenu.levelAdjust = 0
Postal_DropDownMenu.UncheckHack = function(dropdownbutton)
	_G[dropdownbutton:GetName().."Check"]:Hide()
	_G[dropdownbutton:GetName().."UnCheck"]:Hide()
end
Postal_DropDownMenu.HideMenu = function()
	if PostyDDM_OPEN_MENU == Postal_DropDownMenu then
		PostyDDM_Close()
	end
end

-- Functions for long subject mouseover
local function subjectHoverIn(self)
	local s = _G["MailItem"..self:GetID().."Subject"]
	if s:GetStringWidth() + 25 > s:GetWidth() then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(s:GetText())
		GameTooltip:Show()
	end
end
local function subjectHoverOut(self)
	GameTooltip:Hide()
end

function Postal:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(eventName, ...)
	local paneType = ...
	if paneType ==  Enum.PlayerInteractionType.MailInfo then Postal:MAIL_CLOSED() end
end

---------------------------
-- Postal Core Functions --
---------------------------

function Postal:OnInitialize()

	--print("Postal is Active and Running");

	-- Detect which release of WOW is running and set appropriate flags
	if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC then Postal.WOWClassic = true end
	if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC then Postal.WOWBCClassic = true end
	if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC then Postal.WOWWotLKClassic = true end
	if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC then Postal.WOWCataClassic = true end
	if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MISTS_CLASSIC then Postal.WOWMists = true end
	if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then Postal.WOWRetail = true end
	if _G.WOW_PROJECT_ID == _G.LE_EXPANSION_11_0 then Postal.WOWRetail = true end
	-- Posty (Forever) : le client se declare "Classic" mais tourne sur le
	-- moteur Retail (API 12.x). On prend donc les chemins de code Retail.
	local build = select(4, GetBuildInfo())
	if build >= 16000 and build < 20000 then
		Postal.WOWForever = true
		Postal.WOWClassic, Postal.WOWBCClassic, Postal.WOWWotLKClassic = false, false, false
		Postal.WOWCataClassic, Postal.WOWMists = false, false
		Postal.WOWRetail = true
	end
--	if Postal.WOWClassic then DEFAULT_CHAT_FRAME:AddMessage("Postal WOW Classic", 0.0, 0.69, 0.94) end
--	if Postal.WOWBCClassic then DEFAULT_CHAT_FRAME:AddMessage("Postal WOW BC Classic", 0.0, 0.69, 0.94) end
--	if Postal.WOWWotLKClassic then DEFAULT_CHAT_FRAME:AddMessage("Postal WOW WotLK Classic", 0.0, 0.69, 0.94) end
--	if Postal.WOWCataClassic then DEFAULT_CHAT_FRAME:AddMessage("Postal WOW Cataclysm Classic", 0.0, 0.69, 0.94) end
--	if Postal.WOWMists then DEFAULT_CHAT_FRAME:AddMessage("Postal WOW Mists Classic", 0.0, 0.69, 0.94) end
--	if Postal.WOWRetail then DEFAULT_CHAT_FRAME:AddMessage("Postal WOW Retail", 0.0, 0.69, 0.94) end
--	if Postal.WOWRetail then DEFAULT_CHAT_FRAME:AddMessage("LE_EXPANSION_11_0", 0.0, 0.69, 0.94) end
	-- Version number
	if not self.version then self.version = C_AddOns.GetAddOnMetadata("Posty_Forever", "Version") end

	-- Anciennes versions de Posty (avant le portage de Postal) : format
	-- incompatible avec AceDB, on repart de zero.
	if type(PostyForeverDB) == "table" and (PostyForeverDB.take or PostyForeverDB.alts) then
		wipe(PostyForeverDB)
	end

	-- Initialize database
	local EnableDefault = false
	if PostyForeverDB and PostyForeverDB.global then
		EnableDefault = PostyForeverDB.global.EnableDefault and true or false
	end
--	if type(next(PostyForeverDB)) ~= "nil" then EnableDefault = PostyForeverDB.global.EnableDefault end
	if EnableDefault == true then
		self.db = LibStub("AceDB-3.0"):New("PostyForeverDB", defaults, true)
	else
		self.db = LibStub("AceDB-3.0"):New("PostyForeverDB", defaults)
	end
--	self.db = LibStub("AceDB-3.0"):New("PostyForeverDB", defaults)
	self:ApplyLanguage()
	-- Forever : AceDB nomme le profil d'un personnage avec UnitName, qui ne
	-- donne que le prenom. "Daeler Backbi" et "Daeler Backbï" partageaient donc
	-- le meme profil (et le meme dernier destinataire). On force un profil
	-- par personnage, avec son nom complet.
	if not EnableDefault then
		local charProfile = self:PlayerName() .. " - " .. (GetRealmName() or "")
		if self.db:GetCurrentProfile() ~= charProfile then
			self.db:SetProfile(charProfile)
		end
	end
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	-- Forever : InboxFrame_Update n'existe pas, on installe le remplacant
	-- avant que les modules ne s'y accrochent.
	self:EnsureInboxUpdate()

	-- Enable/disable modules based on saved settings
	for name, module in self:IterateModules() do
		module:SetEnabledState(self.db.profile.ModuleEnabledState[name] or false)
		if module.OnEnable then
			hooksecurefunc(module, "OnEnable", self.OnModuleEnable_Common) -- Posthook
		end
	end

	-- Register events
	if Postal.WOWBCClassic then
		self:RegisterEvent("MAIL_CLOSED")
	else
		self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
	end

	-- Create the Menu Button
	local Postal_ModuleMenuButton = CreateFrame("Button", "Postal_ModuleMenuButton", MailFrame)
	Postal_ModuleMenuButton:SetWidth(25)
	Postal_ModuleMenuButton:SetHeight(25)
	Postal_ModuleMenuButton:SetPoint("TOPRIGHT", -22, 2)
	if Postal.WOWRetail then Postal_ModuleMenuButton:SetFrameLevel(501) end -- Seems like a Blizzard bug to need this to make Postal menu visible.
	Postal_ModuleMenuButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	Postal_ModuleMenuButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
	Postal_ModuleMenuButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	Postal_ModuleMenuButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	Postal_ModuleMenuButton:SetScript("OnClick", function(self, button, down)
		if Postal_DropDownMenu.initialize ~= Postal.Menu then
			PostyDDM_Close()
			Postal_DropDownMenu.initialize = Postal.Menu
		end
		PostyDDM_Toggle(1, nil, Postal_DropDownMenu, self:GetName(), 0, 0)
	end)
	Postal_ModuleMenuButton:SetScript("OnHide", Postal_DropDownMenu.HideMenu)

	-- Create 7 buttons for mouseover on long subject lines
	for i = 1, 7 do
		local b = CreateFrame("Button", "PostalSubjectHover"..i, _G["MailItem"..i])
		b:SetID(i)
		b:SetAllPoints(_G["MailItem"..i.."Subject"])
		b:SetScript("OnEnter", subjectHoverIn)
		b:SetScript("OnLeave", subjectHoverOut)
	end
	self.OnInitialize = nil
end

-- Langue forcee (menu > Langue) : on remplace les textes par ceux de la langue choisie.
function Postal:ApplyLanguage()
	local lang = self.db.global.Language
	local T = PostyForever_Translations
	if not lang or lang == GetLocale() or not T or not T[lang] then return end
	for k, v in pairs(T.enUS) do rawset(L, k, v) end
	if lang ~= "enUS" then
		for k, v in pairs(T[lang]) do rawset(L, k, v) end
	end
end

Postal.Languages = {
	{ "enUS", "English" }, { "frFR", "Français" }, { "deDE", "Deutsch" },
	{ "esES", "Español" }, { "itIT", "Italiano" }, { "ptBR", "Português" },
	{ "ruRU", "Русский" }, { "koKR", "한국어" }, { "zhCN", "简体中文" }, { "zhTW", "繁體中文" },
}

function Postal.SetLanguage(dropdownbutton, arg1)
	Postal.db.global.Language = arg1
	PostyDDM_Close()
	StaticPopup_Show("POSTAL_RELOAD_LANGUAGE")
end

StaticPopupDialogs["POSTAL_RELOAD_LANGUAGE"] = {
	text = L["Reload the UI to apply the language?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() ReloadUI() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

function Postal:OnProfileChanged(event, database, newProfileKey)
	for name, module in self:IterateModules() do
		if self.db.profile.ModuleEnabledState[name] then
			module:Enable()
		else
			module:Disable()
		end
	end
end

function Postal:OnModuleEnable_Common()
	-- If the module is enabled with the MailFrame open (at mailbox)
	-- run the MAIL_SHOW() event function
	if self.MAIL_SHOW and MailFrame:IsVisible() then
		self:MAIL_SHOW()
	end
end

-- Hides the minimap unread mail button if there are no unread mail on closing the mailbox.
-- Does not scan past the first 100 items since only the first 100 are viewable.
function Postal:MAIL_CLOSED()
	for i = 1, GetInboxNumItems() do
		if not select(9, GetInboxHeaderInfo(i)) then return end
	end
	if Postal.WOWClassic or Postal.WOWBCClassic or Postal.WOWWotLKClassic or Postal.WOWCataClassic or Postal.WOWMists then
		if MiniMapMailFrame then MiniMapMailFrame:Hide() end
	else
		if MiniMapMailFrameMixin and MiniMapMailFrameMixin.OnLeave then pcall(MiniMapMailFrameMixin.OnLeave, MiniMapMailFrameMixin) end
	end
end

function Postal:Print(...)
	local text = "|cff33ff99Posty|r:"
	for i = 1, select("#", ...) do
		text = text.." "..tostring(select(i, ...))
	end

	if not self:IsChatFrameActive(self.db.profile.ChatOutput) then
		self.db.profile.ChatOutput = 1
	end
	local chatFrame = _G["ChatFrame"..self.db.profile.ChatOutput]
	if chatFrame then
		chatFrame:AddMessage(text)
	end
end

function Postal:IsChatFrameActive(i)
	local _, _, _, _, _, _, shown = FCF_GetChatWindowInfo(i);
	local chatFrame = _G["ChatFrame"..i]
	if chatFrame then
		if shown or chatFrame.isDocked then
			return true
		end
	end
	return false
end

function Postal.SaveOption(dropdownbutton, arg1, arg2, checked)
	Postal.db.profile[arg1][arg2] = checked
end

function Postal.ToggleModule(dropdownbutton, arg1, arg2, checked)
	Postal.db.profile.ModuleEnabledState[arg1] = checked
	if checked then arg2:Enable() else arg2:Disable() end
end

function Postal.SetOpenSpeed(dropdownbutton, arg1, arg2, checked)
	Postal.db.profile.OpenSpeed = arg1
end

function Postal.SetChatOutput(dropdownbutton, arg1, arg2, checked)
	Postal.db.profile.ChatOutput = arg1
end

function Postal.EnableDefault(dropdownbutton, arg1, arg2, checked)
	Postal.db.global.EnableDefault = checked
end

function Postal.ProfileFunc(dropdownbutton, arg1, arg2, checked)
	if arg1 == "NewProfile" then
		StaticPopup_Show("POSTAL_NEW_PROFILE")
	else
		Postal.db[arg1](Postal.db, arg2)
	end
	PostyDDM_Close()
end

StaticPopupDialogs["POSTAL_NEW_PROFILE"] = {
	text = L["New Profile Name:"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 128,
	editBoxWidth = 350,  -- Needed in Cata
	OnAccept = function(self)
		Postal.db:SetProfile(strtrim(StaticPopup1EditBox:GetText()))
	end,
	OnShow = function(self)
		StaticPopup1EditBox:SetText(Postal.db:GetCurrentProfile())
		StaticPopup1EditBox:SetFocus()
	end,
	OnHide = StaticPopupDialogs["SET_GUILDPLAYERNOTE"].OnHide,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		Postal.db:SetProfile(strtrim(StaticPopup1EditBox:GetText()))
		parent:Hide()
	end,
	EditBoxOnEscapePressed = StaticPopupDialogs["SET_GUILDPLAYERNOTE"].EditBoxOnEscapePressed,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

function Postal.Menu(self, level)
	if not level then return end
	local info = self.info
	wipe(info)
	if level == 1 then
		info.isTitle = 1
		info.text = "Posty (Forever)"
		info.notCheckable = 1
		PostyDDM_AddButton(info, level)

		info.disabled = nil
		info.isTitle = nil
		info.notCheckable = nil

		info.keepShownOnClick = 1
		info.isNotRadio = 1
		for name, module in Postal:IterateModules() do
			info.text = L[name]
			info.func = Postal.ToggleModule
			info.arg1 = name
			info.arg2 = module
			info.checked = module:IsEnabled()
			info.hasArrow = module.ModuleMenu ~= nil
			info.value = module
			PostyDDM_AddButton(info, level)
		end

		wipe(info)
		info.disabled = 1
		PostyDDM_AddButton(info, level)
		info.disabled = nil

		info.text = L["Opening Speed"]
		info.func = self.UncheckHack
		info.notCheckable = 1
		info.keepShownOnClick = 1
		info.hasArrow = 1
		info.value = "OpenSpeed"
		PostyDDM_AddButton(info, level)

		info.text = L["Chat Output"]
		info.func = self.UncheckHack
		info.notCheckable = 1
		info.keepShownOnClick = 1
		info.hasArrow = 1
		info.value = "ChatOutput"
		PostyDDM_AddButton(info, level)

		info.text = L["Profile"]
		info.func = self.UncheckHack
		info.value = "Profile"
		PostyDDM_AddButton(info, level)

		info.text = L["Language"]
		info.func = self.UncheckHack
		info.value = "Language"
		PostyDDM_AddButton(info, level)

		wipe(info)
		info.notCheckable = 1
		info.text = L["Help"]
		info.func = Postal.About
		PostyDDM_AddButton(info, level)

		info.disabled = 1
		info.text = nil
		info.func = nil
		PostyDDM_AddButton(info, level)

		info.disabled = nil
		info.text = CLOSE
		info.func = self.HideMenu
		info.tooltipTitle = CLOSE
		PostyDDM_AddButton(info, level)

	elseif level == 2 then
		if PostyDDM_MENU_VALUE == "OpenSpeed" then
			local speed = Postal.db.profile.OpenSpeed
			for i = 0, 0 do
				local s = 0
				info.text = format("%0.2f", s)
				info.func = Postal.SetOpenSpeed
				info.checked = s == speed
				info.arg1 = s
				PostyDDM_AddButton(info, level)
			end
			for i = 0, 13 do
				local s = 0.3 + i*0.05
				info.text = format("%0.2f", s)
				info.func = Postal.SetOpenSpeed
				info.checked = s == speed
				info.arg1 = s
				PostyDDM_AddButton(info, level)
			end
			for i = 0, 8 do
				local s = 1 + i*0.5
				info.text = format("%0.2f", s)
				info.func = Postal.SetOpenSpeed
				info.checked = s == speed
				info.arg1 = s
				PostyDDM_AddButton(info, level)
			end

		elseif PostyDDM_MENU_VALUE == "ChatOutput" then
			local selectedFrame = Postal.db.profile.ChatOutput
			for i = 1, NUM_CHAT_WINDOWS do
				if Postal:IsChatFrameActive(i) then
					info.text = format("%d. %s", i, _G["ChatFrame"..i.."Tab"]:GetText())
					info.func = Postal.SetChatOutput
					info.checked = i == selectedFrame
					info.arg1 = i
					PostyDDM_AddButton(info, level)
				end
			end

		elseif PostyDDM_MENU_VALUE == "Language" then
			local current = Postal.db.global.Language
			info.text = L["Client language"]
			info.func = Postal.SetLanguage
			info.arg1 = nil
			info.checked = current == nil
			PostyDDM_AddButton(info, level)
			for _, lang in ipairs(Postal.Languages) do
				info.text = lang[2]
				info.arg1 = lang[1]
				info.checked = current == lang[1]
				PostyDDM_AddButton(info, level)
			end

		elseif PostyDDM_MENU_VALUE == "Profile" then
			-- Profile stuff
			info.hasArrow = 1
			info.keepShownOnClick = 1
			info.func = self.UncheckHack
			info.notCheckable = 1

			info.text = L["Choose"]
			info.value = "SetProfile"
			PostyDDM_AddButton(info, level)

			info.text = L["Copy From"]
			info.value = "CopyProfile"
			PostyDDM_AddButton(info, level)

			info.text = L["Delete"]
			info.value = "DeleteProfile"
			PostyDDM_AddButton(info, level)

			info.hasArrow = nil
			info.keepShownOnClick = nil
			info.func = Postal.ProfileFunc
			info.arg1 = "NewProfile"
			info.text = L["New Profile"]
			PostyDDM_AddButton(info, level)

			info.text = L["Reset Profile"]
			info.func = Postal.ProfileFunc
			info.arg1 = "ResetProfile"
			info.arg2 = nil
			PostyDDM_AddButton(info, level)

			info.keepShownOnClick = 1
			info.isNotRadio = 1
			info.notCheckable = nil
			info.text = L["Default"]
			info.func = Postal.EnableDefault
			info.checked = Postal.db.global.EnableDefault
			PostyDDM_AddButton(info, level)

		elseif type(PostyDDM_MENU_VALUE) == "table" and PostyDDM_MENU_VALUE.ModuleMenu then
			-- Submenus for modules
			self.levelAdjust = 1
			PostyDDM_MENU_VALUE.ModuleMenu(self, level)
			self.levelAdjust = 0
			self.module = PostyDDM_MENU_VALUE
		end

	elseif level == 3 then
		if PostyDDM_MENU_VALUE == "SetProfile" then
			local cur = Postal.db:GetCurrentProfile()
			Postal.db:GetProfiles(t)
			table.sort(t)
			info.func = Postal.ProfileFunc
			info.arg1 = "SetProfile"
			for i = 1, #t do
				local s = t[i]
				info.text = s
				info.arg2 = s
				info.checked = cur == s
				PostyDDM_AddButton(info, level)
			end

		elseif PostyDDM_MENU_VALUE == "CopyProfile" or PostyDDM_MENU_VALUE == "DeleteProfile" then
			local cur = Postal.db:GetCurrentProfile()
			Postal.db:GetProfiles(t)
			table.sort(t)
			info.func = Postal.ProfileFunc
			info.arg1 = PostyDDM_MENU_VALUE
			info.notCheckable = 1
			for i = 1, #t do
				local s = t[i]
				if s ~= cur then
					info.text = s
					info.arg2 = s
					PostyDDM_AddButton(info, level)
				end
			end

		elseif self.module and self.module.ModuleMenu then
			self.levelAdjust = 1
			self.module.ModuleMenu(self, level)
			self.levelAdjust = 0
		end

	elseif level > 3 then
		if self.module and self.module.ModuleMenu then
			self.levelAdjust = 1
			self.module.ModuleMenu(self, level)
			self.levelAdjust = 0
		end

	end
end

function Postal:CreateAboutFrame()
	local aboutFrame = Postal.aboutFrame
	if not aboutFrame and Chatter and ChatterCopyFrame then
		aboutFrame = ChatterCopyFrame
		aboutFrame.editBox = Chatter:GetModule("Chat Copy").editBox
	end
	if not aboutFrame or not aboutFrame.editBox then
		aboutFrame = CreateFrame("Frame", "PostalAboutFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
		tinsert(UISpecialFrames, "PostalAboutFrame")
		aboutFrame:SetBackdrop({
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 3, right = 3, top = 5, bottom = 3 }
		})
		aboutFrame:SetBackdropColor(0,0,0,1)
		aboutFrame:SetWidth(500)
		aboutFrame:SetHeight(400)
		aboutFrame:SetPoint("CENTER", UIParent, "CENTER")
		aboutFrame:Hide()
		aboutFrame:SetFrameStrata("DIALOG")
		aboutFrame:SetToplevel(true)

		local scrollArea = CreateFrame("ScrollFrame", "PostalAboutScroll", aboutFrame, "UIPanelScrollFrameTemplate")
		scrollArea:SetPoint("TOPLEFT", aboutFrame, "TOPLEFT", 8, -30)
		scrollArea:SetPoint("BOTTOMRIGHT", aboutFrame, "BOTTOMRIGHT", -30, 8)

		local editBox = CreateFrame("EditBox", nil, aboutFrame)
		editBox:SetMultiLine(true)
		editBox:SetMaxLetters(99999)
		editBox:EnableMouse(true)
		editBox:SetAutoFocus(false)
		editBox:SetFontObject(ChatFontNormal)
		editBox:SetWidth(400)
		editBox:SetHeight(270)
		editBox:SetScript("OnEscapePressed", function() aboutFrame:Hide() end)
		aboutFrame.editBox = editBox

		scrollArea:SetScrollChild(editBox)

		local close = CreateFrame("Button", nil, aboutFrame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", aboutFrame, "TOPRIGHT")
	end
	Postal.aboutFrame = aboutFrame
	Postal.CreateAboutFrame = nil -- Kill ourselves
end

function Postal.About()
	if Postal.CreateAboutFrame then Postal:CreateAboutFrame() end
	local version = C_AddOns.GetAddOnMetadata("Posty_Forever", "Version")
	wipe(t)
	tinsert(t, "|cFFFFCC00"..C_AddOns.GetAddOnMetadata("Posty_Forever", "Title").." v"..version.."|r")
	tinsert(t, "-----")
	tinsert(t, "")
	for name, module in Postal:IterateModules() do
		tinsert(t, "|cffffcc00"..L[name].."|r")
		if module.description then
			tinsert(t, module.description)
		end
		if module.description2 then
			tinsert(t, "")
			tinsert(t, module.description2)
		end
		tinsert(t, "")
	end
	tinsert(t, "-----")
	tinsert(t, L["Please post bugs or suggestions at the CurseForge forums thread at |cFF00FFFFhttp://www.curseforge.com/wow/addons/postal/issues|r. When posting bugs, indicate your locale and Postal's version number v%s."]:format(version))
	tinsert(t, "")
	tinsert(t, "- Xinhuan (Blackrock/Barthilas US Alliance)")
	tinsert(t, "")
	Postal.aboutFrame.editBox:SetText(table.concat(t, "\n"))
	Postal.aboutFrame:Show()
	wipe(t) -- For garbage collection
end

---------------------------
-- Common Mail Functions --
---------------------------

-- Sur Forever, les personnages ont un prenom ET un nom ("Daeler Backbi").
-- UnitName ne renvoie que le prenom : deux personnages au meme prenom se
-- confondaient. UnitFullName renvoie le nom complet.
-- Sur Forever, la fonction globale InboxFrame_Update de Blizzard peut
-- manquer : les hooks de Select et DoNotWant plantaient ("Attempting to hook
-- a non existing target"). On la remplace alors par une fonction vide, que
-- Posty appelle lui-meme quand la boite de reception change.
function Postal:EnsureInboxUpdate()
	if type(_G.InboxFrame_Update) == "function" then return end
	_G.InboxFrame_Update = function() end
	if Postal.inboxUpdateDriver then return end
	local function run()
		if InboxFrame and InboxFrame:IsVisible() then _G.InboxFrame_Update() end
	end
	local function later() C_Timer.After(0, run) end
	local driver = CreateFrame("Frame")
	pcall(driver.RegisterEvent, driver, "MAIL_INBOX_UPDATE")
	driver:SetScript("OnEvent", later)
	if InboxFrame then InboxFrame:HookScript("OnShow", later) end
	if InboxPrevPageButton then InboxPrevPageButton:HookScript("OnClick", later) end
	if InboxNextPageButton then InboxNextPageButton:HookScript("OnClick", later) end
	Postal.inboxUpdateDriver = driver
end

-- UnitName("player") renvoie alors le prenom et le nom de famille en deux
-- valeurs .
function Postal:PlayerName()
	local name, surname = UnitName("player")
	if surname and surname ~= "" and RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
		local sep = Constants and Constants.CharacterNameSeparatorConsts
			and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or " "
		return name .. sep .. surname
	end
	return name
end

-- "Royaume" regional sur Forever : le jeu de regles
-- (PvP, RP, HC, PvE), et non le nom du serveur.
function Postal:RegionalRealm()
	if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() and C_GameRules and Enum.GameRule then
		local rules = C_GameRules.IsGameRuleActive
		if Enum.GameRule.PvPRuleset and rules(Enum.GameRule.PvPRuleset) then return "PvP" end
		if Enum.GameRule.RPRuleset and rules(Enum.GameRule.RPRuleset) then return "RP" end
		if Enum.GameRule.HardcoreRuleset and rules(Enum.GameRule.HardcoreRuleset) then return "HC" end
		return "PvE"
	end
	local _, realm = UnitFullName("player")
	if (not realm or realm == "") and GetNormalizedRealmName then realm = GetNormalizedRealmName() end
	return realm
end

-- Disable Inbox Clicks
local function noop() end
function Postal:DisableInbox(disable)
	if disable then
		if not self:IsHooked("InboxFrame_OnClick") then
			self:RawHook("InboxFrame_OnClick", noop, true)
			for i = 1, 7 do
				_G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(true)
			end
		end
	else
		if self:IsHooked("InboxFrame_OnClick") then
			self:Unhook("InboxFrame_OnClick")
			for i = 1, 7 do
				_G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(false)
			end
		end
	end
end

-- Return the type of mail a message subject is
local SubjectPatterns = {
	AHCancelled = gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*"),
	AHExpired = gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*"),
	AHOutbid = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*"),
	AHSuccess = gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*"),
	AHWon = gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*"),
}
function Postal:GetMailType(msgSubject)
	if msgSubject then
		for k, v in pairs(SubjectPatterns) do
			if msgSubject:find(v) then return k end
		end
	end
	return "NonAHMail"
end

function Postal:GetMoneyString(money)
	local gold = floor(money / 10000)
	local silver = floor((money - gold * 10000) / 100)
	local copper = mod(money, 100)
	if gold > 0 then
		return format(GOLD_AMOUNT_TEXTURE.." "..SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0)
	elseif silver > 0 then
		return format(SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, silver, 0, 0, copper, 0, 0)
	else
		return format(COPPER_AMOUNT_TEXTURE, copper, 0, 0)
	end
end

function Postal:GetMoneyStringPlain(money)
	local gold = floor(money / 10000)
	local silver = floor((money - gold * 10000) / 100)
	local copper = mod(money, 100)
	if gold > 0 then
		return gold..GOLD_AMOUNT_SYMBOL.." "..silver..SILVER_AMOUNT_SYMBOL.." "..copper..COPPER_AMOUNT_SYMBOL
	elseif silver > 0 then
		return silver..SILVER_AMOUNT_SYMBOL.." "..copper..COPPER_AMOUNT_SYMBOL
	else
		return copper..COPPER_AMOUNT_SYMBOL
	end
end

function Postal:CountItemsAndMoney()
	local numAttach = 0
	local numGold = 0
	for i = 1, GetInboxNumItems() do
		local msgMoney, _, _, msgItem = select(5, GetInboxHeaderInfo(i))
		numAttach = numAttach + (msgItem or 0)
		numGold = numGold + msgMoney
	end
	return numAttach, numGold
end
