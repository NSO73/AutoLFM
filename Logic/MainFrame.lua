--=============================================================================
-- AutoLFM: MainFrame
--   Main window management, tab switching, and content display
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.MainFrame = AutoLFM.Logic.MainFrame or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local currentBottomTab = 1
local currentLineTab = 0
local contentFrames = {}

-- Content panel mapping
local BOTTOM_TAB_CONTENT = {
    "Dungeons",
    "Raids",
    "Quests",
    "Broadcasts"
}

local LINE_TAB_CONTENT = {
    [1] = "Presets",
    [4] = "Options",
    [5] = "AutoInvite"  -- Special case
}

--=============================================================================
-- CONTENT FRAME MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Initialize Content Frames
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.InitializeContentFrames()
    local parent = getglobal("AutoLFM_MainFrame_Content")
    if not parent then
        AutoLFM.Core.Utils.PrintError("MainFrame: Content parent not found")
        return
    end

    -- Create all content frames
    for _, contentName in ipairs(BOTTOM_TAB_CONTENT) do
        local templateName = "AutoLFM_Content_" .. contentName
        local frameName = "AutoLFM_MainFrame_Content_" .. contentName

        -- Create frame from template
        local contentFrame = CreateFrame("Frame", frameName, parent, templateName)
        contentFrame:SetAllPoints(parent)
        contentFrame:Hide()

        contentFrames[contentName] = contentFrame
    end

    -- Create line tab content frames
    for tabId, contentName in pairs(LINE_TAB_CONTENT) do
        if contentName ~= "AutoInvite" then
            local templateName = "AutoLFM_Content_" .. contentName
            local frameName = "AutoLFM_MainFrame_Content_" .. contentName

            if not contentFrames[contentName] then
                local contentFrame = CreateFrame("Frame", frameName, parent, templateName)
                contentFrame:SetAllPoints(parent)
                contentFrame:Hide()

                contentFrames[contentName] = contentFrame
            end
        end
    end
end

--=============================================================================
-- TAB SELECTION
--=============================================================================

-----------------------------------------------------------------------------
-- Select Bottom Tab
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.SelectBottomTab(tabId)
    if tabId == currentBottomTab and currentLineTab == 0 then
        return
    end

    currentBottomTab = tabId
    currentLineTab = 0

    -- Update tab visuals
    AutoLFM.Logic.MainFrame.UpdateBottomTabVisuals(tabId)

    -- Uncheck all line tabs
    AutoLFM.Logic.MainFrame.UncheckAllLineTabs()

    -- Show appropriate content
    local contentName = BOTTOM_TAB_CONTENT[tabId]
    AutoLFM.Logic.MainFrame.ShowContent(contentName)

    -- Emit event
    AutoLFM.Core.Maestro.Emit("UI.BottomTab.Selected", tabId, contentName)
end

-----------------------------------------------------------------------------
-- Select Line Tab
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.SelectLineTab(tabId)
    if tabId == currentLineTab then
        -- Uncheck and return to current bottom tab
        currentLineTab = 0
        AutoLFM.Logic.MainFrame.SelectBottomTab(currentBottomTab)
        return
    end

    currentLineTab = tabId

    -- Update line tab visuals
    AutoLFM.Logic.MainFrame.UpdateLineTabVisuals(tabId)

    -- Show appropriate content
    local contentName = LINE_TAB_CONTENT[tabId]
    if contentName then
        AutoLFM.Logic.MainFrame.ShowContent(contentName)

        -- Dispatch event
        AutoLFM.Core.Maestro.Dispatch("UI.LineTab.Selected", tabId, contentName)
    end
end

--=============================================================================
-- VISUAL UPDATES
--=============================================================================

-----------------------------------------------------------------------------
-- Update Bottom Tab Visuals
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.UpdateBottomTabVisuals(selectedTab)
    for i = 1, 4 do
        local tab = getglobal("AutoLFM_MainFrame_Tab" .. i)
        if tab then
            local bg = tab:GetRegions()
            local highlight = getglobal(tab:GetName() .. "_Highlight")

            if i == selectedTab then
                -- Active tab
                if bg then
                    bg:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Tabs\\BottomTabActive")
                end
                if highlight then
                    highlight:Hide()
                end

                -- Update text color
                local _, _, _, _, text = tab:GetRegions()
                if text then
                    text:SetTextColor(1, 1, 1)
                end
            else
                -- Inactive tab
                if bg then
                    bg:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Tabs\\BottomTabInactive")
                end

                -- Update text color
                local _, _, _, _, text = tab:GetRegions()
                if text then
                    text:SetTextColor(1, 0.82, 0)
                end
            end
        end
    end
end

-----------------------------------------------------------------------------
-- Update Line Tab Visuals
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.UpdateLineTabVisuals(selectedTab)
    -- Uncheck all line tabs first
    AutoLFM.Logic.MainFrame.UncheckAllLineTabs()

    -- Check the selected tab
    local tab = getglobal("AutoLFM_MainFrame_LineTab" .. selectedTab)
    if tab and tab.SetChecked then
        tab:SetChecked(1)
    end
end

-----------------------------------------------------------------------------
-- Uncheck All Line Tabs
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.UncheckAllLineTabs()
    for _, tabId in ipairs({1, 2, 4, 5}) do
        local tab = getglobal("AutoLFM_MainFrame_LineTab" .. tabId)
        if tab and tab.SetChecked then
            tab:SetChecked(nil)
        end
    end
end

--=============================================================================
-- CONTENT DISPLAY
--=============================================================================

-----------------------------------------------------------------------------
-- Show Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.ShowContent(contentName)
    -- Hide all content frames
    for _, frame in pairs(contentFrames) do
        frame:Hide()
    end

    -- Show selected content
    local frame = contentFrames[contentName]
    if frame then
        frame:Show()
    end
end

-----------------------------------------------------------------------------
-- Refresh Current Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.RefreshCurrentContent()
    -- Emit refresh for current content
    if currentLineTab > 0 then
        local contentName = LINE_TAB_CONTENT[currentLineTab]
        if contentName then
            AutoLFM.Core.Maestro.Emit("UI.Content.Refresh", contentName)
        end
    else
        local contentName = BOTTOM_TAB_CONTENT[currentBottomTab]
        if contentName then
            AutoLFM.Core.Maestro.Emit("UI.Content.Refresh", contentName)
        end
    end
end

--=============================================================================
-- PUBLIC API
--=============================================================================

-----------------------------------------------------------------------------
-- Toggle Main Frame
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.Toggle()
    local frame = getglobal("AutoLFM_MainFrame")
    if frame then
        if frame:IsVisible() then
            HideUIPanel(frame)
        else
            ShowUIPanel(frame)
        end
    end
end

-----------------------------------------------------------------------------
-- Show Main Frame
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.Show()
    local frame = getglobal("AutoLFM_MainFrame")
    if frame then
        ShowUIPanel(frame)
    end
end

-----------------------------------------------------------------------------
-- Hide Main Frame
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.Hide()
    local frame = getglobal("AutoLFM_MainFrame")
    if frame then
        HideUIPanel(frame)
    end
end

-----------------------------------------------------------------------------
-- Update Start Button
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.UpdateStartButton(isRunning)
    local button = getglobal("AutoLFM_MainFrame_MainButton")
    if button then
        if isRunning then
            button:SetText("Stop")
            button:Enable()
        else
            button:SetText("Start")
            button:Enable()
        end
    end
end

-----------------------------------------------------------------------------
-- Update Message Preview
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.UpdateMessagePreview(message)
    local preview = getglobal("AutoLFM_MainFrame_MessagePreview_Text")
    if preview then
        if message and message ~= "" then
            preview:SetText(message)

            -- Show preview button
            local button = getglobal("AutoLFM_MainFrame_MessagePreview_Button")
            if button then
                button:Show()
            end
        else
            preview:SetText("")

            -- Hide preview button
            local button = getglobal("AutoLFM_MainFrame_MessagePreview_Button")
            if button then
                button:Hide()
            end
        end
    end
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.RegisterCommands()
    -- Toggle main frame
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "MainFrame.Toggle",
        description = "Toggle main frame visibility",
        handler = function()
            AutoLFM.Logic.MainFrame.Toggle()
        end
    })

    -- Show main frame
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "MainFrame.Show",
        description = "Show main frame",
        handler = function()
            AutoLFM.Logic.MainFrame.Show()
        end
    })

    -- Hide main frame
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "MainFrame.Hide",
        description = "Hide main frame",
        handler = function()
            AutoLFM.Logic.MainFrame.Hide()
        end
    })
end

--=============================================================================
-- EVENT LISTENERS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Event Listeners
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.RegisterEventListeners()
    -- Listen for broadcast state changes
    AutoLFM.Core.Maestro.On("Broadcaster.StateChanged", function(isRunning)
        AutoLFM.Logic.MainFrame.UpdateStartButton(isRunning)
    end, {
        key = "MainFrame.UpdateStartButton",
        description = "Update start/stop button based on broadcast state"
    })

    -- Listen for message preview updates
    AutoLFM.Core.Maestro.On("Messages.PreviewUpdated", function(message)
        AutoLFM.Logic.MainFrame.UpdateMessagePreview(message)
    end, {
        key = "Messages.UpdatePreview",
        description = "Update message preview display"
    })
end

--=============================================================================
-- UI HANDLERS
--=============================================================================

-- Create UI namespace for XML callbacks
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.MainFrame = AutoLFM.UI.MainFrame or {}

local MainFrameUI = AutoLFM.UI.MainFrame

-----------------------------------------------------------------------------
-- UI Lifecycle
-----------------------------------------------------------------------------
function MainFrameUI.OnLoad(frame)
    -- Initialize content frames
    AutoLFM.Logic.MainFrame.InitializeContentFrames()

    -- Show default tab
    AutoLFM.Logic.MainFrame.SelectBottomTab(1)
end

function MainFrameUI.OnShow(frame)
    -- Refresh current content
    AutoLFM.Logic.MainFrame.RefreshCurrentContent()

    -- Emit show event
    AutoLFM.Core.Maestro.Emit("UI.MainFrame.Shown")
end

function MainFrameUI.OnHide(frame)
    -- Emit hide event
    AutoLFM.Core.Maestro.Emit("UI.MainFrame.Hidden")
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("mainframe.init", function()
    AutoLFM.Logic.MainFrame.RegisterCommands()
    AutoLFM.Logic.MainFrame.RegisterEventListeners()
end, {
    key = "MainFrame.Init",
    description = "Initialize main frame commands and event listeners"
})
