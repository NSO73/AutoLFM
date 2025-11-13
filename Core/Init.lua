--=============================================================================
-- AutoLFM: Initialization
--   Event-driven addon initialization using self-registration system
--=============================================================================

-----------------------------------------------------------------------------
-- Event Registration
-----------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    -- Phase 1: Load persistent data first
    if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.Init then
      AutoLFM.Core.Persistent.Init()
    end

    -- Phase 2: Initialize Maestro state (loads saved tab preference)
    if AutoLFM.Core.Maestro and AutoLFM.Core.Maestro.Init then
      AutoLFM.Core.Maestro.Init()
    end

    -- Phase 3: Run all registered init handlers (register commands & load state)
    -- At this point Persistent is ready, so modules can safely load their state
    AutoLFM.Core.Maestro.RunInit()

    initFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
  end
end)
