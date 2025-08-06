local addonName, addon = ...

addon.searchFrame:RegisterEvent("WORLD_MAP_OPEN")

function addon.searchFrame:WORLD_MAP_OPEN(mapId)
	addon:SetSearchButtonLocation(mapId)
end

function addon:OpenMap(mapId)
    C_Map.OpenWorldMap(mapId)
end

function addon:SetSearchButtonLocation(mapId)
	local mapGroupID = C_Map.GetMapGroupID(mapId);
	if not mapGroupID then
		addon.searchFrame:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, 0, 0)
		return
	end

	local mapGroupMembersInfo = C_Map.GetMapGroupMembersInfo(mapGroupID);
	if not mapGroupMembersInfo then
		addon.searchFrame:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, 0, 0)
		return
	end

	addon.searchFrame:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, 0, -24)
end

addon:SetSearchButtonLocation(C_Map.GetBestMapForUnit("player"))