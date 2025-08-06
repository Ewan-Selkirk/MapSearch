local addonName, addon = ...

addon.searchFrame:RegisterEvent("CVAR_UPDATE")

function addon.searchFrame:CVAR_UPDATE(event, ...)
    if event == "miniWorldMap" then
        addon:SetSearchButtonLocation(nil)
    end
end

function addon:SetSearchButtonLocation(...)
    if tonumber(C_CVar.GetCVar("miniWorldMap")) == 1 then
        addon.searchFrame:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 24, -24)
    else
        addon.searchFrame:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 12, -32)
    end
end

function addon:OpenMap(mapId)
    WorldMapFrame:SetMapID(mapId)
end