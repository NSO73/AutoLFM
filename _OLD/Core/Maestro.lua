--=============================================================================
-- AutoLFM: Maestro
--   Central state management and addon API
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Maestro = AutoLFM.Core.Maestro or {}

--=============================================================================
-- PRIVATE INFRASTRUCTURE
--=============================================================================

-----------------------------------------------------------------------------
-- Infrastructure (Private - Internal technical mechanisms)
-----------------------------------------------------------------------------
local initHandlers = {}

-- Public for Debug module access
AutoLFM.Core.Maestro.commandHandlers = {}
AutoLFM.Core.Maestro.eventListeners = {}
AutoLFM.Core.Maestro.listenerMetadata = {} -- Public access for debug tools

-- Listener metadata tracking (for debug purposes)
local listenerIdCounter = 0
local listenerMetadata = AutoLFM.Core.Maestro.listenerMetadata -- Reference to public table

--=============================================================================
-- MAESTRO STATE (UI orchestration only)
--=============================================================================

-----------------------------------------------------------------------------
-- UI State (navigation and display)
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.currentTab = {
  bottomTab = "dungeons",
  lineTab = nil
}

AutoLFM.Core.Maestro.currentContent = nil

--=============================================================================
-- INITIALIZATION SYSTEM
--=============================================================================

-----------------------------------------------------------------------------
-- Helper to call a function by path (e.g., "Logic.Content.Dungeons.RegisterCommands")
-----------------------------------------------------------------------------
local function CallByPath(fullPath, arg)
  local lastDot = 0
  for i = string.len(fullPath), 1, -1 do
    if string.sub(fullPath, i, i) == "." then
      lastDot = i
      break
    end
  end

  if lastDot == 0 then
    AutoLFM.Core.Utils.PrintError("Invalid path: " .. fullPath)
    return false
  end

  -- Navigate to module
  local module = AutoLFM
  local current = 1
  while current < lastDot do
    local dotPos = string.find(fullPath, "%.", current)
    if dotPos and dotPos < lastDot then
      local part = string.sub(fullPath, current, dotPos - 1)
      module = module and module[part]
      current = dotPos + 1
    else
      local part = string.sub(fullPath, current, lastDot - 1)
      module = module and module[part]
      break
    end
  end

  if not module then
    AutoLFM.Core.Utils.PrintError("Missing module: " .. string.sub(fullPath, 1, lastDot - 1))
    return false
  end

  -- Get function
  local funcName = string.sub(fullPath, lastDot + 1)
  local func = module[funcName]
  if not func then
    AutoLFM.Core.Utils.PrintError("Missing function: " .. fullPath)
    return false
  end

  -- Execute
  local ok, result = pcall(func, arg)
  if not ok then
    AutoLFM.Core.Utils.PrintError("Error in " .. fullPath .. ": " .. tostring(result))
    return false
  end

  return result or true
end

-----------------------------------------------------------------------------
-- Load persistent data into Maestro's runtime state
-- Called once after Persistent.Init() but before RunInit()
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.Init()
  -- Load default panel (UI state)
  local defaultPanel = AutoLFM.Core.Persistent.GetDefaultPanel()
  if defaultPanel then
    local bottomTabs = {"dungeons", "raids", "quests", "broadcasts"}
    local lineTabs = {"presets"}
    local isBottomTab = false
    local isLineTab = false

    for i = 1, table.getn(bottomTabs) do
      if bottomTabs[i] == defaultPanel then
        isBottomTab = true
        break
      end
    end

    if not isBottomTab then
      for i = 1, table.getn(lineTabs) do
        if lineTabs[i] == defaultPanel then
          isLineTab = true
          break
        end
      end
    end

    if isBottomTab then
      AutoLFM.Core.Maestro.currentTab.bottomTab = defaultPanel
      AutoLFM.Core.Maestro.currentTab.lineTab = nil
    elseif isLineTab then
      AutoLFM.Core.Maestro.currentTab.bottomTab = nil
      AutoLFM.Core.Maestro.currentTab.lineTab = defaultPanel
    end
  end

  -- Note: Business state and options are now loaded by their respective modules during RunInit()
end

-----------------------------------------------------------------------------
-- Register an initialization handler
-- Handler can be either a function or a string path
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RegisterInit(moduleName, handler)
  if not moduleName or not handler then
    AutoLFM.Core.Utils.PrintError("Invalid RegisterInit call")
    return
  end
  initHandlers[moduleName] = handler
end

-----------------------------------------------------------------------------
-- Run all registered initialization handlers
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RunInit()
  for moduleName, handler in pairs(initHandlers) do
    local ok, err
    if type(handler) == "string" then
      ok = CallByPath(handler)
      if not ok then
        err = "Failed to call " .. handler
      end
    else
      ok, err = pcall(handler)
    end
    if not ok then
      AutoLFM.Core.Utils.PrintError("Init error in " .. moduleName .. ": " .. tostring(err or "unknown error"))
    end
  end
end

--=============================================================================
-- COMMAND SYSTEM
--=============================================================================

-----------------------------------------------------------------------------
-- Register a command handler (called by Logic layer)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RegisterCommand(commandName, handler)
  AutoLFM.Core.Maestro.commandHandlers[commandName] = handler

  -- Log command registration
  if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.LogListener then
    AutoLFM.Debug.DebugWindow.LogListener("+ Command: " .. commandName)
  end
end

-----------------------------------------------------------------------------
-- Dispatch a command (called by UI layer)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.DispatchCommand(commandName, ...)
  -- Log to debug window only (no chat logging)
  if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.LogCommand then
    AutoLFM.Debug.DebugWindow.LogCommand(commandName, unpack(arg))
  end

  local handler = AutoLFM.Core.Maestro.commandHandlers[commandName]
  if handler then
    handler(unpack(arg))
  else
    AutoLFM.Core.Utils.PrintError("AutoLFM Error: Unknown command '" .. commandName .. "'")
  end
end

--=============================================================================
-- EVENT SYSTEM
--=============================================================================

-----------------------------------------------------------------------------
-- Register an event listener
-- Parameters:
--   eventName: The event to listen to
--   callback: The callback function
--   description: (optional) Human-readable description of what this listener does
-- Returns the callback reference for later unregistration
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RegisterEventListener(eventName, callback, description)
  if not AutoLFM.Core.Maestro.eventListeners[eventName] then
    AutoLFM.Core.Maestro.eventListeners[eventName] = {}
  end
  table.insert(AutoLFM.Core.Maestro.eventListeners[eventName], callback)

  -- Generate listener metadata for debugging
  listenerIdCounter = listenerIdCounter + 1
  local listenerId = "L" .. listenerIdCounter

  -- Try to identify source from stack trace
  local source = "unknown"
  local lineInfo = ""
  local debugInfo = debug and debug.getinfo and debug.getinfo(2, "Sln")
  if debugInfo and debugInfo.short_src then
    -- Extract just the filename from the path
    local filename = debugInfo.short_src
    local lastSlash = 0
    for i = string.len(filename), 1, -1 do
      local char = string.sub(filename, i, i)
      if char == "\\" or char == "/" then
        lastSlash = i
        break
      end
    end
    if lastSlash > 0 then
      filename = string.sub(filename, lastSlash + 1)
    end

    -- Remove .lua extension for cleaner display
    if string.sub(filename, -4) == ".lua" then
      filename = string.sub(filename, 1, -5)
    end

    source = filename

    -- Add line number if available
    if debugInfo.currentline and debugInfo.currentline > 0 then
      lineInfo = ":" .. debugInfo.currentline
    end
  end

  listenerMetadata[callback] = {
    id = listenerId,
    eventName = eventName,
    source = source,
    line = lineInfo,
    description = description
  }

  -- Log listener registration
  if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.LogListener then
    local count = table.getn(AutoLFM.Core.Maestro.eventListeners[eventName])
    local displayText = description or (source .. lineInfo)
    AutoLFM.Debug.DebugWindow.LogListener("+ Listener for " .. eventName .. ": " .. displayText .. " (" .. count .. " total)")
  end

  return callback
end

-----------------------------------------------------------------------------
-- Unregister a specific event listener
-- Pass the callback reference returned by RegisterEventListener
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.UnregisterEventListener(eventName, callback)
  if not AutoLFM.Core.Maestro.eventListeners[eventName] then return end

  local listeners = AutoLFM.Core.Maestro.eventListeners[eventName]
  for i = table.getn(listeners), 1, -1 do
    if listeners[i] == callback then
      table.remove(listeners, i)
    end
  end

  -- Log listener unregistration
  if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.LogListener then
    local metadata = listenerMetadata[callback]
    local displayText = "unknown"
    if metadata then
      displayText = metadata.description
      if not displayText or displayText == "" then
        displayText = metadata.source
        if metadata.line and metadata.line ~= "" then
          displayText = displayText .. metadata.line
        end
      end
    end
    local count = table.getn(listeners)
    AutoLFM.Debug.DebugWindow.LogListener("- Listener for " .. eventName .. ": " .. displayText .. " (" .. count .. " remaining)")
  end

  -- Clean up metadata
  listenerMetadata[callback] = nil

  -- Clean up empty listener arrays
  if table.getn(listeners) == 0 then
    AutoLFM.Core.Maestro.eventListeners[eventName] = nil
  end
end

-----------------------------------------------------------------------------
-- Unregister all listeners for a specific event
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.UnregisterAllEventListeners(eventName)
  AutoLFM.Core.Maestro.eventListeners[eventName] = nil
end

-----------------------------------------------------------------------------
-- Emit an event (called by Logic after state change)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.EmitEvent(eventName, ...)
  -- Log to debug window
  if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.LogEvent then
    AutoLFM.Debug.DebugWindow.LogEvent(eventName, unpack(arg))
  end

  local listeners = AutoLFM.Core.Maestro.eventListeners[eventName]
  if listeners then
    -- Log each listener being triggered
    if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.LogAction then
      local count = table.getn(listeners)
      if count > 0 then
        for i = 1, count do
          local listener = listeners[i]
          local metadata = listenerMetadata[listener]
          if metadata then
            -- Use description if available, otherwise fall back to source:line
            local displayText = metadata.description
            if not displayText or displayText == "" then
              displayText = metadata.source
              if metadata.line and metadata.line ~= "" then
                displayText = displayText .. metadata.line
              end
            end
            AutoLFM.Debug.DebugWindow.LogAction("-> " .. displayText)
          else
            AutoLFM.Debug.DebugWindow.LogAction("-> unknown listener")
          end
        end
      end
    end

    -- Create a copy to avoid issues if listeners are modified during iteration
    local listenersCopy = {}
    for i = 1, table.getn(listeners) do
      listenersCopy[i] = listeners[i]
    end

    for i = 1, table.getn(listenersCopy) do
      if listenersCopy[i] then
        listenersCopy[i](unpack(arg))
      end
    end
  end
end

--=============================================================================
-- STATE QUERY API
--=============================================================================

-----------------------------------------------------------------------------
-- Check if there's any content selected (query modules)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.HasAnySelection()
  -- Check roles
  if AutoLFM.Logic.Roles and AutoLFM.Logic.Roles.HasRoleSelected and AutoLFM.Logic.Roles.HasRoleSelected() then
    return true
  end

  -- Check dungeons
  if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
    local dungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
    if table.getn(dungeons) > 0 then
      return true
    end
  end

  -- Check raids
  if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
    local raids = AutoLFM.Logic.Content.Raids.GetSelected()
    if table.getn(raids) > 0 then
      return true
    end
  end

  -- Check quests
  if AutoLFM.Logic.Content.Quests and AutoLFM.Logic.Content.Quests.GetSelected then
    local quests = AutoLFM.Logic.Content.Quests.GetSelected()
    if table.getn(quests) > 0 then
      return true
    end
  end

  -- Check custom message
  if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetCustomMessage then
    local message = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage()
    if message and message ~= "" then
      return true
    end
  end

  return false
end

--=============================================================================
-- DEBUG / STATE INSPECTION
--=============================================================================

-----------------------------------------------------------------------------
-- Helper functions for PrintState
-----------------------------------------------------------------------------
local function PrintHeader(text)
  AutoLFM.Core.Utils.PrintInfo(AutoLFM.Core.Utils.ColorizeText(text .. ":", "blue"))
end

local function PrintBoolean(label, value)
  local coloredValue = value and
    AutoLFM.Core.Utils.ColorizeText("Yes", "green") or
    AutoLFM.Core.Utils.ColorizeText("No", "red")
  AutoLFM.Core.Utils.PrintInfo("  " .. label .. ": " .. coloredValue)
end

local function PrintValue(label, value)
  AutoLFM.Core.Utils.PrintInfo("  " .. label .. ": " .. tostring(value))
end

local function PrintEmpty()
  AutoLFM.Core.Utils.PrintNote("  (none)")
end

-----------------------------------------------------------------------------
-- Print complete addon state for debugging
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.PrintState()
  AutoLFM.Core.Utils.PrintTitle("=== AutoLFM State ===")

  -- Current tab
  PrintHeader("Current Tab")
  PrintValue("Bottom Tab", AutoLFM.Core.Maestro.currentTab.bottomTab)
  PrintValue("Line Tab", AutoLFM.Core.Maestro.currentTab.lineTab)

  -- Roles
  if AutoLFM.Logic.Roles and AutoLFM.Logic.Roles.GetSelectedRoles then
    local roles = AutoLFM.Logic.Roles.GetSelectedRoles()
    PrintHeader("Roles")
    PrintBoolean("Tank", roles.tank)
    PrintBoolean("Heal", roles.heal)
    PrintBoolean("DPS", roles.dps)
  end

  -- Channels
  if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.IsChannelSelected then
    PrintHeader("Channels")
    PrintBoolean("LookingForGroup", AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("LookingForGroup"))
    PrintBoolean("World", AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("World"))
    PrintBoolean("Hardcore", AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("Hardcore"))
  end

  -- Dungeons
  if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
    local selected = AutoLFM.Logic.Content.Dungeons.GetSelected()
    PrintHeader("Dungeons (" .. table.getn(selected) .. " selected)")
    if table.getn(selected) > 0 then
      for i = 1, table.getn(selected) do
        AutoLFM.Core.Utils.PrintInfo("  - " .. selected[i].name)
      end
    else
      PrintEmpty()
    end
  end

  -- Raids
  if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
    local selected = AutoLFM.Logic.Content.Raids.GetSelected()
    PrintHeader("Raids (" .. table.getn(selected) .. " selected)")
    if table.getn(selected) > 0 then
      for i = 1, table.getn(selected) do
        local raid = selected[i]
        local size = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index or i)
        local sizeText = (raid.sizeMin ~= raid.sizeMax)
          and " [Size: " .. size .. " (range: " .. raid.sizeMin .. "-" .. raid.sizeMax .. ")]"
          or " [Size: " .. raid.sizeMin .. "]"
        AutoLFM.Core.Utils.PrintInfo("  - " .. raid.name .. sizeText)
      end
    else
      PrintEmpty()
    end
  end

  -- Raid sizes
  if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetAllRaidSizes then
    local raidSizes = AutoLFM.Logic.Content.Raids.GetAllRaidSizes()
    PrintHeader("Raid Sizes")
    local hasRaidSizes = false
    for index, size in pairs(raidSizes) do
      local raid = AutoLFM.Core.Constants.RAIDS[index]
      if raid then
        AutoLFM.Core.Utils.PrintInfo("  [" .. index .. "] " .. raid.name .. ": " .. size)
        hasRaidSizes = true
      end
    end
    if not hasRaidSizes then
      PrintEmpty()
    end
  end

  -- Quests
  if AutoLFM.Logic.Content.Quests and AutoLFM.Logic.Content.Quests.GetSelected then
    local selected = AutoLFM.Logic.Content.Quests.GetSelected()
    PrintHeader("Quests (" .. table.getn(selected) .. " selected)")
    if table.getn(selected) == 0 then
      PrintEmpty()
    end
  end

  -- Broadcast stats
  if AutoLFM.Logic.Content.Broadcasts then
    local stats = AutoLFM.Logic.Content.Broadcasts.GetBroadcastStats and AutoLFM.Logic.Content.Broadcasts.GetBroadcastStats() or {}
    local interval = AutoLFM.Logic.Content.Broadcasts.GetInterval and AutoLFM.Logic.Content.Broadcasts.GetInterval() or 60

    PrintHeader("Broadcast")
    PrintBoolean("Active", stats.isActive or false)
    PrintValue("Interval", interval .. " seconds")
    PrintValue("Message count", stats.messageCount or 0)

    local startTime = stats.startTime
    if startTime and startTime > 0 then
      local duration = GetTime() - startTime
      local hours = math.floor(duration / 3600)
      local minutes = math.floor((duration - hours * 3600) / 60)
      local seconds = math.floor(duration - hours * 3600 - minutes * 60)
      AutoLFM.Core.Utils.PrintInfo(string.format("  Running for: %02d:%02d:%02d", hours, minutes, seconds))
    end
  end

  -- Custom broadcast message
  if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetCustomMessage then
    local customMessage = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage()
    if customMessage and customMessage ~= "" then
      PrintHeader("Custom Broadcast Message")
      AutoLFM.Core.Utils.PrintInfo("  " .. customMessage)
    end
  end

  -- Preview message
  PrintHeader("Preview Message")
  local previewMsg = AutoLFM.Logic.Message and AutoLFM.Logic.Message.GetPreviewMessage and AutoLFM.Logic.Message.GetPreviewMessage() or ""
  if previewMsg and previewMsg ~= "" then
    AutoLFM.Core.Utils.PrintInfo("  " .. previewMsg)
  else
    PrintEmpty()
  end

  AutoLFM.Core.Utils.PrintTitle("========================")
end

--=============================================================================
-- REGISTRY INSPECTION API
--=============================================================================

-----------------------------------------------------------------------------
-- Get all registered commands
-- Returns: array of command names
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetAllCommands()
  local commands = {}
  for commandName, _ in pairs(AutoLFM.Core.Maestro.commandHandlers) do
    table.insert(commands, commandName)
  end

  -- Sort alphabetically for consistency
  table.sort(commands)
  return commands
end

-----------------------------------------------------------------------------
-- Get all registered event names
-- Returns: array of event names
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetAllEvents()
  local events = {}
  for eventName, _ in pairs(AutoLFM.Core.Maestro.eventListeners) do
    table.insert(events, eventName)
  end

  -- Sort alphabetically for consistency
  table.sort(events)
  return events
end

-----------------------------------------------------------------------------
-- Get all listeners for a specific event
-- Returns: array of listener info {id, source, line, description}
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetListenersForEvent(eventName)
  local listeners = AutoLFM.Core.Maestro.eventListeners[eventName]
  if not listeners then
    return {}
  end

  local listenerInfos = {}
  for i = 1, table.getn(listeners) do
    local listener = listeners[i]
    local metadata = listenerMetadata[listener]
    if metadata then
      table.insert(listenerInfos, {
        id = metadata.id,
        source = metadata.source,
        line = metadata.line or "",
        description = metadata.description or ""
      })
    else
      table.insert(listenerInfos, {
        id = "unknown",
        source = "unknown",
        line = "",
        description = ""
      })
    end
  end

  return listenerInfos
end

-----------------------------------------------------------------------------
-- Get complete registry overview
-- Returns: { commands = {...}, events = {eventName = {listeners = {...}}} }
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetRegistry()
  local registry = {
    commands = AutoLFM.Core.Maestro.GetAllCommands(),
    events = {}
  }

  -- Build events map with their listeners
  local eventNames = AutoLFM.Core.Maestro.GetAllEvents()
  for i = 1, table.getn(eventNames) do
    local eventName = eventNames[i]
    registry.events[eventName] = {
      listenerCount = table.getn(AutoLFM.Core.Maestro.eventListeners[eventName] or {}),
      listeners = AutoLFM.Core.Maestro.GetListenersForEvent(eventName)
    }
  end

  return registry
end

-----------------------------------------------------------------------------
-- Print complete registry (commands, events, listeners)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.PrintRegistry()
  AutoLFM.Core.Utils.PrintTitle("=== Maestro Registry ===")

  -- Commands
  local commands = AutoLFM.Core.Maestro.GetAllCommands()
  PrintHeader("Registered Commands (" .. table.getn(commands) .. ")")
  if table.getn(commands) > 0 then
    for i = 1, table.getn(commands) do
      AutoLFM.Core.Utils.PrintInfo("  - " .. commands[i])
    end
  else
    PrintEmpty()
  end

  -- Events with listeners
  local eventNames = AutoLFM.Core.Maestro.GetAllEvents()
  PrintHeader("Registered Events (" .. table.getn(eventNames) .. ")")
  if table.getn(eventNames) > 0 then
    for i = 1, table.getn(eventNames) do
      local eventName = eventNames[i]
      local listeners = AutoLFM.Core.Maestro.GetListenersForEvent(eventName)
      local listenerCount = table.getn(listeners)

      AutoLFM.Core.Utils.PrintInfo("  " .. AutoLFM.Core.Utils.ColorizeText(eventName, "yellow") .. " (" .. listenerCount .. " listener" .. (listenerCount > 1 and "s" or "") .. ")")

      -- List each listener
      for j = 1, listenerCount do
        local listener = listeners[j]
        local displayText = listener.description
        if not displayText or displayText == "" then
          displayText = listener.source
          if listener.line and listener.line ~= "" then
            displayText = displayText .. listener.line
          end
        end
        AutoLFM.Core.Utils.PrintInfo("    [" .. listener.id .. "] " .. displayText)
      end
    end
  else
    PrintEmpty()
  end

  AutoLFM.Core.Utils.PrintTitle("========================")
end
