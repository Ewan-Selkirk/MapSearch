local addonName, addon = ...

local sort = {byId = 0, byName = 1}
local locationData = {}

-- I don't think there is an API for accessing all the map locations so for now lets brute force it :)
for i=1,3000 do
	if C_Map.GetMapInfo(i) ~= nil then
		table.insert(locationData, C_Map.GetMapInfo(i))
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

local ScrollView = CreateScrollBoxListLinearView()
local searchFrame = CreateFrame("Frame", "MapSearch", WorldMapFrame)

searchFrame:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, 0, -24)
searchFrame:SetFrameStrata("HIGH")
searchFrame:SetSize(165, 29 + 205)

searchFrame:RegisterEvent("PLAYER_MAP_CHANGED")
searchFrame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

searchFrame.searchButton = CreateFrame("Button", "MapSearchIcon", WorldMapFrame)
searchFrame.searchBar = CreateFrame("EditBox", "MapSearchBar", WorldMapFrame, "SearchBoxTemplate")
searchFrame.scrollContainer = CreateFrame("Frame", "MapSearchScroll", WorldMapFrame, "WowScrollBoxList")
searchFrame.scrollBar = CreateFrame("EventFrame", "MapSearchScrollBar", WorldMapFrame, "MinimalScrollBar")

function searchFrame:PLAYER_MAP_CHANGED(oldMap, newMap)
	-- print(oldMap, newMap)
end

function searchFrame.searchButton:CVAR_UPDATE(cvar, value)
	if (cvar == "miniWorldMap") then
		-- print("CVAR Updated:", cvar, value)
	end
end

local function changeSearchIcon()
	searchFrame.searchButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" .. (not searchFrame.searchBar:IsShown() and "Up" or "Down"))
end

function searchFrame.searchBar:ZONE_CHANGED_NEW_AREA()
	-- print("Zone Changed!")
end

searchFrame.searchButton:SetSize(29, 29)
searchFrame.searchButton:SetPoint("LEFT", searchFrame)
searchFrame.searchButton:SetPoint("TOP", searchFrame, "TOP")
-- searchFrame.searchButton:SetPoint("TOPRIGHT", WorldMapFrame.ScrollContainer, "TOPRIGHT", -4, -34 - 32)
searchFrame.searchButton:SetFrameStrata("HIGH")

searchFrame.searchButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:AddLine("Search for Map", 1.0, 0.82, 0.0)
	GameTooltip:AddLine("Player Location ID: ".. tostring(C_Map.GetBestMapForUnit("player")), 1, 1, 1)

	if C_Map.GetBestMapForUnit("player") ~= WorldMapFrame.mapID then
		GameTooltip:AddLine("Map Location ID: " .. tostring(WorldMapFrame.mapID), 1, 1, 1)
	end

	GameTooltip:Show()
end)

searchFrame.searchButton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

searchFrame.searchButton:SetScript("OnClick", function(self)
	searchFrame.searchBar:SetShown(not searchFrame.searchBar:IsShown())
	searchFrame.scrollContainer:SetShown(not searchFrame.scrollContainer:IsShown())
	changeSearchIcon()
end)

searchFrame.searchButton:RegisterEvent("CVAR_UPDATE")
searchFrame.searchButton:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

-- searchFrame.searchBar:SetPoint("CENTER", searchFrame, 1, 3)
searchFrame.searchBar:SetPoint("RIGHT", searchFrame, "RIGHT")
searchFrame.searchBar:SetPoint("LEFT", searchFrame.searchButton, 30, 0)
searchFrame.searchBar:SetPoint("TOP", searchFrame, "TOP")
searchFrame.searchBar:SetAutoFocus(false)
searchFrame.searchBar:SetWidth(searchFrame:GetWidth() - searchFrame.searchButton:GetWidth() - 2)
searchFrame.searchBar:SetHeight(searchFrame.searchButton:GetHeight())
searchFrame.searchBar:SetFrameStrata("HIGH")
searchFrame.searchBar:Hide()
changeSearchIcon()

searchFrame.searchBar:RegisterEvent("ZONE_CHANGED_NEW_AREA")
searchFrame.searchBar:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

for i=1,#locationData do
	searchFrame.searchBar:AddHistoryLine(tostring(locationData[i].mapID), "-", locationData[i].name)
end

searchFrame.searchBar:SetScript("OnTextChanged", function(self, ...)
	-- print(self:GetText())
	SearchBoxTemplate_OnTextChanged(self)
	local data = CreateDataProvider()

	if self:GetText() == "" then
		-- Do Nothing
	elseif tonumber(self:GetText()) ~= nil then
		-- Search by ID
		local searchResults = {}
		for i=1,#locationData do
			if string.find(locationData[i].mapID, self:GetText()) then
				table.insert(searchResults, locationData[i])
				data:Insert(locationData[i])
			end
		end
	else
		-- Search by Name
		local searchResults = {}
		for i=1,#locationData do
			if string.find(string.lower(locationData[i].name), string.lower(self:GetText())) then
				table.insert(searchResults, locationData[i])
				data:Insert(locationData[i])
			end
		end

		-- print("Searching for:", self:GetText())
		-- for i=1,#searchResults do
		-- 	-- print(searchResults[i].name, "-", tostring(searchResults[i].mapID))
		-- 	searchFrame.searchBar:AddHistoryLine(searchResults[i].name, "-", tostring(searchResults[i].mapID))
		-- 	DataProvider:Insert(searchResults[i])
		-- end

	end

	-- data:Insert({name = "This is an example of a really long name. Hopefully this works", mapID = 100, mapType = 3})

	ScrollView:SetDataProvider(data)
end)

searchFrame.searchBar:HookScript("OnEnterPressed", function(self)
	if tonumber(self:GetText()) ~= nil then
		C_Map.OpenWorldMap(tonumber(self:GetText()))
		local m = locationData[tonumber(self:GetText())]
		print("Opening map:", m.name, m.mapID)
	else
		self:GetText()
	end
	self:ClearFocus()
	self:SetText("")
end)

searchFrame.searchBar:SetScript("OnEscapePressed", function(self)
	self:SetText("")
	self:ClearFocus()
	self:Hide()
	searchFrame.scrollContainer:Hide()
	changeSearchIcon()
end)

searchFrame.scrollContainer:SetSize(searchFrame:GetWidth(), searchFrame:GetHeight() - 35)
searchFrame.scrollContainer:SetPoint("TOPLEFT", searchFrame.searchButton, "BOTTOMLEFT", 0, 0)
searchFrame.scrollContainer:SetPoint("BOTTOMRIGHT", searchFrame, "BOTTOMRIGHT")
searchFrame.scrollContainer:SetFrameStrata("HIGH")
searchFrame.scrollContainer:Hide()

searchFrame.scrollBar:SetPoint("TOPLEFT", searchFrame.scrollContainer, "TOPRIGHT")
searchFrame.scrollBar:SetPoint("BOTTOMLEFT", searchFrame.scrollContainer, "BOTTOMRIGHT")
searchFrame.scrollBar:SetHideIfUnscrollable(true)

ScrollUtil.InitScrollBoxListWithScrollBar(searchFrame.scrollContainer, searchFrame.scrollBar, ScrollView)

local function CreateSearchItem(button, data)
	local locName = data.name
	local locId = data.mapID
	local locType = data.mapType

	button:SetScript("OnClick", function()
		C_Map.OpenWorldMap(locId)
		searchFrame.searchBar:SetText("")
		searchFrame.searchBar:ClearFocus()
		searchFrame.searchBar:Hide()
		searchFrame.scrollContainer:Hide()
		changeSearchIcon()

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

-- /run for k,v in pairs(WorldMapFrame.ScrollContainer.Child) do print(k,v) end