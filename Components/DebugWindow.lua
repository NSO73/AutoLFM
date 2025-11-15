--=============================================================================
-- AutoLFM: Debug Window Component
--   Real-time debug console with action logging
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Components = AutoLFM.Components or {}
AutoLFM.Components.DebugWindow = {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local debugFrame = nil
local logBuffer = {}
local maxLogLines = 500
local isEnabled = false

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

local function GetTimestamp()
    local hour, minute = GetGameTime()
    return string.format("%02d:%02d", hour, minute)
end

local LOG_COLORS = {
    EVENT = "GREEN",
    COMMAND = "BLUE",
    ACTION = "PURPLE",
    ERROR = "RED",
    WARNING = "ORANGE",
    INFO = "WHITE",
    REGISTRY = "CYAN",
    TIMESTAMP = "GRAY"
}

local function FormatLogLine(category, message)
    local timestampColor = AutoLFM.Core.Common.GetColor(LOG_COLORS.TIMESTAMP)
    local categoryColor = AutoLFM.Core.Common.GetColor(LOG_COLORS[category] or LOG_COLORS.INFO)

    if not timestampColor or not categoryColor then
        return "[" .. GetTimestamp() .. "] [" .. category .. "] " .. message
    end

    local timestamp = "|cff" .. timestampColor.hex .. "[" .. GetTimestamp() .. "]|r"
    local coloredCategory = "|cff" .. categoryColor.hex .. "[" .. category .. "]|r"

    return timestamp .. " " .. coloredCategory .. " " .. message
end

local function AddToBuffer(line)
    table.insert(logBuffer, line)

    if table.getn(logBuffer) > maxLogLines then
        table.remove(logBuffer, 1)
    end
end

local function UpdateDisplay()
    if not debugFrame or not debugFrame:IsVisible() then
        return
    end

    local scrollFrame = getglobal("AutoLFM_DebugWindow_ScrollFrame")
    local editBox = getglobal("AutoLFM_DebugWindow_EditBox")

    if not editBox then
        return
    end

    local text = table.concat(logBuffer, "\n")
    editBox:SetText(text)

    -- Calculate height based on number of lines
    local lineCount = table.getn(logBuffer)
    local lineHeight = 14
    local calculatedHeight = lineCount * lineHeight
    local minHeight = scrollFrame:GetHeight()

    -- Use calculated height directly, don't add extra space
    if calculatedHeight > minHeight then
        editBox:SetHeight(calculatedHeight)
    else
        editBox:SetHeight(minHeight)
    end

    -- Update scroll child rect
    scrollFrame:UpdateScrollChildRect()

    -- Scroll to bottom - use max scroll value
    local scrollBar = getglobal("AutoLFM_DebugWindow_ScrollFrameScrollBar")
    if scrollBar then
        local _, maxValue = scrollBar:GetMinMaxValues()
        if maxValue and maxValue > 0 then
            scrollBar:SetValue(maxValue)
        end
    end
end

--=============================================================================
-- PUBLIC LOGGING API
--=============================================================================

function AutoLFM.Components.DebugWindow.LogEvent(eventName, ...)
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

    if isEnabled then
        UpdateDisplay()
    end
end

function AutoLFM.Components.DebugWindow.LogCommand(commandName, ...)
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

    if isEnabled then
        UpdateDisplay()
    end
end

function AutoLFM.Components.DebugWindow.LogError(message)
    local line = FormatLogLine("ERROR", message)
    AddToBuffer(line)

    if isEnabled then
        UpdateDisplay()
    end
end

function AutoLFM.Components.DebugWindow.LogWarning(message)
    local line = FormatLogLine("WARNING", message)
    AddToBuffer(line)

    if isEnabled then
        UpdateDisplay()
    end
end

function AutoLFM.Components.DebugWindow.LogInfo(message)
    local line = FormatLogLine("INFO", message)
    AddToBuffer(line)

    if isEnabled then
        UpdateDisplay()
    end
end

function AutoLFM.Components.DebugWindow.LogAction(message)
    local line = FormatLogLine("ACTION", message)
    AddToBuffer(line)

    if isEnabled then
        UpdateDisplay()
    end
end

function AutoLFM.Components.DebugWindow.LogRegistry(message)
    local line = FormatLogLine("REGISTRY", message)
    AddToBuffer(line)

    if isEnabled then
        UpdateDisplay()
    end
end

--=============================================================================
-- WINDOW MANAGEMENT
--=============================================================================

function AutoLFM.Components.DebugWindow.Show()
    if not debugFrame then
        AutoLFM.Components.DebugWindow.CreateFrame()
    end

    debugFrame:Show()
    isEnabled = true

    UpdateDisplay()

    AutoLFM.Components.DebugWindow.LogAction("Debug window opened")
end

function AutoLFM.Components.DebugWindow.Hide()
    if debugFrame then
        debugFrame:Hide()
    end

    isEnabled = false
    AutoLFM.Components.DebugWindow.LogAction("Debug window closed")
end

function AutoLFM.Components.DebugWindow.Toggle()
    if debugFrame and debugFrame:IsVisible() then
        AutoLFM.Components.DebugWindow.Hide()
    else
        AutoLFM.Components.DebugWindow.Show()
    end
end

function AutoLFM.Components.DebugWindow.Clear()
    -- Clear buffer completely
    logBuffer = {}

    local scrollFrame = getglobal("AutoLFM_DebugWindow_ScrollFrame")
    local editBox = getglobal("AutoLFM_DebugWindow_EditBox")
    local scrollBar = getglobal("AutoLFM_DebugWindow_ScrollFrameScrollBar")

    if not scrollFrame or not editBox then
        return
    end

    -- Reset editBox to empty state
    editBox:SetText("")
    editBox:SetHeight(scrollFrame:GetHeight())
    editBox:SetCursorPosition(0)
    editBox:ClearFocus()

    -- Update scroll child
    scrollFrame:UpdateScrollChildRect()

    -- Reset scroll to top
    if scrollBar then
        scrollBar:SetValue(0)
    end

    -- Add clear message
    AutoLFM.Components.DebugWindow.LogInfo("Debug log cleared")

    -- Force display update to show the message at the top
    if isEnabled then
        UpdateDisplay()
    end
end

function AutoLFM.Components.DebugWindow.ShowRegistry()
    -- Add registry info to debug log
    AutoLFM.Components.DebugWindow.LogRegistry("|cffffffff====================================|r")
    AutoLFM.Components.DebugWindow.LogRegistry("|cffffffffMAESTRO REGISTRY INFO|r")
    AutoLFM.Components.DebugWindow.LogRegistry("|cffffffff====================================|r")

    -- Commands Section
    local commands = AutoLFM.Core.Maestro.GetCommands()
    AutoLFM.Components.DebugWindow.LogRegistry("")
    AutoLFM.Components.DebugWindow.LogRegistry("|cff00aaffCOMMANDS (" .. table.getn(commands) .. " registered):|r")
    for i = 1, table.getn(commands) do
        local entry = commands[i]
        AutoLFM.Components.DebugWindow.LogRegistry("  |cff888888[" .. entry.id .. "]|r " .. entry.key)
    end

    -- Init Handlers Section
    local handlers = AutoLFM.Core.Maestro.GetInitHandlers()
    AutoLFM.Components.DebugWindow.LogRegistry("")
    AutoLFM.Components.DebugWindow.LogRegistry("|cff00ff00INIT HANDLERS / LISTENERS (" .. table.getn(handlers) .. " registered):|r")
    for i = 1, table.getn(handlers) do
        local entry = handlers[i]
        AutoLFM.Components.DebugWindow.LogRegistry("  |cff888888[" .. entry.id .. "]|r " .. entry.key)
    end

    AutoLFM.Components.DebugWindow.LogRegistry("")
    AutoLFM.Components.DebugWindow.LogRegistry("|cffffffff====================================|r")
end

--=============================================================================
-- FRAME CREATION
--=============================================================================

function AutoLFM.Components.DebugWindow.CreateFrame()
    if debugFrame then
        return
    end

    -- Main Frame
    debugFrame = CreateFrame("Frame", "AutoLFM_DebugWindow", UIParent)
    debugFrame:SetWidth(420)
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
        AutoLFM.Components.DebugWindow.Hide()
    end)

    -- Clear Button
    local clearButton = CreateFrame("Button", "AutoLFM_DebugWindow_ClearButton", debugFrame, "UIPanelButtonTemplate")
    clearButton:SetWidth(80)
    clearButton:SetHeight(22)
    clearButton:SetPoint("BOTTOMLEFT", debugFrame, "BOTTOMLEFT", 15, 15)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        AutoLFM.Components.DebugWindow.Clear()
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

    -- Registry Button
    local registryButton = CreateFrame("Button", "AutoLFM_DebugWindow_RegistryButton", debugFrame, "UIPanelButtonTemplate")
    registryButton:SetWidth(80)
    registryButton:SetHeight(22)
    registryButton:SetPoint("LEFT", selectAllButton, "RIGHT", 5, 0)
    registryButton:SetText("Registry")
    registryButton:SetScript("OnClick", function()
        AutoLFM.Components.DebugWindow.ShowRegistry()
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

    -- Make draggable
    debugFrame:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then
            this:StartMoving()
        end
    end)

    debugFrame:SetScript("OnMouseUp", function()
        this:StopMovingOrSizing()
    end)
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

AutoLFM.Core.Maestro.RegisterInit("DebugWindow", function()
    -- Register commands (silent because they log themselves with better context)
    AutoLFM.Core.Maestro.RegisterCommand("Debug.Toggle", AutoLFM.Components.DebugWindow.Toggle, { silent = true })
    AutoLFM.Core.Maestro.RegisterCommand("Debug.Show", AutoLFM.Components.DebugWindow.Show, { silent = true })
    AutoLFM.Core.Maestro.RegisterCommand("Debug.Hide", AutoLFM.Components.DebugWindow.Hide, { silent = true })
    AutoLFM.Core.Maestro.RegisterCommand("Debug.Clear", AutoLFM.Components.DebugWindow.Clear)
end)
