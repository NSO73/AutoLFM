--=============================================================================
-- AutoLFM: Event Monitor (Debug Tool)
--   Monitor and log all events for debugging
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Debug = AutoLFM.Debug or {}
AutoLFM.Debug.EventMonitor = AutoLFM.Debug.EventMonitor or {}

local M = AutoLFM.Debug.EventMonitor

--=============================================================================
-- Private state
--=============================================================================
local isMonitoring = false
local registeredListeners = {}

--=============================================================================
-- Event Monitor
--=============================================================================
function M.Start()
  if isMonitoring then
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintWarning("Event monitoring is already active")
    end
    return
  end

  if not AutoLFM.Core then return end
  if not AutoLFM.Core.Maestro then return end

  -- List of all known events
  local events = {
    "Dungeons.SelectionChanged",
    "Dungeons.FilterChanged",
    "Dungeons.AllDeselected",
    "Raids.SelectionChanged",
    "Raids.SizeChanged",
    "Raids.AllDeselected",
    "Quests.SelectionChanged",
    "Roles.RoleToggled",
    "Broadcasts.CustomMessageChanged",
    "Broadcasts.IntervalChanged",
    "Broadcasts.ChannelToggled",
    "Messages.TemplateChanged",
    "Presets.ViewModeChanged",
    "Options.MinimapVisibilityChanged",
    "Options.DarkModeChanged",
    "Options.TestModeChanged",
    "Options.DebugModeChanged",
    "Selection.AllCleared",
    "Broadcaster.MessageSent",
    "Broadcaster.GroupFull",
    "Broadcaster.Started",
    "Broadcaster.Stopped"
  }

  -- Subscribe to all events
  for i = 1, table.getn(events) do
    local eventName = events[i]
    local listener = function(...)
      local args = {}
      for j = 1, arg.n do
        table.insert(args, tostring(arg[j]))
      end

      local argsText = ""
      if table.getn(args) > 0 then
        argsText = "(" .. table.concat(args, ", ") .. ")"
      else
        argsText = "()"
      end

      -- Use custom print with green color for event logs
      if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Event]|r " .. eventName .. argsText)
      end
    end

    AutoLFM.Core.Maestro.RegisterEventListener(eventName, listener)
    table.insert(registeredListeners, {event = eventName, listener = listener})
  end

  isMonitoring = true
  if AutoLFM.Core and AutoLFM.Core.Utils then
    AutoLFM.Core.Utils.PrintInfo("Event monitoring enabled (" .. table.getn(events) .. " events)")
  end
end

function M.Stop()
  if not isMonitoring then
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintWarning("Event monitoring is not active")
    end
    return
  end

  if not AutoLFM.Core then return end
  if not AutoLFM.Core.Maestro then return end

  -- Unregister all listeners
  for i = 1, table.getn(registeredListeners) do
    local entry = registeredListeners[i]
    AutoLFM.Core.Maestro.UnregisterEventListener(entry.event, entry.listener)
  end

  registeredListeners = {}
  isMonitoring = false
  if AutoLFM.Core and AutoLFM.Core.Utils then
    AutoLFM.Core.Utils.PrintInfo("Event monitoring disabled")
  end
end

function M.IsMonitoring()
  return isMonitoring
end

--=============================================================================
-- Shortcuts
--=============================================================================
function AutoLFM.Debug.MonitorAllEvents()
  M.Start()
end

function AutoLFM.Debug.StopMonitoring()
  M.Stop()
end

--=============================================================================
-- Print registered events and listeners with details
--=============================================================================
function AutoLFM.Debug.PrintEventListeners()
  if not AutoLFM.Debug.DebugWindow then return end
  if not AutoLFM.Debug.DebugWindow.LogInfo then return end
  if not AutoLFM.Core then return end
  if not AutoLFM.Core.Maestro then return end
  if not AutoLFM.Core.Maestro.eventListeners then return end

  AutoLFM.Debug.DebugWindow.LogInfo("=== AutoLFM Event Listeners ===")
  AutoLFM.Debug.DebugWindow.LogInfo(" ")

  local eventCount = 0
  local listenerCount = 0

  -- Collect and sort event names
  local eventNames = {}
  for eventName, _ in pairs(AutoLFM.Core.Maestro.eventListeners) do
    table.insert(eventNames, eventName)
  end
  table.sort(eventNames)

  -- Display each event with its listeners
  for i = 1, table.getn(eventNames) do
    local eventName = eventNames[i]
    local listeners = AutoLFM.Core.Maestro.eventListeners[eventName]
    local count = table.getn(listeners)
    eventCount = eventCount + 1
    listenerCount = listenerCount + count

    -- Event header
    AutoLFM.Debug.DebugWindow.LogInfo(eventName .. " (" .. count .. " listener" .. (count > 1 and "s" or "") .. ")")

    -- List each listener with details
    for j = 1, count do
      local listener = listeners[j]
      local metadata = AutoLFM.Core.Maestro.listenerMetadata[listener]

      if metadata then
        local displayText = metadata.description
        if not displayText or displayText == "" then
          displayText = metadata.source
          if metadata.line and metadata.line ~= "" then
            displayText = displayText .. metadata.line
          end
        end

        -- Show only description if available, otherwise show source
        if metadata.description and metadata.description ~= "" then
          AutoLFM.Debug.DebugWindow.LogInfo("  - " .. metadata.description)
        else
          local sourceInfo = metadata.source
          if metadata.line and metadata.line ~= "" then
            sourceInfo = sourceInfo .. metadata.line
          end
          AutoLFM.Debug.DebugWindow.LogInfo("  - " .. sourceInfo)
        end
      else
        AutoLFM.Debug.DebugWindow.LogInfo("  - unknown listener")
      end
    end

    AutoLFM.Debug.DebugWindow.LogInfo(" ")
  end

  local total = "Total: " .. eventCount .. " event" .. (eventCount > 1 and "s" or "") ..
                ", " .. listenerCount .. " listener" .. (listenerCount > 1 and "s" or "")
  AutoLFM.Debug.DebugWindow.LogInfo(total)
end

--=============================================================================
-- Print registered commands
--=============================================================================
function AutoLFM.Debug.PrintCommands()
  if not AutoLFM.Debug.DebugWindow then return end
  if not AutoLFM.Debug.DebugWindow.LogInfo then return end
  if not AutoLFM.Core then return end
  if not AutoLFM.Core.Maestro then return end
  if not AutoLFM.Core.Maestro.commandHandlers then return end

  AutoLFM.Debug.DebugWindow.LogInfo("=== AutoLFM Commands ===")

  local commandCount = 0
  local commands = {}

  for commandName, _ in pairs(AutoLFM.Core.Maestro.commandHandlers) do
    commandCount = commandCount + 1
    table.insert(commands, commandName)
  end

  -- Sort alphabetically
  table.sort(commands)

  for i = 1, table.getn(commands) do
    AutoLFM.Debug.DebugWindow.LogInfo(commands[i])
  end

  local total = "Total: " .. commandCount .. " command" .. (commandCount > 1 and "s" or "")
  AutoLFM.Debug.DebugWindow.LogInfo(total)
end
