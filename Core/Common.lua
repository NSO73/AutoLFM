--=============================================================================
-- AutoLFM: Common
--   Shared constants and utility functions for the addon
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Common = {}

--=============================================================================
-- CONSTANTS
--=============================================================================

-----------------------------------------------------------------------------
-- Colors
-----------------------------------------------------------------------------
AutoLFM.Core.Common.COLORS = {
    {name = "GOLD", priority = 99, r = 1.0, g = 0.82, b = 0.0, hex = "FFD100"},
    {name = "WHITE", priority = 99, r = 1.0, g = 1.0, b = 1.0, hex = "FFFFFF"},
    {name = "GRAY", priority = 5, r = 0.5, g = 0.5, b = 0.5, hex = "808080"},
    {name = "GREEN", priority = 1, r = 0.25, g = 0.75, b = 0.25, hex = "40BF40"},
    {name = "YELLOW", priority = 2, r = 1.0, g = 1.0, b = 0.0, hex = "FFFF00"},
    {name = "ORANGE", priority = 3, r = 1.0, g = 0.5, b = 0.25, hex = "FF8040"},
    {name = "RED", priority = 4, r = 1.0, g = 0.0, b = 0.0, hex = "FF0000"},
    {name = "BLUE", priority = 99, r = 0.0, g = 0.67, b = 1.0, hex = "00AAFF"},
    {name = "CYAN", priority = 99, r = 0.0, g = 1.0, b = 1.0, hex = "00FFFF"},
    {name = "PURPLE", priority = 99, r = 0.67, g = 0.0, b = 1.0, hex = "AA00FF"}
}

--=============================================================================
-- HELPERS
--=============================================================================

-----------------------------------------------------------------------------
-- Get Color by Name
-----------------------------------------------------------------------------
function AutoLFM.Core.Common.GetColor(colorName)
    for i = 1, table.getn(AutoLFM.Core.Common.COLORS) do
        if AutoLFM.Core.Common.COLORS[i].name == colorName then
            return AutoLFM.Core.Common.COLORS[i]
        end
    end
    return nil
end

-----------------------------------------------------------------------------
-- Chat Functions
-----------------------------------------------------------------------------
local PREFIX = "|cff808080[|r|cffffffffAuto|r|cff0070ddL|r|cffffffffF|r|cffff0000M|r|cff808080]|r"

local function PrintToChat(message, colorHex)
    if message then
        local prefix = PREFIX
        if colorHex then
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. " |cff" .. colorHex .. message .. "|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. " " .. message)
        end
    end
end

function AutoLFM.Core.Common.Print(message)
    PrintToChat(message)
end

function AutoLFM.Core.Common.PrintError(message)
    local color = AutoLFM.Core.Common.GetColor("RED")
    PrintToChat(message, color and color.hex)
end

function AutoLFM.Core.Common.PrintSuccess(message)
    local color = AutoLFM.Core.Common.GetColor("GREEN")
    PrintToChat(message, color and color.hex)
end

function AutoLFM.Core.Common.PrintTitle(message)
    local color = AutoLFM.Core.Common.GetColor("CYAN")
    PrintToChat(message, color and color.hex)
end

function AutoLFM.Core.Common.PrintInfo(message)
    local color = AutoLFM.Core.Common.GetColor("GRAY")
    PrintToChat(message, color and color.hex)
end
