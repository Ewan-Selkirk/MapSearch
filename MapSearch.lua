local addonName, addon = ...

local sortType = {byId = 0, byName = 1}
local maxLocations = 5000
local locationData = {}
local searchResults = {}

local defaultSettings = {
	useSorting = true,
	sort = sortType.byName,
	filters = {					-- <Based on Enum.UIMapType>
		true, 					-- Cosmic
		true,					-- World
		true,					-- Continent
		true,					-- Zone
		true,					-- Dungeon
		true,					-- Micro
		false					-- Orphan
	}
}

-- I don't think there is an API for accessing all the map locations so for now lets brute force it :)
for i=1,maxLocations do
	if C_Map.GetMapInfo(i) ~= nil then
		locationData[i] =  C_Map.GetMapInfo(i)
	end
end

local function GetMapTypeFromEnum(value)
	for k,v in pairs(Enum.UIMapType) do
		if v == value then
			return k
		end
	end

	return nil
end

local function sortSearchResults(results)
	table.sort(results, function(a, b)
		if MapSearchSettings.sort == sortType.byId then
			return a.mapID < b.mapID
		elseif MapSearchSettings.sort == sortType.byName then
			return a.name < b.name
		else
			return false
		end
	end)
end

local ScrollView = CreateScrollBoxListLinearView()
addon.searchFrame = CreateFrame("Frame", "MapSearch", WorldMapFrame)

addon.searchFrame:SetFrameStrata("HIGH")
addon.searchFrame:SetSize(165, 35 + 205)
addon.searchFrame:RegisterEvent("ADDON_LOADED")

addon.searchFrame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function addon.searchFrame:ADDON_LOADED(a)
	if a ~= addonName then return end

	-- Check if there is already a config or create a new one.
	-- If one already exists, check that there aren't any missing values
	if not MapSearchSettings then
		MapSearchSettings = defaultSettings
	else
		-- Add missing settings
		for k, v in pairs(defaultSettings) do
			if not MapSearchSettings[k] then MapSearchSettings[k] = v end
		end

		-- Remove any unnecessary settings (not working at the moment. Oh well, doesn't really matter ¯\_(ツ)_/¯ )
		-- local i = 1
		-- for k, v in pairs(MapSearchSettings) do
		-- 	if not defaultSettings[k] then table.remove(MapSearchSettings, i) end
		-- 	i = i + 1
		-- end
	end

	-- Create sort toggle checkbox
	local sortToggle = CreateFrame("CheckButton", "MapSearchSettings_SortToggle", addon.searchFrame.settingsFrame, "ChatConfigCheckButtonTemplate")
	sortToggle:SetPoint("TOPLEFT", addon.searchFrame.settingsFrame, "TOPLEFT", 12, -46)
	sortToggle:SetChecked(MapSearchSettings["useSorting"])
	sortToggle.Text:SetText("Enable Sorting")
	sortToggle:HookScript("OnClick", function()
		MapSearchSettings["useSorting"] = not MapSearchSettings["useSorting"]
		MapSearchSettings_SortName:SetEnabled(MapSearchSettings["useSorting"] and MapSearchSettings["sort"] ~= sortType.byName)
		MapSearchSettings_SortId:SetEnabled(MapSearchSettings["useSorting"] and MapSearchSettings["sort"] ~= sortType.byId)
	end)

	-- Create filter checkboxes
	for k, v in pairs(Enum.UIMapType) do
		local f = CreateFrame("CheckButton", "MapSearchSettings_Filter" .. k, addon.searchFrame.settingsFrame, "ChatConfigCheckButtonTemplate")
		f:SetPoint("TOPLEFT", addon.searchFrame.settingsFrame, "TOPLEFT", 12, -112 - 24 * (v + 1))
		f:SetChecked(MapSearchSettings["filters"][v + 1])
		f.Text:SetText("Show " .. k)

		f:HookScript("OnClick", function ()
			MapSearchSettings["filters"][v + 1] = not MapSearchSettings["filters"][v + 1]
		end)
	end

	-- Disable sort buttons based on the current sort type
	MapSearchSettings_SortName:SetEnabled(MapSearchSettings["useSorting"] and MapSearchSettings["sort"] ~= sortType.byName)
	MapSearchSettings_SortId:SetEnabled(MapSearchSettings["useSorting"] and MapSearchSettings["sort"] ~= sortType.byId)
end

addon.searchFrame.searchButton = CreateFrame("Button", "MapSearchIcon", WorldMapFrame, "MapSearchButtonTemplate")
addon.searchFrame.searchBar = CreateFrame("EditBox", "MapSearchBar", WorldMapFrame, "SearchBoxTemplate")
addon.searchFrame.scrollContainer = CreateFrame("Frame", "MapSearchScroll", WorldMapFrame, "WowScrollBoxList")
addon.searchFrame.scrollBar = CreateFrame("EventFrame", "MapSearchScrollBar", WorldMapFrame, "MinimalScrollBar")
addon.searchFrame.settingsFrame = CreateFrame("Frame", "MapSearchSettings", WorldMapFrame, "MapSearchSettingsFrame")

addon.searchFrame.searchButton:SetPoint("LEFT", addon.searchFrame)
addon.searchFrame.searchButton:SetPoint("TOP", addon.searchFrame, "TOP")
addon.searchFrame.searchButton:RegisterForClicks("AnyUp")

addon.searchFrame.searchBar:SetPoint("RIGHT", addon.searchFrame, "RIGHT")
addon.searchFrame.searchBar:SetPoint("LEFT", addon.searchFrame.searchButton, 38, 0)
addon.searchFrame.searchBar:SetPoint("TOP", addon.searchFrame, "TOP")
addon.searchFrame.searchBar:SetAutoFocus(false)
addon.searchFrame.searchBar:SetWidth(addon.searchFrame:GetWidth() - addon.searchFrame.searchButton:GetWidth() - 2)
addon.searchFrame.searchBar:SetHeight(addon.searchFrame.searchButton:GetHeight())
addon.searchFrame.searchBar:SetFrameStrata("HIGH")
addon.searchFrame.searchBar:Hide()

addon.searchFrame.searchBar:HookScript("OnTextChanged", function(self, ...)
	-- SearchBoxTemplate_OnTextChanged(self)
	local data = CreateDataProvider()
	searchResults = {}

	if self:GetText() == "" then
		-- Do Nothing
	elseif tonumber(self:GetText()) ~= nil then
		-- Search by ID
		for i=1,maxLocations do
			if locationData[i] ~= nil then
				if string.find(locationData[i].mapID, self:GetText(), 1, true) then
					if MapSearchSettings["filters"][locationData[i].mapType + 1] then
						table.insert(searchResults, locationData[i])
					end
				end
			end
		end
	else
		-- Search by Name
		for i=1,maxLocations do
			if locationData[i] ~= nil then
				if string.find(string.lower(locationData[i].name), string.lower(self:GetText()), 1, true) then
					if MapSearchSettings["filters"][locationData[i].mapType + 1] then
						table.insert(searchResults, locationData[i])
					end
				end
			end
		end
	end

	if MapSearchSettings.useSorting then sortSearchResults(searchResults) end

	for i=1,#searchResults do
		data:Insert(searchResults[i])
	end
	ScrollView:SetDataProvider(data)
end)

addon.searchFrame.searchBar:SetScript("OnEnterPressed", function(self)
	if tonumber(self:GetText()) ~= nil then
		local num = tonumber(self:GetText())
		addon:OpenMap(num)

		local m = locationData[num]
		print("Opening map:", m.name, m.mapID)
	else
		if #searchResults ~= 0 then
			addon:OpenMap(searchResults[1].mapID)
			print("Opening map:", searchResults[1].name, searchResults[1].mapID)
		end
	end
	self:ClearFocus()
	self:SetText("")
	self:Hide()
	addon.searchFrame.scrollContainer:Hide()
	addon.searchFrame.searchButton.ActiveTexture:SetShown(addon.searchFrame.scrollContainer:IsShown());

	ScrollView:SetDataProvider(CreateDataProvider())
end)

addon.searchFrame.searchBar:SetScript("OnEscapePressed", function(self)
	self:SetText("")
	self:ClearFocus()
	self:Hide()
	addon.searchFrame.scrollContainer:Hide()
	addon.searchFrame.searchButton.ActiveTexture:SetShown(addon.searchFrame.scrollContainer:IsShown());
end)

addon.searchFrame.scrollContainer:SetSize(addon.searchFrame:GetWidth(), addon.searchFrame:GetHeight() - 35)
addon.searchFrame.scrollContainer:SetPoint("TOPLEFT", addon.searchFrame.searchButton, "BOTTOMLEFT", 0, 0)
addon.searchFrame.scrollContainer:SetPoint("BOTTOMRIGHT", addon.searchFrame, "BOTTOMRIGHT")
addon.searchFrame.scrollContainer:SetFrameStrata("HIGH")
addon.searchFrame.scrollContainer:Hide()

addon.searchFrame.scrollBar:SetPoint("TOPLEFT", addon.searchFrame.scrollContainer, "TOPRIGHT")
addon.searchFrame.scrollBar:SetPoint("BOTTOMLEFT", addon.searchFrame.scrollContainer, "BOTTOMRIGHT")
addon.searchFrame.scrollBar:SetHideIfUnscrollable(true)

addon.searchFrame.settingsFrame:SetSize(150, 300)
addon.searchFrame.settingsFrame:SetPoint("TOPLEFT", addon.searchFrame.searchButton, "BOTTOMLEFT")
addon.searchFrame.settingsFrame:SetPoint("RIGHT", addon.searchFrame, "RIGHT")
addon.searchFrame.settingsFrame:Hide()

ScrollUtil.InitScrollBoxListWithScrollBar(addon.searchFrame.scrollContainer, addon.searchFrame.scrollBar, ScrollView)

local function CreateSearchItem(button, data)
	local locName = data.name
	local locId = data.mapID
	local locType = data.mapType

	button:SetScript("OnClick", function()
		addon:OpenMap(locId)
		addon.searchFrame.searchBar:SetText("")
		addon.searchFrame.searchBar:ClearFocus()
		addon.searchFrame.searchBar:Hide()
		addon.searchFrame.scrollContainer:Hide()
		addon.searchFrame.searchButton.ActiveTexture:SetShown(false);

		ScrollView:SetDataProvider(CreateDataProvider())
	end)

	button:SetText(locName .. " (" .. tostring(locId) .. ")")

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, -(self:GetHeight() / 2))

		GameTooltip:AddLine("Details")
		GameTooltip:AddLine("Type: " .. GetMapTypeFromEnum(locType))


		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end

ScrollView:SetElementInitializer("UIPanelButtonTemplate", CreateSearchItem)

WorldMapFrame:HookScript("OnShow", function (...)
	print("World Map Opened!")
	addon:SetSearchButtonLocation(C_Map.GetBestMapForUnit("player"))
end, LE_SCRIPT_BINDING_TYPE_INTRINSIC_POSTCALL)

hooksecurefunc(MapCanvasMixin, "OnMapChanged", function(...)
	addon:SetSearchButtonLocation(WorldMapFrame.mapID)
end)

-- /run for k,v in pairs(WorldMapFrame.ScrollContainer.Child) do print(k,v) end