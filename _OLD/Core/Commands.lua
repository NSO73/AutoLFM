--=============================================================================
-- AutoLFM: Commands
--   Slash command handlers
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Commands = AutoLFM.Core.Commands or {}

-----------------------------------------------------------------------------
-- Slash Command Handler
-----------------------------------------------------------------------------
function AutoLFM.Core.Commands.HandleSlashCommand(msg)
  if not msg then msg = "" end

  -- Parse command and arguments
  local command = ""
  local args = ""

  local firstSpace = string.find(msg, " ")
  if firstSpace then
    command = string.sub(msg, 1, firstSpace - 1)
    args = string.sub(msg, firstSpace + 1)
    -- Trim leading/trailing spaces from args
    args = string.gsub(args, "^%s+", "")
    args = string.gsub(args, "%s+$", "")
  else
    command = msg
  end

  command = string.lower(command)

  if command == "" or command == "toggle" then
    AutoLFM.Logic.MainFrame.Toggle()
  elseif command == "state" then
    AutoLFM.Core.Maestro.PrintState()
  elseif command == "registry" then
    if AutoLFM.Core.Maestro and AutoLFM.Core.Maestro.PrintRegistry then
      AutoLFM.Core.Maestro.PrintRegistry()
    else
      AutoLFM.Core.Utils.PrintError("Maestro module not loaded")
    end
  elseif command == "debug" then
    -- Toggle debug window
    if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.Toggle then
      AutoLFM.Debug.DebugWindow.Toggle()
    else
      AutoLFM.Core.Utils.PrintError("Debug module not loaded")
    end
  elseif command == "test" then
    -- Test: Group size simulation
    if AutoLFM.Debug and AutoLFM.Debug.GroupTest then
      local subCommand = ""
      local value = ""

      local firstSpace = string.find(args, " ")
      if firstSpace then
        subCommand = string.sub(args, 1, firstSpace - 1)
        value = string.sub(args, firstSpace + 1)
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")
      else
        subCommand = args
      end

      subCommand = string.lower(subCommand)

      if subCommand == "setgroup" or subCommand == "set" then
        local size = tonumber(value)
        if size then
          AutoLFM.Debug.GroupTest.SetGroupSize(size)
        else
          AutoLFM.Core.Utils.PrintError("Usage: /lfm test setgroup <number>")
        end
      elseif subCommand == "reset" or subCommand == "off" then
        AutoLFM.Debug.GroupTest.Reset()
      elseif subCommand == "full" then
        AutoLFM.Debug.GroupTest.SimulateFull()
      elseif subCommand == "status" then
        if AutoLFM.Debug.GroupTest.IsActive() then
          local testSize = AutoLFM.Debug.GroupTest.GetTestSize()
          AutoLFM.Core.Utils.PrintInfo("Test mode: ACTIVE - Group size: " .. testSize)
        else
          AutoLFM.Core.Utils.PrintInfo("Test mode: INACTIVE - Using real group data")
        end
      else
        AutoLFM.Core.Utils.PrintError("Usage:")
        AutoLFM.Core.Utils.PrintInfo("  /lfm test setgroup <1-40> - Set group size")
        AutoLFM.Core.Utils.PrintInfo("  /lfm test full - Simulate full group")
        AutoLFM.Core.Utils.PrintInfo("  /lfm test reset - Disable test mode")
        AutoLFM.Core.Utils.PrintInfo("  /lfm test status - Show test mode status")
      end
    else
      AutoLFM.Core.Utils.PrintError("Debug module not loaded")
    end
  else
    AutoLFM.Core.Utils.PrintTitle("AutoLFM3 Commands:")
    AutoLFM.Core.Utils.PrintInfo("/lfm or /lfm toggle - Toggle main frame")
    AutoLFM.Core.Utils.PrintInfo("/lfm state - Show current state")
    AutoLFM.Core.Utils.PrintInfo("/lfm registry - Show all commands/events/listeners")
    AutoLFM.Core.Utils.PrintInfo("/lfm debug - Toggle debug console window")
    AutoLFM.Core.Utils.PrintInfo(" ")
    AutoLFM.Core.Utils.PrintTitle("Test Commands:")
    AutoLFM.Core.Utils.PrintInfo("/lfm test setgroup <1-40> - Simulate group size")
    AutoLFM.Core.Utils.PrintInfo("/lfm test full - Simulate full group")
    AutoLFM.Core.Utils.PrintInfo("/lfm test reset - Disable test mode")
    AutoLFM.Core.Utils.PrintInfo("/lfm test status - Show test status")
    AutoLFM.Core.Utils.PrintInfo(" ")
    AutoLFM.Core.Utils.PrintWarning("Note: Use 'Registry' button in debug window for live diagnostics")
  end
end

-----------------------------------------------------------------------------
-- Registration
-----------------------------------------------------------------------------
SLASH_AUTOLFM1 = "/lfm"
SlashCmdList["AUTOLFM"] = AutoLFM.Core.Commands.HandleSlashCommand
