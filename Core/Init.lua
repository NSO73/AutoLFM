--=============================================================================
-- AutoLFM: Initialization
--   Main initialization system
--=============================================================================

--=============================================================================
-- WOW EVENT HANDLING
--=============================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    AutoLFM.Core.Maestro.RunInit()
    initFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
