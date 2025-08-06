local addonName, addon = ...

local sort = {byId = 0, byName = 1}
local maxLocations = 3000
local locationData = {}
local searchResults = {}

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

local ScrollView = CreateScrollBoxListLinearView()
addon.searchFrame = CreateFrame("Frame", "MapSearch", WorldMapFrame)

addon.searchFrame:SetFrameStrata("HIGH")
addon.searchFrame:SetSize(165, 35 + 205)

addon.searchFrame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

addon.searchFrame.searchButton = CreateFrame("Button", "MapSearchIcon", WorldMapFrame, "MapSearchButtonTemplate")
addon.searchFrame.searchBar = CreateFrame("EditBox", "MapSearchBar", WorldMapFrame, "SearchBoxTemplate")
addon.searchFrame.scrollContainer = CreateFrame("Frame", "MapSearchScroll", WorldMapFrame, "WowScrollBoxList")
addon.searchFrame.scrollBar = CreateFrame("EventFrame", "MapSearchScrollBar", WorldMapFrame, "MinimalScrollBar")

addon.searchFrame.searchButton:SetPoint("LEFT", addon.searchFrame)
addon.searchFrame.searchButton:SetPoint("TOP", addon.searchFrame, "TOP")

addon.searchFrame.searchBar:SetPoint("RIGHT", addon.searchFrame, "RIGHT")
addon.searchFrame.searchBar:SetPoint("LEFT", addon.searchFrame.searchButton, 38, 0)
addon.searchFrame.searchBar:SetPoint("TOP", addon.searchFrame, "TOP")
addon.searchFrame.searchBar:SetAutoFocus(false)
addon.searchFrame.searchBar:SetWidth(addon.searchFrame:GetWidth() - addon.searchFrame.searchButton:GetWidth() - 2)
addon.searchFrame.searchBar:SetHeight(addon.searchFrame.searchButton:GetHeight())
addon.searchFrame.searchBar:SetFrameStrata("HIGH")
addon.searchFrame.searchBar:Hide()

addon.searchFrame.searchBar:SetScript("OnTextChanged", function(self, ...)
	SearchBoxTemplate_OnTextChanged(self)
	local data = CreateDataProvider()
	searchResults = {}

	if self:GetText() == "" then
		-- Do Nothing
	elseif tonumber(self:GetText()) ~= nil then
		-- Search by ID
		for i=1,maxLocations do
			if locationData[i] ~= nil then
				if string.find(locationData[i].mapID, self:GetText()) then
					table.insert(searchResults, locationData[i])
					data:Insert(locationData[i])
				end
			end
		end
	else
		-- Search by Name
		for i=1,maxLocations do
			if locationData[i] ~= nil then
				if string.find(string.lower(locationData[i].name), string.lower(self:GetText())) then
					table.insert(searchResults, locationData[i])
					data:Insert(locationData[i])
				end
			end
		end
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