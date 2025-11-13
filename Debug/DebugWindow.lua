--=============================================================================
-- AutoLFM: Debug Window
--   Real-time debug console with action logging and copy functionality
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Debug = AutoLFM.Debug or {}
AutoLFM.Debug.DebugWindow = AutoLFM.Debug.DebugWindow or {}

local M = AutoLFM.Debug.DebugWindow

--=============================================================================
-- Private State
--=============================================================================
local debugFrame = nil
local logBuffer = {}
local maxLogLines = 500
local isEnabled = false

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
  local lineHeight = 14 -- Approximate height per line
  local calculatedHeight = lineCount * lineHeight
  local minHeight = scrollFrame:GetHeight()

  editBox:SetHeight(math.max(calculatedHeight, minHeight))

  if scrollFrame and scrollFrame.ScrollToBottom then
    scrollFrame:ScrollToBottom()
  end
end

--=============================================================================
-- Public Logging API
--=============================================================================
function M.LogEvent(eventName, ...)
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

function M.LogCommand(commandName, ...)
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

function M.LogError(message)
  if not message then return end

  local line = FormatLogLine("ERROR", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function M.LogWarning(message)
  if not message then return end

  local line = FormatLogLine("WARNING", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function M.LogInfo(message)
  if not message then return end

  local line = FormatLogLine("INFO", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function M.LogAction(message)
  if not message then return end

  local line = FormatLogLine("ACTION", message)
  AddToBuffer(line)

  if isEnabled then
    UpdateDisplay()
  end
end

function M.LogListener(message)
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
function M.Show()
  if not debugFrame then
    M.CreateFrame()
  end

  if debugFrame then
    debugFrame:Show()
  end
  isEnabled = true

  -- Update display with all buffered logs
  UpdateDisplay()

  M.LogInfo("Debug window opened")
end

function M.Hide()
  if debugFrame then
    debugFrame:Hide()
  end

  isEnabled = false
end

function M.Toggle()
  if debugFrame and debugFrame:IsVisible() then
    M.Hide()
  else
    M.Show()
  end
end

function M.IsVisible()
  return debugFrame and debugFrame:IsVisible() or false
end

function M.Clear()
  logBuffer = {}
  UpdateDisplay()
  M.LogInfo("Debug log cleared")
end

--=============================================================================
-- Frame Creation
--=============================================================================
function M.CreateFrame()
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
    M.Hide()
  end)

  -- Clear Button
  local clearButton = CreateFrame("Button", "AutoLFM_DebugWindow_ClearButton", debugFrame, "UIPanelButtonTemplate")
  clearButton:SetWidth(80)
  clearButton:SetHeight(22)
  clearButton:SetPoint("BOTTOMLEFT", debugFrame, "BOTTOMLEFT", 15, 15)
  clearButton:SetText("Clear")
  clearButton:SetScript("OnClick", function()
    M.Clear()
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
    if AutoLFM.Debug and AutoLFM.Debug.PrintEventListeners then
      AutoLFM.Debug.PrintEventListeners()
    else
      if AutoLFM.Core and AutoLFM.Core.Utils then
        AutoLFM.Core.Utils.PrintError("Debug module not fully loaded")
      end
    end
  end)

  -- Commands Button
  local commandsButton = CreateFrame("Button", "AutoLFM_DebugWindow_CommandsButton", debugFrame, "UIPanelButtonTemplate")
  commandsButton:SetWidth(80)
  commandsButton:SetHeight(22)
  commandsButton:SetPoint("LEFT", eventsButton, "RIGHT", 5, 0)
  commandsButton:SetText("Commands")
  commandsButton:SetScript("OnClick", function()
    if AutoLFM.Debug and AutoLFM.Debug.PrintCommands then
      AutoLFM.Debug.PrintCommands()
    else
      if AutoLFM.Core and AutoLFM.Core.Utils then
        AutoLFM.Core.Utils.PrintError("Debug module not fully loaded")
      end
    end
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
    local scrollBar = getglobal("AutoLFM_DebugWindow_ScrollFrameScrollBar")
    if scrollBar and scrollBar.GetMaxValue then
      local maxValue = scrollBar:GetMaxValue()
      if maxValue and maxValue > 0 then
        scrollBar:SetValue(maxValue)
      end
    end
  end

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
-- Initialize (called automatically on load)
--=============================================================================
function M.Init()
  -- Nothing to do on init, window is created on demand
end
