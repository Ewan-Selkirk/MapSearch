local _, addon = ...

MapSearchButtonMixin = {}

function MapSearchButtonMixin:OnClick(button, down)
	if button == "RightButton" then
		addon.searchFrame.settingsFrame:SetShown(not addon.searchFrame.settingsFrame:IsShown())
		if addon.searchFrame.settingsFrame:IsShown() and addon.searchFrame.scrollContainer:IsShown() then
			addon.searchFrame.searchBar:Hide()
			addon.searchFrame.scrollContainer:Hide()
			addon.searchFrame.scrollBar:Hide()
			self.ActiveTexture:SetShown(addon.searchFrame.searchBar:IsShown());
		end
		return
	end

	addon.searchFrame.searchBar:SetShown(not addon.searchFrame.searchBar:IsShown())
	addon.searchFrame.scrollContainer:SetShown(addon.searchFrame.searchBar:IsShown())

	if not addon.searchFrame.searchBar:IsShown() then
		addon.searchFrame.scrollBar:Hide()
	else
		if addon.searchFrame.settingsFrame:IsShown() then
			addon.searchFrame.settingsFrame:Hide()
		end
	end

	self.ActiveTexture:SetShown(addon.searchFrame.searchBar:IsShown());
end

function MapSearchButtonMixin:OnEnter()
	GameTooltip:SetOwner(self, (select(4, GetBuildInfo()) == 50500) and "ANCHOR_BOTTOM" or "ANCHOR_TOP")
	GameTooltip:AddLine("Search for Map", 1, 1, 1)
	GameTooltip:AddLine("Player Location ID: ".. tostring(C_Map.GetBestMapForUnit("player")), 1.0, 0.82, 0.0)

	if C_Map.GetBestMapForUnit("player") ~= WorldMapFrame.mapID then
		GameTooltip:AddLine("Map Location ID: " .. tostring(WorldMapFrame.mapID), 1.0, 0.82, 0.0)
	end

	GameTooltip:AddLine("\nRight Click to view settings", 1, 1, 1, true)

	GameTooltip:Show()
end

function MapSearchButtonMixin:OnMouseDown(button)
	if self:IsShown() then
		self.Icon:SetPoint("TOPLEFT", 8, -8)
	end
end

function MapSearchButtonMixin:OnMouseUp()
	self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 7, -6);
	self.IconOverlay:Hide();
end