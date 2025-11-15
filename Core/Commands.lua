--=============================================================================
-- AutoLFM: Slash Commands
--   Command-line interface for the addon
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Commands = {}

--=============================================================================
-- SLASH COMMAND HANDLER
--=============================================================================

local function HandleSlashCommand(msg)
    -- Parse command
    local cmd = string.lower(msg or "")

    if cmd == "" then
        -- Toggle window
        AutoLFM.Core.Maestro.Dispatch("UI.Toggle")

    elseif cmd == "reset" or cmd == "resetminimap" then
        -- Reset minimap button position
        AutoLFM.Core.Maestro.Dispatch("Minimap.Reset")

    elseif cmd == "debug" then
        -- Toggle debug window
        AutoLFM.Core.Maestro.Dispatch("Debug.Toggle")

    elseif cmd == "commands" then
        -- List all registered commands
        AutoLFM.Core.Maestro.PrintCommands()

    else
        -- Show help in debug window
        if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogInfo then
            AutoLFM.Components.DebugWindow.LogInfo("=== Available Commands ===")
            AutoLFM.Components.DebugWindow.LogInfo("  /lfm - Toggle window")
            AutoLFM.Components.DebugWindow.LogInfo("  /lfm reset - Reset minimap button position")
            AutoLFM.Components.DebugWindow.LogInfo("  /lfm debug - Toggle debug window")
            AutoLFM.Components.DebugWindow.LogInfo("  /lfm commands - List all registered commands")
        end
    end
end

--=============================================================================
-- REGISTRATION
--=============================================================================

SLASH_AUTOLFM1 = "/lfm"
SLASH_AUTOLFM2 = "/autolfm"
SlashCmdList["AUTOLFM"] = HandleSlashCommand
