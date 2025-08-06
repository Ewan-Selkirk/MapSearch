local addonName, addon = ...

function addon:SetSearchButtonLocation(mapId)
    addon.searchFrame:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 24, -24)
end

function addon:OpenMap(mapId)
    WorldMapFrame:SetMapID(mapId)
end