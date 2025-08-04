MapSearchButtonMixin = {}

function MapSearchButtonMixin:OnClick()
	MapSearchBar:SetShown(not MapSearchBar:IsShown())
	MapSearchScroll:SetShown(MapSearchBar:IsShown())

	self.ActiveTexture:SetShown(MapSearchBar:IsShown());
end

function MapSearchButtonMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:AddLine("Search for Map", 1, 1, 1)
	GameTooltip:AddLine("Player Location ID: ".. tostring(C_Map.GetBestMapForUnit("player")), 1.0, 0.82, 0.0)

	if C_Map.GetBestMapForUnit("player") ~= WorldMapFrame.mapID then
		GameTooltip:AddLine("Map Location ID: " .. tostring(WorldMapFrame.mapID), 1.0, 0.82, 0.0)
	end

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