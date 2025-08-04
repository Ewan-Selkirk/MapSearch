local addonName, addon = ...

local sort = {byId = 0, byName = 1}
local locationData = {}
local searchResults = {}

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

searchFrame:SetFrameStrata("HIGH")
searchFrame:SetSize(165, 29 + 205)

function searchFrame:SetSearchButtonLocation(mapId)
	-- This function works, but finding the right places to call it is iffy.
	-- For now, keep the search button below the group selector and figure it out later

	-- local mapGroupID = C_Map.GetMapGroupID(mapId);
	-- if not mapGroupID then
	-- 	self:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, 0, 0)
	-- 	return
	-- end

	-- local mapGroupMembersInfo = C_Map.GetMapGroupMembersInfo(mapGroupID);
	-- if not mapGroupMembersInfo then
	-- 	self:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, 0, 0)
	-- 	return
	-- end

	self:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, 0, -24)
end
searchFrame:SetSearchButtonLocation(C_Map.GetBestMapForUnit("player"))

searchFrame:RegisterEvent("PLAYER_MAP_CHANGED")
-- searchFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
searchFrame:RegisterEvent("WORLD_MAP_OPEN")
searchFrame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function searchFrame:PLAYER_MAP_CHANGED(oldMap, newMap)
	-- Currently isn't working right now for some reason...
	-- Will figure it out another time :(
	print("Player moved from zone: " .. oldMap .. " to new zone: " .. newMap)
	searchFrame:SetSearchButtonLocation(newMap)
end

function searchFrame:ZONE_CHANGED_NEW_AREA()
	searchFrame:SetSearchButtonLocation(C_Map.GetBestMapForUnit("player"))
end

function searchFrame:WORLD_MAP_OPEN(mapId)
	searchFrame:SetSearchButtonLocation(mapId)
end

searchFrame.searchButton = CreateFrame("Button", "MapSearchIcon", WorldMapFrame, "MapSearchButtonTemplate")
searchFrame.searchBar = CreateFrame("EditBox", "MapSearchBar", WorldMapFrame, "SearchBoxTemplate")
searchFrame.scrollContainer = CreateFrame("Frame", "MapSearchScroll", WorldMapFrame, "WowScrollBoxList")
searchFrame.scrollBar = CreateFrame("EventFrame", "MapSearchScrollBar", WorldMapFrame, "MinimalScrollBar")

searchFrame.searchButton:SetPoint("LEFT", searchFrame)
searchFrame.searchButton:SetPoint("TOP", searchFrame, "TOP")

searchFrame.searchBar:SetPoint("RIGHT", searchFrame, "RIGHT")
searchFrame.searchBar:SetPoint("LEFT", searchFrame.searchButton, 38, 0)
searchFrame.searchBar:SetPoint("TOP", searchFrame, "TOP")
searchFrame.searchBar:SetAutoFocus(false)
searchFrame.searchBar:SetWidth(searchFrame:GetWidth() - searchFrame.searchButton:GetWidth() - 2)
searchFrame.searchBar:SetHeight(searchFrame.searchButton:GetHeight())
searchFrame.searchBar:SetFrameStrata("HIGH")
searchFrame.searchBar:Hide()

-- searchFrame.searchBar:RegisterEvent("ZONE_CHANGED_NEW_AREA")
searchFrame.searchBar:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

searchFrame.searchBar:SetScript("OnTextChanged", function(self, ...)
	SearchBoxTemplate_OnTextChanged(self)
	local data = CreateDataProvider()
	searchResults = {}

	if self:GetText() == "" then
		-- Do Nothing
	elseif tonumber(self:GetText()) ~= nil then
		-- Search by ID
		for i=1,#locationData do
			if string.find(locationData[i].mapID, self:GetText()) then
				table.insert(searchResults, locationData[i])
				data:Insert(locationData[i])
			end
		end
	else
		-- Search by Name
		for i=1,#locationData do
			if string.find(string.lower(locationData[i].name), string.lower(self:GetText())) then
				table.insert(searchResults, locationData[i])
				data:Insert(locationData[i])
			end
		end
	end

	ScrollView:SetDataProvider(data)
end)

searchFrame.searchBar:SetScript("OnEnterPressed", function(self)
	if tonumber(self:GetText()) ~= nil then
		C_Map.OpenWorldMap(tonumber(self:GetText()))
		local m = locationData[tonumber(self:GetText())]
		print("Opening map:", m.name, m.mapID)
	else
		if #searchResults ~= 0 then
			C_Map.OpenWorldMap(searchResults[1].mapID)
		end
	end
	self:ClearFocus()
	self:SetText("")
	self:Hide()
	searchFrame.scrollContainer:Hide()
	searchFrame.searchButton.ActiveTexture:SetShown(searchFrame.scrollContainer:IsShown());
end)

searchFrame.searchBar:SetScript("OnEscapePressed", function(self)
	self:SetText("")
	self:ClearFocus()
	self:Hide()
	searchFrame.scrollContainer:Hide()
	searchFrame.searchButton.ActiveTexture:SetShown(searchFrame.scrollContainer:IsShown());
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
		searchFrame.searchButton.ActiveTexture:SetShown(false);

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