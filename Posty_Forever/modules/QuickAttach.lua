local Postal = LibStub("AceAddon-3.0"):GetAddon("Posty_Forever")
local Postal_QuickAttach = Postal:NewModule("QuickAttach", "AceHook-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Posty_Forever")
Postal_QuickAttach.description = L["Allows you to quickly attach different trade items types to a mail."]
Postal_QuickAttach.description2 = L[ [[|cFFFFCC00*|r A default recipient name can be specified by right clicking on a button.
|cFFFFCC00*|r Which bags are used by this feature can be set in the main menu.]] ]
-- Trade Goods supported itemType for C_Item.GetItemInfo() by WoW release version
-- Classic: Trade Goods(0), Reagent(5, 0)
-- BCC: Cloth(5), Leather(6), Metal & Stone(7), Meat(8), Herb(9), Enchanting(12), Jewelcrafting(4), Parts(1), Elemental(10), Devices(3), Explosives(2), Materials(13), Other(11)
-- Shadowlands: Cloth(5), Leather(6), Metal & Stone(7), Cooking(8), Herb(9), Enchanting(12), Inscription(16), Jewelcrafting(4), Parts(1), Elemental(10), Optional Reagents(18), Other(11)
local QAButtonPos = 0 -- Needed due to lack of static variables in lua
local QAButtonCol = 0 -- Colonne courante des boutons
local QAButtonMaxRows = 12 -- Nombre max de boutons par colonne
local QAButtonDialogInfo = "" -- Name|classID|subclassID
local QAButtons

-- Set a button's GameTooltip
local function SetQAButtonGameTooltip(button, toolTip)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetText(toolTip,1,1,1,1,true)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

-- Create QuickAttach button
local function CreateQAButton(name, texture, classID, subclassID, toolTip)
	local ofsxBase, ofsyBase, ofsyGap = 0, 0, 0
	local scale = 0.73 -- gives good results for classic and retail
	local TempButton, QAButtonCharName
	TempButton = CreateFrame("Button", name, SendMailFrame, "ActionButtonTemplate")
	local buttonHeight = math.floor(TempButton:GetHeight() + 0.5)
	local buttonWidth = math.floor(TempButton:GetWidth() + 0.5)
	TempButton:SetScale(scale)
	TempButton.icon:SetTexture(texture)
	TempButton:ClearAllPoints()
	-- Securite : passe a la colonne suivante si la colonne depasse la hauteur du courrier
	if QAButtonPos >= QAButtonMaxRows then
		QAButtonCol = QAButtonCol + 1
		QAButtonPos = 0
	end
	TempButton:SetPoint("TOPLEFT", "MailFrame", "TOPRIGHT", ofsxBase + (buttonWidth + 2) * QAButtonCol, ofsyBase - (buttonHeight + ofsyGap) * QAButtonPos)
	TempButton:RegisterForClicks("AnyUp")
	TempButton:SetScript("OnClick", function(self, button, down) Postal_QuickAttachButtonClick(button, classID, subclassID) end)
	TempButton:SetFrameLevel(TempButton:GetFrameLevel() + 1)
	QAButtonCharName = Postal_QuickAttachGetQAButtonCharName(classID, subclassID)
	if QAButtonCharName ~= "" then toolTip = toolTip.."\n"..L["Default recipient:"].." "..QAButtonCharName end
	SetQAButtonGameTooltip(TempButton, toolTip)
	QAButtonPos = QAButtonPos + 1
end

-- Hide QuickAttach Buttons
local function Postal_QuickAttachHideButtons()
	local i, name
	for i = 1, #QAButtons, 1 do
		name = "Postal_QuickAttachButton"..tostring(i)
		if _G[name] then _G[name]:Hide() end
	end
end

-- Show QuickAttach Buttons
local function Postal_QuickAttachShowButtons()
	local i, name
	for i = 1, #QAButtons, 1 do
		name = "Postal_QuickAttachButton"..tostring(i)
		if _G[name] then _G[name]:Show() end
	end
end

-- Create QuickAttach buttons and hook OnClick events
function Postal_QuickAttach:OnEnable()
	if not Postal_QuickAttachButton1 then
		QAButtons = {}
		if Postal.WOWForever then
			-- Forever, colonne 1 : tous les objets d'artisanat en un bouton, puis
			-- un bouton par type de materiau (voir ForeverTradeGoods), et les composants.
			table.insert(QAButtons, {"Postal_QuickAttachButton1", "Interface/Icons/Ability_Ensnare", 7, -1, L["Trade Goods"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton2", "Interface/Icons/INV_Fabric_Linen_01", 7, 5, L["Cloth"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton3", "Interface/Icons/INV_Misc_LeatherScrap_03", 7, 6, L["Leather"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton4", "Interface/Icons/INV_Ore_Copper_01", 7, 7, L["Metal & Stone"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton5", "Interface/Icons/INV_Misc_Herb_07", 7, 9, L["Herb"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton6", "Interface/Icons/INV_Misc_Food_14", 7, 8, L["Cooking"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton7", "Interface/Icons/INV_Enchant_DustStrange", 7, 12, L["Enchanting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton8", "Interface/Icons/INV_Elemental_Primal_Air", 7, 10, L["Elemental"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton9", "Interface/Icons/INV_Gizmo_BronzeFramework_01", 7, 1, L["Parts"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton10", "Interface/Icons/INV_Misc_Rune_09", 7, 11, L["Other"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton11", "Interface/Icons/inv_misc_food_02", 5, 0, L["Reagent"]})
			-- Colonne 2 : equipement et autres categories (seuls les objets non lies sont joints).
			table.insert(QAButtons, {"Postal_QuickAttachButton12", "Interface/Icons/INV_Sword_04", 2, -1, L["Unbound weapons"], true})
			table.insert(QAButtons, {"Postal_QuickAttachButton13", "Interface/Icons/INV_Chest_Chain", 4, -1, L["Unbound armor"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton14", "Interface/Icons/INV_Potion_51", 0, -1, L["Consumables"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton15", "Interface/Icons/INV_Scroll_03", 9, -1, L["Recipes"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton16", "Interface/Icons/INV_Misc_Bag_09", 1, -1, L["Bags"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton17", "Interface/Icons/INV_Misc_Gem_Ruby_01", 3, -1, L["Gems"]})
		elseif Postal.WOWClassic == true then
			table.insert(QAButtons, {"Postal_QuickAttachButton1", GetSpellTexture(2018), 7, 0, L["Trade Goods"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton2", "Interface/Icons/inv_misc_food_02", 5, 0, L["Reagent"]})
		end
		if Postal.WOWBCClassic == true then
			table.insert(QAButtons, {"Postal_QuickAttachButton1", GetSpellTexture(3908), 7, 5, L["Cloth"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton2", GetSpellTexture(2108), 7, 6, L["Leather"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton3", GetSpellTexture(2656), 7, 7, L["Metal & Stone"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton4", GetSpellTexture(2550), 7, 8, L["Cooking"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton5", GetSpellTexture(2383), 7, 9, L["Herb"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton6", GetSpellTexture(7411), 7, 12, L["Enchanting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton7", GetSpellTexture(25229), 7, 4, L["Jewelcrafting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton8", "Interface/Icons/INV_Gizmo_FelIronCasing", 7, 1, L["Parts"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton9", "Interface/Icons/INV_Elemental_Primal_Air", 7, 10, L["Elemental"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton10", "Interface/Icons/inv_gizmo_goblingtonkcontroller", 7, 3, L["Devices"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton11", "Interface/Icons/INV_Misc_Ammo_Gunpowder_01", 7, 2, L["Explosives"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton12", "Interface/Icons/INV_Misc_Rune_09", 7, 11, L["Other"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton13", "Interface/Icons/Ability_Ensnare", 7, -1, L["Trade Goods"]})
		end
		if Postal.WOWWotLKClassic == true then
			table.insert(QAButtons, {"Postal_QuickAttachButton1", GetSpellTexture(3908), 7, 5, L["Cloth"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton2", GetSpellTexture(2108), 7, 6, L["Leather"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton3", GetSpellTexture(2656), 7, 7, L["Metal & Stone"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton4", GetSpellTexture(2550), 7, 8, L["Cooking"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton5", GetSpellTexture(2383), 7, 9, L["Herb"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton6", GetSpellTexture(7411), 7, 12, L["Enchanting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton7", GetSpellTexture(25229), 7, 4, L["Jewelcrafting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton8", "Interface/Icons/INV_Gizmo_FelIronCasing", 7, 1, L["Parts"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton9", "Interface/Icons/INV_Elemental_Primal_Air", 7, 10, L["Elemental"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton10", "Interface/Icons/inv_gizmo_goblingtonkcontroller", 7, 3, L["Devices"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton11", "Interface/Icons/INV_Misc_Ammo_Gunpowder_01", 7, 2, L["Explosives"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton12", "Interface/Icons/INV_Elemental_Primal_Nether", 7, 13, L["Materials"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton13", "Interface/Icons/INV_Misc_Rune_09", 7, 11, L["Other"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton14", 237050, 7, 14, L["Armor Enchantment"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton15", 237172, 7, 15, L["Weapon Enchantment"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton16", "Interface/Icons/Ability_Ensnare", 7, -1, L["Trade Goods"]})
		end
		if Postal.WOWCataClassic == true then
			table.insert(QAButtons, {"Postal_QuickAttachButton1", GetSpellTexture(3908), 7, 5, L["Cloth"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton2", GetSpellTexture(2108), 7, 6, L["Leather"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton3", GetSpellTexture(2656), 7, 7, L["Metal & Stone"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton4", GetSpellTexture(2550), 7, 8, L["Cooking"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton5", GetSpellTexture(2383), 7, 9, L["Herb"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton6", GetSpellTexture(7411), 7, 12, L["Enchanting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton7", GetSpellTexture(25229), 7, 4, L["Jewelcrafting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton8", "Interface/Icons/INV_Gizmo_FelIronCasing", 7, 1, L["Parts"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton9", "Interface/Icons/INV_Elemental_Primal_Air", 7, 10, L["Elemental"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton10", "Interface/Icons/inv_gizmo_goblingtonkcontroller", 7, 3, L["Devices"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton11", "Interface/Icons/INV_Misc_Ammo_Gunpowder_01", 7, 2, L["Explosives"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton12", "Interface/Icons/INV_Elemental_Primal_Nether", 7, 13, L["Materials"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton13", "Interface/Icons/INV_Misc_Rune_09", 7, 11, L["Other"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton14", 237050, 7, 14, L["Item Enchantment"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton15", "Interface/Icons/Ability_Ensnare", 7, -1, L["Trade Goods"]})
		end
		if Postal.WOWMists == true then
			table.insert(QAButtons, {"Postal_QuickAttachButton1", GetSpellTexture(3908), 7, 5, L["Cloth"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton2", GetSpellTexture(2108), 7, 6, L["Leather"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton3", GetSpellTexture(2656), 7, 7, L["Metal & Stone"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton4", GetSpellTexture(2550), 7, 8, L["Cooking"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton5", GetSpellTexture(2383), 7, 9, L["Herb"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton6", GetSpellTexture(7411), 7, 12, L["Enchanting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton7", GetSpellTexture(25229), 7, 4, L["Jewelcrafting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton8", "Interface/Icons/INV_Gizmo_FelIronCasing", 7, 1, L["Parts"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton9", "Interface/Icons/INV_Elemental_Primal_Air", 7, 10, L["Elemental"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton10", "Interface/Icons/inv_gizmo_goblingtonkcontroller", 7, 3, L["Devices"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton11", "Interface/Icons/INV_Misc_Ammo_Gunpowder_01", 7, 2, L["Explosives"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton12", "Interface/Icons/INV_Elemental_Primal_Nether", 7, 13, L["Materials"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton13", "Interface/Icons/INV_Misc_Rune_09", 7, 11, L["Other"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton14", 237050, 7, 14, L["Item Enchantment"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton15", "Interface/Icons/Ability_Ensnare", 7, -1, L["Trade Goods"]})
		end
		if Postal.WOWRetail == true and not Postal.WOWForever then
--			table.insert(QAButtons, {"Postal_QuickAttachButton1", GetSpellTexture(3908), 7, 5, L["Cloth"]})
--			table.insert(QAButtons, {"Postal_QuickAttachButton2", GetSpellTexture(2108), 7, 6, L["Leather"]})
--			table.insert(QAButtons, {"Postal_QuickAttachButton3", GetSpellTexture(2656), 7, 7, L["Metal & Stone"]})
--			table.insert(QAButtons, {"Postal_QuickAttachButton4", GetSpellTexture(2550), 7, 8, L["Cooking"]})
--			table.insert(QAButtons, {"Postal_QuickAttachButton5", GetSpellTexture(2383), 7, 9, L["Herb"]})
--			table.insert(QAButtons, {"Postal_QuickAttachButton6", GetSpellTexture(7411), 7, 12, L["Enchanting"]})
--			table.insert(QAButtons, {"Postal_QuickAttachButton7", GetSpellTexture(45357), 7, 16, L["Inscription"]})
--			table.insert(QAButtons, {"Postal_QuickAttachButton8", GetSpellTexture(25229), 7, 4, L["Jewelcrafting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton1", 4620681, 7, 5, L["Cloth"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton2", 4620678, 7, 6, L["Leather"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton3", 4625105, 7, 7, L["Metal & Stone"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton4", 4620671, 7, 8, L["Cooking"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton5", 133939, 7, 9, L["Herb"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton6", 4620672, 7, 12, L["Enchanting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton7", 4620676, 7, 16, L["Inscription"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton8", 4620677, 7, 4, L["Jewelcrafting"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton9", "Interface/Icons/INV_Gizmo_FelIronCasing", 7, 1, L["Parts"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton10", "Interface/Icons/INV_Elemental_Primal_Air", 7, 10, L["Elemental"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton11", "Interface/Icons/INV_Bijou_Green", 7, 18, L["Optional Reagents"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton12", "Interface/Icons/INV_Misc_Rune_09", 7, 11, L["Other"]})
			table.insert(QAButtons, {"Postal_QuickAttachButton13", "Interface/Icons/Ability_Ensnare", 7, -1, L["Trade Goods"]})
		end
		for i = 1, #QAButtons, 1 do
			if QAButtons[i][6] and QAButtonPos > 0 then
				-- Debut d'une nouvelle colonne
				QAButtonCol = QAButtonCol + 1
				QAButtonPos = 0
			end
			CreateQAButton(QAButtons[i][1], QAButtons[i][2], QAButtons[i][3], QAButtons[i][4], QAButtons[i][5])
		end
	end
	Postal_QuickAttachShowButtons()
end

-- Disabling modules unregisters all events/hook automatically
function Postal_QuickAttach:OnDisable()
	Postal_QuickAttach:UnregisterAllEvents()
	Postal_QuickAttachHideButtons()
end

-- Outils de metier classes comme armes : jamais joints par le bouton Armes
local ProfessionTools = {
	[2901] = true,  -- Pioche de mineur
	[7005] = true,  -- Couteau a depecer
	[5956] = true,  -- Marteau de forgeron
	[6219] = true,  -- Cle plate
	[778] = true,   -- Pioche Kobold
	[1959] = true,  -- Pioche de mineur des Kobolds
	[756] = true,   -- Pioche du tunnelier
	[12709] = true, -- Couteau d'ecorcheur de Finkle
	[19901] = true, -- Couteau d'ecorchage zulien
}
-- Forever : materiaux d'artisanat vanilla par itemID -> sous-classe du bouton.
-- Sert de secours quand le client renvoie la sous-classe 0 (donnees vanilla,
-- tout est "Fournitures generales"). Si le client renvoie une vraie sous-classe,
-- elle est utilisee directement.
local ForeverTradeGoods = {}
local function AddTradeGoods(subclassID, ids)
	for _, id in ipairs(ids) do ForeverTradeGoods[id] = subclassID end
end
-- Tissu (5) : tissus, rouleaux, fils, soies d'araignee
AddTradeGoods(5, {2589, 2592, 4306, 4338, 14047, 14256, 14227, 2996, 2997, 4305, 4339, 14048, 14342,
	2320, 2321, 4291, 8343, 14341, 3182, 4337, 10285})
-- Cuir (6) : cuirs, peaux, ecailles
AddTradeGoods(6, {2934, 2318, 2319, 4234, 4304, 8170, 783, 4232, 4235, 8169, 8171, 4231, 4233, 4236, 8172, 15407,
	15417, 15416, 15412, 15414, 15415, 15408, 8154, 15410, 17012, 12810, 15419, 15422, 15423, 7286, 7392,
	5784, 5785, 6470, 6471, 8165, 7428, 4461, 19767, 19768, 20498, 20500, 20501})
-- Metal et pierre (7) : minerais, barres, pierres, pierres a aiguiser, gemmes
AddTradeGoods(7, {2770, 2771, 2772, 2775, 2776, 3858, 7911, 10620, 11370, 18562,
	2840, 3576, 2841, 3575, 2842, 3577, 3859, 3860, 6037, 12359, 11371, 12360, 17771,
	2835, 2836, 2838, 7912, 12365, 3470, 3478, 3486, 7966, 12644, 22202, 22203,
	818, 774, 1210, 1206, 1705, 1529, 3864, 7909, 7910, 12361, 12799, 12800, 12364, 12363,
	7971, 13926, 5498, 5500})
-- Cuisine (8) : viandes, oeufs, epices
AddTradeGoods(8, {769, 2672, 2673, 2674, 2675, 2677, 2924, 3173, 3685, 3667, 3712, 3730, 3731, 1015, 723, 729,
	730, 731, 1468, 1080, 1081, 5465, 5467, 5468, 5469, 5470, 5471, 5503, 5504, 7974, 3404, 4655, 12037,
	12184, 12202, 12203, 12204, 12205, 12206, 12207, 12208, 20424, 6889, 2251, 2678, 2692, 3713})
-- Herbes (9)
AddTradeGoods(9, {765, 2447, 785, 2449, 2450, 2452, 2453, 3355, 3356, 3357, 3358, 3369, 3818, 3819, 3820, 3821,
	4625, 8831, 8836, 8838, 8839, 8845, 8846, 13463, 13464, 13465, 13466, 13467, 13468, 19726})
-- Elementaire (10)
AddTradeGoods(10, {7067, 7068, 7069, 7070, 7075, 7076, 7077, 7078, 7079, 7080, 7081, 7082, 7972, 12808, 12803,
	12809, 17010, 17011, 18512, 12662, 20520, 12811})
-- Enchantement (12) : poussieres, essences, eclats
AddTradeGoods(12, {10940, 11083, 11137, 11176, 16204, 10938, 10939, 10998, 11082, 11134, 11135, 11174, 11175,
	16202, 16203, 10978, 11084, 11138, 11139, 11177, 11178, 14343, 14344, 20725})
-- Pieces d'ingenierie (1) : poudres, boulons, tubes, mecanismes
AddTradeGoods(1, {4357, 4364, 4377, 10505, 15992, 4359, 4371, 4375, 4382, 4387, 4389, 4399, 4400, 4404,
	10558, 10559, 10560, 10561, 16000, 15994})

-- Sous-classes modernes regroupees sur les boutons Forever
local ForeverSubclassRemap = {
	[2] = 1,   -- Explosifs -> Pieces
	[3] = 1,   -- Appareils -> Pieces
	[4] = 7,   -- Joaillerie -> Metal et pierre
	[13] = 11, -- Materiaux -> Autre
	[16] = 11, -- Calligraphie -> Autre
	[18] = 11, -- Composants optionnels -> Autre
}

-- Sous-classe d'un materiau telle que l'utilisent les boutons Forever
local function GetForeverTradeGoodsSubclass(itemID, itemsubclassID)
	if not itemsubclassID or itemsubclassID == 0 then
		return ForeverTradeGoods[itemID] or 11
	end
	return ForeverSubclassRemap[itemsubclassID] or itemsubclassID
end

local function IsProfessionTool(itemID, classID, subclassID)
	if ProfessionTools[itemID] then return true end
	-- Cannes a peche (sous-classe 20)
	return classID == 2 and subclassID == 20
end

-- Return how many free item slots are in the current send mail
local function SendMailNumberOfFreeSlots()
	local itemIndex, NumberOfFreeSlots
	NumberOfFreeSlots = ATTACHMENTS_MAX_SEND
	for itemIndex = 1, ATTACHMENTS_MAX_SEND do
		if HasSendMailItem(itemIndex) then
			NumberOfFreeSlots = NumberOfFreeSlots - 1
		end
	end
	return NumberOfFreeSlots
end

-- Take an action based on a QuickAttach button click
function Postal_QuickAttachButtonClick(button, classID, subclassID)
	if (button ==  "LeftButton") then Postal_QuickAttachLeftButtonClick(classID, subclassID) end
	if (button ==  "RightButton") then Postal_QuickAttachRightButtonClick(classID, subclassID) end
end

-- Attach as many items as possible of the specified type to the current send mail.
function Postal_QuickAttachLeftButtonClick(classID, subclassID)
	local bagID, bindType, itemclassID, itemID, itemsubclassID, locked, numberOfSlots, slot, slotIndex
	local name = Postal_QuickAttachGetQAButtonCharName(classID, subclassID)
	if name ~= "" then
		SendMailNameEditBox:SetText(name)
		SendMailNameEditBox:HighlightText()
	end
	local bagIDmax = NUM_BAG_FRAMES
	if Postal.WOWRetail then
		bagIDmax = bagIDmax + (NUM_REAGENTBAG_FRAMES or 0)
	end
	for bagID = 0, bagIDmax, 1 do
		if (bagID == 0) and Postal.db.profile.QuickAttach.EnableBag0 or
			(bagID == 1) and Postal.db.profile.QuickAttach.EnableBag1 or
			(bagID == 2) and Postal.db.profile.QuickAttach.EnableBag2 or
			(bagID == 3) and Postal.db.profile.QuickAttach.EnableBag3 or
			(bagID == 4) and Postal.db.profile.QuickAttach.EnableBag4 or
			(bagID == 5) and Postal.db.profile.QuickAttach.EnableBag5
		then
			if Postal.WOWBCClassic then
				numberOfSlots = GetContainerNumSlots(bagID)
			else
				numberOfSlots = C_Container.GetContainerNumSlots(bagID)
			end
			for slotIndex = 1, numberOfSlots, 1 do
				if Postal.WOWBCClassic then
					locked = select(3, GetContainerItemInfo(bagID, slotIndex))
				else
					if C_Container and C_Container.GetContainerItemInfo(bagID, slotIndex) then
						local itemInfo = C_Container.GetContainerItemInfo(bagID, slotIndex)
						locked = itemInfo.isLocked
					else
						locked = false
					end
				end
				if locked == false then
					if Postal.WOWBCClassic then
						itemID = select(10, GetContainerItemInfo(bagID, slotIndex))
					else
						if C_Container and C_Container.GetContainerItemInfo(bagID, slotIndex) then
							local itemInfo = C_Container.GetContainerItemInfo(bagID, slotIndex)
							itemID = itemInfo.itemID
							-- Objet deja lie (ex. BoE equipe) : impossible a envoyer
							if itemInfo.isBound then itemID = nil end
						else
							itemID = nil
						end
					end
					if itemID then
						bindType = select(14, C_Item.GetItemInfo(itemID))
						if bindType ~= 	LE_ITEM_BIND_ON_ACQUIRE then
							itemclassID = select(12, C_Item.GetItemInfo(itemID))
							if itemclassID == classID then
								itemsubclassID = select(13, C_Item.GetItemInfo(itemID))
								if Postal.WOWForever and classID == 7 and subclassID ~= -1 then
									itemsubclassID = GetForeverTradeGoodsSubclass(itemID, itemsubclassID)
								end
								if (itemsubclassID == subclassID or subclassID == -1) and not (classID == 2 and IsProfessionTool(itemID, itemclassID, itemsubclassID)) then
										if SendMailNumberOfFreeSlots() > 0 then
											if Postal.WOWBCClassic then
												PickupContainerItem(bagID, slotIndex)
											else
												C_Container.PickupContainerItem(bagID, slotIndex)
											end
											ClickSendMailItemButton()
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Set the default recipient name to be filled in for the specified type.
function Postal_QuickAttachRightButtonClick(classID, subclassID)
	local name = Postal_QuickAttachGetQAButtonCharName(classID, subclassID)
	QAButtonDialogInfo = name.."|"..classID.."|"..subclassID
	StaticPopup_Show("POSTAL_QUICKATTACH_CHARACTER_NAME")
end

-- Check if a default character name for the specified type has been set and return it.
function Postal_QuickAttachGetQAButtonCharName(classID, subclassID)
	local db = Postal.db.profile
	if not (db.QuickAttach) then return "" end
	if not (db.QuickAttach.QAbuttons) then return "" end
	db = Postal.db.profile.QuickAttach.QAbuttons
	for i = #db, 1, -1 do
		local n, c, s = strsplit("|", db[i])
		if tonumber(c) == tonumber(classID) and tonumber(s) == tonumber(subclassID) then
			return n
		end
	end
	return ""
end

-- Set and store a default character name for the specified type.
local function Postal_QuickAttachSetQAButtonCharName(name, classID, subclassID)
	local db = Postal.db.profile
	local buttonString = ("%s|%s|%s"):format(name, classID, subclassID)
	if not (db.QuickAttach) then db.QuickAttach = {} end
	if not (db.QuickAttach.QAbuttons) then db.QuickAttach.QAbuttons = {} end
	db = Postal.db.profile.QuickAttach.QAbuttons
	for i = #db, 1, -1 do
		local n, c, s = strsplit("|", db[i])
		if tonumber(c) == tonumber(classID) and tonumber(s) == tonumber(subclassID) then
			tremove(db, i)
		end
	end
	if name ~= "" then tinsert(db, buttonString) end
	table.sort(db)
	if #db == 0 then wipe(Postal.db.profile.QuickAttach) end
	for i = 1, #QAButtons, 1 do
		local c, s, t = QAButtons[i][3], QAButtons[i][4], QAButtons[i][5]
		if tonumber(c) == tonumber(classID) and tonumber(s) == tonumber(subclassID) then
			if name ~= "" then t = t.."\n"..L["Default recipient:"].." "..name end
			SetQAButtonGameTooltip(_G[QAButtons[i][1]], t)
		end
	end	
end

-- Define static popup for default character name dialog.
StaticPopupDialogs["POSTAL_QUICKATTACH_CHARACTER_NAME"] = {
	text = L["Default recipient:"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 128,
	editBoxWidth = 350,  -- Needed in Cata
	OnAccept = function(self)
		local name, classID, subclassID = strsplit("|", QAButtonDialogInfo)
		name = strtrim(StaticPopup1EditBox:GetText())
		Postal_QuickAttachSetQAButtonCharName(name, classID, subclassID)	
	end,
	OnShow = function(self)
		local name, classID, subclassID = strsplit("|", QAButtonDialogInfo)
		StaticPopup1EditBox:SetText(name)
		StaticPopup1EditBox:HighlightText()
		StaticPopup1EditBox:SetFocus()
	end,
	OnHide = StaticPopupDialogs["SET_GUILDPLAYERNOTE"].OnHide,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		local name, classID, subclassID = strsplit("|", QAButtonDialogInfo)
		name = strtrim(StaticPopup1EditBox:GetText())
		Postal_QuickAttachSetQAButtonCharName(name, classID, subclassID)	
		parent:Hide()
	end,
	EditBoxOnEscapePressed = StaticPopupDialogs["SET_GUILDPLAYERNOTE"].EditBoxOnEscapePressed,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

-- Creat QuickAttach Menu
function Postal_QuickAttach.ModuleMenu(self, level)
	if not level then return end
	local info = self.info
	wipe(info)
	info.isNotRadio = 1
	if level == 1 + self.levelAdjust then
		local db = Postal.db.profile.QuickAttach
		info.keepShownOnClick = 1

		info.text = L["Enable for backpack"]
		info.func = Postal.SaveOption
		info.arg1 = "QuickAttach"
		info.arg2 = "EnableBag0"
		info.checked = Postal.db.profile.QuickAttach.EnableBag0
		PostyDDM_AddButton(info, level)

		info.text = L["Enable for bag one"]
		info.func = Postal.SaveOption
		info.arg1 = "QuickAttach"
		info.arg2 = "EnableBag1"
		info.checked = Postal.db.profile.QuickAttach.EnableBag1
		PostyDDM_AddButton(info, level)

		info.text = L["Enable for bag two"]
		info.func = Postal.SaveOption
		info.arg1 = "QuickAttach"
		info.arg2 = "EnableBag2"
		info.checked = Postal.db.profile.QuickAttach.EnableBag2
		PostyDDM_AddButton(info, level)

		info.text = L["Enable for bag three"]
		info.func = Postal.SaveOption
		info.arg1 = "QuickAttach"
		info.arg2 = "EnableBag3"
		info.checked = Postal.db.profile.QuickAttach.EnableBag3
		PostyDDM_AddButton(info, level)

		info.text = L["Enable for bag four"]
		info.func = Postal.SaveOption
		info.arg1 = "QuickAttach"
		info.arg2 = "EnableBag4"
		info.checked = Postal.db.profile.QuickAttach.EnableBag4
		PostyDDM_AddButton(info, level)

		if Postal.WOWRetail then
			info.text = L["Enable for reagent bag"]
			info.func = Postal.SaveOption
			info.arg1 = "QuickAttach"
			info.arg2 = "EnableBag5"
			info.checked = Postal.db.profile.QuickAttach.EnableBag5
			PostyDDM_AddButton(info, level)
		end
	end
end
