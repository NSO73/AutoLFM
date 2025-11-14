--=============================================================================
-- AutoLFM: Debug Window
--   Real-time debug console with event monitoring and introspection
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Debug = AutoLFM.Debug or {}
AutoLFM.Debug.DebugWindow = AutoLFM.Debug.DebugWindow or {}

--=============================================================================
-- Private State
--=============================================================================
local debugFrame = nil
local logBuffer = {}
local maxLogLines = 500
local isEnabled = false

-- Event monitoring state
local isMonitoring = false
local registeredListeners = {}

--=============================================================================
-- Color Codes
--=============================================================================
local COLORS = {
  EVENT = "|cff00ff00",      -- Green
  COMMAND = "|cff00aaff",    -- Blue
  ACTION = "|cffaa00ff",     -- Purple
  ERROR = "|cffff0000",      -- Red
  WARNING = "|cffffaa00",    -- Orange
  INFO = "|cffffffff",       -- White
  TIMESTAMP = "|cff888888",  -- Gray
  RESET = "|r"
}

--=============================================================================
-- Helper Functions
--=============================================================================
local function GetTimestamp()
  local hour, minute = GetGameTime()
  return string.format("%02d:%02d", hour, minute)
end

local function FormatLogLine(category, message)
  local timestamp = COLORS.TIMESTAMP .. "[" .. GetTimestamp() .. "]" .. COLORS.RESET
  local coloredCategory = (COLORS[category] or COLORS.INFO) .. "[" .. category .. "]" .. COLORS.RESET
  return timestamp .. " " .. coloredCategory .. " " .. message
end

local function AddToBuffer(line)
  table.insert(logBuffer, line)

  if table.getn(logBuffer) > maxLogLines then
    table.remove(logBuffer, 1)
  end
end

local function UpdateDisplay()
  if not debugFrame then return end
  if not debugFrame:IsVisible() then return end

  local scrollFrame = getglobal("AutoLFM_DebugWindow_ScrollFrame")
  local editBox = getglobal("AutoLFM_DebugWindow_EditBox")

  if not editBox then return end

  local text = table.concat(logBuffer, "\n")
  editBox:SetText(text)

  -- Calculate height based on number of lines (approximate)
  local lineCount = table.getn(logBuffer)
  if lineCount == 0 then lineCount = 1 end

  local lineHeight = 14 -- Approximate height per line
  local calculatedHeight = (lineCount * lineHeight) + 10 -- Small margin for safety

  -- Set height to calculated height (allow it to grow beyond visible area)
  editBox:SetHeight(calculatedHeight)

  -- Update scroll child rect to recalculate scrollable area
  if scrollFrame then
    scrollFrame:UpdateScrollChildRect()
  end

  if scrollFrame and scrollFrame.ScrollToBottom then
    scrollFrame:ScrollToBottom()
  end
end

--=============================================================================
-- Public Logging API
--=============================================================================
function AutoLFM.Debug.DebugWindow.LogEvent(eventName, ...)
  local argsStr = ""

  if arg.n > 0 then
    local argsList = {}
    for i = 1, arg.n do
      table.insert(argsList, tostring(arg[i]))
    end
    argsStr = " (" .. table.concat(argsList, ", ") .. ")"
  end

  local line = FormatLogLine("EVENT", eventName .. argsStr)
  AddToBuffer(line)

  -- Only update display if window is enabled
  if isEnabled then
    UpdateDisplay()
  end
end

function AutoLFM.Debug.DebugWindow.LogCommand(commandName, ...)
  local argsStr = ""

  if arg.n > 0 then
    local argsList = {}
    for i = 1, arg.n do
      table.insert(argsList, tostring(arg[i]))
    end
    argsStr = " (" .. table.concat(argsList, ", ") .. ")"
  end

  local line = FormatLogLine("COMMAND", commandName .. argsStr)
  AddToBuffer(line)

  -- Only update display if window is enabled
  if isEnabled then
    UpdateDisplay()
  end
end

function AutoLFM.Debug.DebugWindow.LogError(message)
  if not message then return end

  local line = FormatLogLine("ERROR", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function AutoLFM.Debug.DebugWindow.LogWarning(message)
  if not message then return end

  local line = FormatLogLine("WARNING", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function AutoLFM.Debug.DebugWindow.LogInfo(message)
  if not message then return end

  local line = FormatLogLine("INFO", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function AutoLFM.Debug.DebugWindow.LogAction(message)
  if not message then return end

  local line = FormatLogLine("ACTION", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function AutoLFM.Debug.DebugWindow.LogListener(message)
  if not message then return end

  -- Silent logging for listener operations (no category, just gray timestamp and message)
  local timestamp = COLORS.TIMESTAMP .. "[" .. GetTimestamp() .. "]" .. COLORS.RESET
  local line = timestamp .. " " .. COLORS.TIMESTAMP .. message .. COLORS.RESET
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

--=============================================================================
-- Window Management
--=============================================================================
function AutoLFM.Debug.DebugWindow.Show()
  if not debugFrame then
    AutoLFM.Debug.DebugWindow.CreateFrame()
  end

  if debugFrame then
    debugFrame:Show()
  end
  isEnabled = true

  -- Update display with all buffered logs
  UpdateDisplay()

  AutoLFM.Debug.DebugWindow.LogInfo("Debug window opened")

  -- Automatically start event monitoring when debug window opens
  AutoLFM.Debug.DebugWindow.StartMonitoring()
end

function AutoLFM.Debug.DebugWindow.Hide()
  if debugFrame then
    debugFrame:Hide()
  end

  isEnabled = false

  -- Automatically stop event monitoring when debug window closes
  AutoLFM.Debug.DebugWindow.StopMonitoring()
end

function AutoLFM.Debug.DebugWindow.Toggle()
  if debugFrame and debugFrame:IsVisible() then
    AutoLFM.Debug.DebugWindow.Hide()
  else
    AutoLFM.Debug.DebugWindow.Show()
  end
end

function AutoLFM.Debug.DebugWindow.IsVisible()
  return debugFrame and debugFrame:IsVisible() or false
end

function AutoLFM.Debug.DebugWindow.Clear()
  logBuffer = {}
  UpdateDisplay()

  -- Reset scroll position to top
  local scrollBar = getglobal("AutoLFM_DebugWindow_ScrollFrameScrollBar")
  if scrollBar then
    scrollBar:SetValue(0)
  end

  AutoLFM.Debug.DebugWindow.LogInfo("Debug log cleared")
end

--=============================================================================
-- Frame Creation
--=============================================================================
function AutoLFM.Debug.DebugWindow.CreateFrame()
  if debugFrame then return end

  -- Main Frame
  debugFrame = CreateFrame("Frame", "AutoLFM_DebugWindow", UIParent)
  debugFrame:SetWidth(600)
  debugFrame:SetHeight(400)
  debugFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  debugFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 11, right = 12, top = 12, bottom = 11}
  })
  debugFrame:SetMovable(true)
  debugFrame:EnableMouse(true)
  debugFrame:SetFrameStrata("DIALOG")
  debugFrame:Hide()

  -- Title
  local title = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", debugFrame, "TOP", 0, -15)
  title:SetText("AutoLFM Debug Console")

  -- Close Button
  local closeButton = CreateFrame("Button", nil, debugFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", debugFrame, "TOPRIGHT", -5, -5)
  closeButton:SetScript("OnClick", function()
    AutoLFM.Debug.DebugWindow.Hide()
  end)

  -- Clear Button
  local clearButton = CreateFrame("Button", "AutoLFM_DebugWindow_ClearButton", debugFrame, "UIPanelButtonTemplate")
  clearButton:SetWidth(80)
  clearButton:SetHeight(22)
  clearButton:SetPoint("BOTTOMLEFT", debugFrame, "BOTTOMLEFT", 15, 15)
  clearButton:SetText("Clear")
  clearButton:SetScript("OnClick", function()
    AutoLFM.Debug.DebugWindow.Clear()
  end)

  -- Select All Button
  local selectAllButton = CreateFrame("Button", "AutoLFM_DebugWindow_SelectAllButton", debugFrame, "UIPanelButtonTemplate")
  selectAllButton:SetWidth(80)
  selectAllButton:SetHeight(22)
  selectAllButton:SetPoint("LEFT", clearButton, "RIGHT", 5, 0)
  selectAllButton:SetText("Select All")
  selectAllButton:SetScript("OnClick", function()
    local editBox = getglobal("AutoLFM_DebugWindow_EditBox")
    if editBox then
      editBox:HighlightText()
      editBox:SetFocus()
    end
  end)

  -- Events Button
  local eventsButton = CreateFrame("Button", "AutoLFM_DebugWindow_EventsButton", debugFrame, "UIPanelButtonTemplate")
  eventsButton:SetWidth(80)
  eventsButton:SetHeight(22)
  eventsButton:SetPoint("LEFT", selectAllButton, "RIGHT", 5, 0)
  eventsButton:SetText("Events")
  eventsButton:SetScript("OnClick", function()
    AutoLFM.Debug.DebugWindow.PrintEventListeners()
  end)

  -- Commands Button
  local commandsButton = CreateFrame("Button", "AutoLFM_DebugWindow_CommandsButton", debugFrame, "UIPanelButtonTemplate")
  commandsButton:SetWidth(80)
  commandsButton:SetHeight(22)
  commandsButton:SetPoint("LEFT", eventsButton, "RIGHT", 5, 0)
  commandsButton:SetText("Commands")
  commandsButton:SetScript("OnClick", function()
    AutoLFM.Debug.DebugWindow.PrintCommands()
  end)

  -- Info Text
  local infoText = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  infoText:SetPoint("BOTTOMRIGHT", debugFrame, "BOTTOMRIGHT", -15, 15)
  infoText:SetText("|cff888888Ctrl+C to copy selected text|r")

  -- Scroll Frame
  local scrollFrame = CreateFrame("ScrollFrame", "AutoLFM_DebugWindow_ScrollFrame", debugFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 20, -40)
  scrollFrame:SetPoint("BOTTOMRIGHT", debugFrame, "BOTTOMRIGHT", -35, 45)

  -- Edit Box
  local editBox = CreateFrame("EditBox", "AutoLFM_DebugWindow_EditBox", scrollFrame)
  editBox:SetWidth(scrollFrame:GetWidth())
  editBox:SetHeight(scrollFrame:GetHeight())
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject(GameFontNormalSmall)
  editBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  editBox:SetScript("OnTextChanged", function()
    -- Prevent editing
    if this:GetText() ~= table.concat(logBuffer, "\n") then
      this:SetText(table.concat(logBuffer, "\n"))
    end
  end)

  scrollFrame:SetScrollChild(editBox)

  -- Helper function to scroll to bottom
  scrollFrame.ScrollToBottom = function()
    -- Force update the scroll child rect first
    scrollFrame:UpdateScrollChildRect()

    local scrollBar = getglobal("AutoLFM_DebugWindow_ScrollFrameScrollBar")
    if scrollBar and scrollBar.GetMaxValue then
      local maxValue = scrollBar:GetMaxValue()
      if maxValue and maxValue > 0 then
        scrollBar:SetValue(maxValue)
      end
    end
  end

  -- Enable mouse wheel scrolling
  scrollFrame:EnableMouseWheel(1)
  scrollFrame:SetScript("OnMouseWheel", function()
    local scrollBar = getglobal("AutoLFM_DebugWindow_ScrollFrameScrollBar")
    if scrollBar then
      local currentValue = scrollBar:GetValue()
      local step = 20

      if arg1 > 0 then
        scrollBar:SetValue(currentValue - step)
      else
        scrollBar:SetValue(currentValue + step)
      end
    end
  end)

  -- Make draggable
  debugFrame:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
      this:StartMoving()
    end
  end)

  debugFrame:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
  end)

  -- Register with DarkUI if available
  if AutoLFM.Components then
    if AutoLFM.Components.Themes then
      if AutoLFM.Components.Themes.DarkUI then
        if AutoLFM.Components.Themes.DarkUI.RegisterFrame then
          AutoLFM.Components.Themes.DarkUI.RegisterFrame(debugFrame)
        end
      end
    end
  end
end

--=============================================================================
-- Event Monitoring
--=============================================================================
function AutoLFM.Debug.DebugWindow.StartMonitoring()
  if isMonitoring then
    return
  end

  if not AutoLFM.Core then return end
  if not AutoLFM.Core.Maestro then return end

  -- Get all registered events dynamically
  local allEvents = AutoLFM.Core.Maestro.GetAllEvents()
  if not allEvents then
    return
  end

  -- Subscribe to all events
  for i = 1, table.getn(allEvents) do
    local eventName = allEvents[i].key
    local listener = function(...)
      -- Log to debug window if available
      if AutoLFM.Debug and AutoLFM.Debug.DebugWindow and AutoLFM.Debug.DebugWindow.LogEvent then
        AutoLFM.Debug.DebugWindow.LogEvent(eventName, unpack(arg))
      end
    end

    AutoLFM.Core.Maestro.On(eventName, listener, {
      key = "EventMonitor." .. eventName,
      description = "Event monitor listener for " .. eventName
    })
    table.insert(registeredListeners, {event = eventName, listener = listener})
  end

  isMonitoring = true
end

function AutoLFM.Debug.DebugWindow.StopMonitoring()
  if not isMonitoring then
    return
  end

  -- Note: We don't unregister listeners as they are harmless when the window is closed
  -- They will simply not log anything since the window is hidden
  isMonitoring = false
end

function AutoLFM.Debug.DebugWindow.IsMonitoring()
  return isMonitoring
end

--=============================================================================
-- Introspection Functions
--=============================================================================

-----------------------------------------------------------------------------
-- Print registered events and listeners with details
-----------------------------------------------------------------------------
function AutoLFM.Debug.DebugWindow.PrintEventListeners()
  if not AutoLFM.Core then return end
  if not AutoLFM.Core.Maestro then return end

  AutoLFM.Debug.DebugWindow.LogInfo("=== AutoLFM Event Listeners ===")
  AutoLFM.Debug.DebugWindow.LogInfo(" ")

  -- Get all events using introspection API
  local allEvents = AutoLFM.Core.Maestro.GetAllEvents()

  if not allEvents or table.getn(allEvents) == 0 then
    AutoLFM.Debug.DebugWindow.LogInfo("No events registered")
    return
  end

  local totalListeners = 0

  -- Display each event with its listeners
  for i = 1, table.getn(allEvents) do
    local eventInfo = allEvents[i]
    local listenerCount = eventInfo.listenerCount or 0

    -- Get listeners and count non-EventMonitor ones
    local listeners = nil
    local appListenerCount = 0
    if listenerCount > 0 then
      listeners = AutoLFM.Core.Maestro.GetEventListeners(eventInfo.key)
      for j = 1, table.getn(listeners) do
        if not string.find(listeners[j].key, "^EventMonitor%.") then
          appListenerCount = appListenerCount + 1
        end
      end
    end

    totalListeners = totalListeners + appListenerCount

    -- Event header
    local header = "[" .. eventInfo.id .. "] " .. eventInfo.key .. " (" .. appListenerCount .. " listener" .. (appListenerCount > 1 and "s" or "") .. ")"
    AutoLFM.Debug.DebugWindow.LogInfo(header)

    -- Show description if available
    if eventInfo.description and eventInfo.description ~= "No description" then
      AutoLFM.Debug.DebugWindow.LogInfo("  Description: " .. eventInfo.description)
    end

    -- Display listeners (excluding EventMonitor listeners)
    if listeners and appListenerCount > 0 then
      for j = 1, table.getn(listeners) do
        local listener = listeners[j]

        -- Skip EventMonitor listeners
        if not string.find(listener.key, "^EventMonitor%.") then
          local listenerInfo = "  [" .. listener.id .. "] " .. listener.key

          if listener.description and listener.description ~= "No description" then
            listenerInfo = listenerInfo .. " - " .. listener.description
          end

          AutoLFM.Debug.DebugWindow.LogInfo(listenerInfo)
        end
      end
    end

    AutoLFM.Debug.DebugWindow.LogInfo(" ")
  end

  local total = "Total: " .. table.getn(allEvents) .. " event" .. (table.getn(allEvents) > 1 and "s" or "") ..
                ", " .. totalListeners .. " listener" .. (totalListeners > 1 and "s" or "")
  AutoLFM.Debug.DebugWindow.LogInfo(total)
end

-----------------------------------------------------------------------------
-- Print registered commands
-----------------------------------------------------------------------------
function AutoLFM.Debug.DebugWindow.PrintCommands()
  if not AutoLFM.Core then return end
  if not AutoLFM.Core.Maestro then return end

  AutoLFM.Debug.DebugWindow.LogInfo("=== AutoLFM Commands ===")
  AutoLFM.Debug.DebugWindow.LogInfo(" ")

  -- Get all commands using introspection API
  local allCommands = AutoLFM.Core.Maestro.GetAllCommands()

  if not allCommands or table.getn(allCommands) == 0 then
    AutoLFM.Debug.DebugWindow.LogInfo("No commands registered")
    return
  end

  -- Already sorted by numeric ID from GetAllCommands()
  -- Display each command with details
  for i = 1, table.getn(allCommands) do
    local cmd = allCommands[i]
    local cmdInfo = "[" .. cmd.id .. "] " .. cmd.key

    if cmd.description and cmd.description ~= "No description" then
      cmdInfo = cmdInfo .. " - " .. cmd.description
    end

    AutoLFM.Debug.DebugWindow.LogInfo(cmdInfo)
  end

  AutoLFM.Debug.DebugWindow.LogInfo(" ")
  local total = "Total: " .. table.getn(allCommands) .. " command" .. (table.getn(allCommands) > 1 and "s" or "")
  AutoLFM.Debug.DebugWindow.LogInfo(total)
end

--=============================================================================
-- Legacy API Compatibility (for external code that might reference EventMonitor)
--=============================================================================
AutoLFM.Debug.EventMonitor = {
  Start = function() AutoLFM.Debug.DebugWindow.StartMonitoring() end,
  Stop = function() AutoLFM.Debug.DebugWindow.StopMonitoring() end,
  IsMonitoring = function() return AutoLFM.Debug.DebugWindow.IsMonitoring() end
}

-- Legacy functions for external references
AutoLFM.Debug.MonitorAllEvents = function() AutoLFM.Debug.DebugWindow.StartMonitoring() end
AutoLFM.Debug.StopMonitoring = function() AutoLFM.Debug.DebugWindow.StopMonitoring() end
AutoLFM.Debug.PrintEventListeners = function() AutoLFM.Debug.DebugWindow.PrintEventListeners() end
AutoLFM.Debug.PrintCommands = function() AutoLFM.Debug.DebugWindow.PrintCommands() end

--=============================================================================
-- Initialize (called automatically on load)
--=============================================================================
function AutoLFM.Debug.DebugWindow.Init()
  -- Nothing to do on init, window is created on demand
end
