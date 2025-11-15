--=============================================================================
-- AutoLFM: Minimap Button
--   Minimap button management
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Components = AutoLFM.Components or {}
AutoLFM.Components.MinimapButton = {}

--=============================================================================
-- PUBLIC API
--=============================================================================

-----------------------------------------------------------------------------
-- Reset Minimap Button Position
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.ResetPosition()
    local button = getglobal("AutoLFM_MinimapButton")
    if button then
        button:ClearAllPoints()
        button:SetPoint("LEFT", Minimap, "LEFT", 16, -68)
        if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogInfo then
            AutoLFM.Components.DebugWindow.LogInfo("Minimap button position reset")
        end
    end
end

--=============================================================================
-- EVENT HANDLERS
--=============================================================================

function AutoLFM.Components.MinimapButton.OnClick(button, mouseButton)
    if mouseButton == "LeftButton" then
        AutoLFM.Core.Maestro.Dispatch("UI.Toggle")
    elseif mouseButton == "RightButton" and IsControlKeyDown() then
        AutoLFM.Core.Maestro.Dispatch("Minimap.Reset")
    end
end

function AutoLFM.Components.MinimapButton.OnDragStop(button)
    -- Save position if needed in the future
end

function AutoLFM.Components.MinimapButton.OnEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Auto|cff0070DDL|r|cffffffffF|r|cffff0000M")
    GameTooltip:AddLine("Left-click to open main window.", 1, 1, 1)
    GameTooltip:AddLine("Hold control and drag to move.", 1, 1, 1)
    GameTooltip:AddLine("Hold control and right-click to reset position.", 1, 1, 1)
    GameTooltip:Show()
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

AutoLFM.Core.Maestro.RegisterInit("Minimap", function()
    -- Register commands
    AutoLFM.Core.Maestro.RegisterCommand("Minimap.Reset", AutoLFM.Components.MinimapButton.ResetPosition)
end)
