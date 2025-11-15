--=============================================================================
-- AutoLFM: MainFrame Logic
--   Main window and tab management
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.MainFrame = {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local Debug = AutoLFM.Components.DebugWindow

local currentBottomTab = 1  -- 1=Dungeons, 2=Raids, 3=Quests, 4=Broadcasts
local currentSideTab = nil  -- nil or 2=Presets, 4=AutoInvite, 5=Options

-- Tab content mapping
local BOTTOM_TABS = {
    "Dungeons",
    "Raids",
    "Quests",
    "Broadcasts"
}

local SIDE_TABS = {
    [2] = "Presets",
    [4] = "AutoInvite",
    [5] = "Options"
}

--=============================================================================
-- PUBLIC API
--=============================================================================

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
-- Toggle Main Frame
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.Toggle()
    local frame = getglobal("AutoLFM_MainFrame")
    if not frame then
        return
    end

    if frame:IsVisible() then
        AutoLFM.Logic.MainFrame.Hide()
    else
        AutoLFM.Logic.MainFrame.Show()
    end
end

--=============================================================================
-- TAB MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Select Bottom Tab
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.SelectBottomTab(tabIndex)
    if tabIndex < 1 or tabIndex > 4 then
        return
    end

    currentBottomTab = tabIndex
    currentSideTab = nil

    -- Log tab selection with name
    Debug.LogAction("Show " .. BOTTOM_TABS[tabIndex] .. " content")

    AutoLFM.Logic.MainFrame.UpdateTabVisuals()
    AutoLFM.Logic.MainFrame.UpdateContent()
end

-----------------------------------------------------------------------------
-- Select Side Tab
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.SelectSideTab(tabIndex)
    if not SIDE_TABS[tabIndex] then
        return
    end

    -- No toggle - just select the tab
    currentSideTab = tabIndex

    -- Log tab selection with name
    Debug.LogAction("Show " .. SIDE_TABS[tabIndex] .. " content")

    AutoLFM.Logic.MainFrame.UpdateTabVisuals()
    AutoLFM.Logic.MainFrame.UpdateContent()
end

-----------------------------------------------------------------------------
-- Update Tab Visuals
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.UpdateTabVisuals()
    -- Update bottom tabs
    for i = 1, 4 do
        local tab = getglobal("AutoLFM_MainFrame_Tab" .. i)
        if tab then
            local bg = tab:GetRegions()
            local highlight = getglobal(tab:GetName() .. "_Highlight")
            local text = getglobal(tab:GetName() .. "_Text")

            if i == currentBottomTab and not currentSideTab then
                -- Active tab
                if bg then
                    bg:SetTexture("Interface\\AddOns\\AutoLFM3\\UI\\Textures\\Tabs\\BottomTabActive")
                end
                if highlight then
                    highlight:Hide()
                end
                if text then
                    text:SetTextColor(1, 1, 1)  -- White
                end
            else
                -- Inactive tab
                if bg then
                    bg:SetTexture("Interface\\AddOns\\AutoLFM3\\UI\\Textures\\Tabs\\BottomTabInactive")
                end
                if highlight then
                    highlight:Hide()  -- Cache le highlight par défaut
                end
                if text then
                    text:SetTextColor(1, 0.82, 0)  -- Gold
                end
            end
        end
    end

    -- Update side tabs
    for _, tabIndex in ipairs({2, 4, 5}) do
        local tab = getglobal("AutoLFM_MainFrame_SideTab" .. tabIndex)
        if tab and tab.SetChecked then
            if currentSideTab == tabIndex then
                tab:SetChecked(1)
            else
                tab:SetChecked(nil)
            end
        end
    end
end

-----------------------------------------------------------------------------
-- Update Content Display
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.UpdateContent()
    -- Determine active content
    local activeContent
    if currentSideTab and SIDE_TABS[currentSideTab] then
        activeContent = SIDE_TABS[currentSideTab]
    else
        activeContent = BOTTOM_TABS[currentBottomTab]
    end

    -- Hide all content frames
    for _, contentName in ipairs(BOTTOM_TABS) do
        local frame = getglobal("AutoLFM_MainFrameContent_" .. contentName)
        if frame then
            frame:Hide()
        end
    end

    for _, contentName in pairs(SIDE_TABS) do
        local frame = getglobal("AutoLFM_MainFrameContent_" .. contentName)
        if frame then
            frame:Hide()
        end
    end

    -- Show active content frame
    local activeFrame = getglobal("AutoLFM_MainFrameContent_" .. activeContent)
    if activeFrame then
        activeFrame:Show()
        Debug.LogInfo("Showing content frame: " .. activeContent)
    else
        Debug.LogWarning("Content frame not found: " .. activeContent)
    end
end

--=============================================================================
-- BUTTON ACTIONS
--=============================================================================

-----------------------------------------------------------------------------
-- Clear All Action
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.ClearAll()
    -- TODO: Implement clear all logic
    Debug.LogWarning("Clear All - Not implemented yet")
end

-----------------------------------------------------------------------------
-- Add Preset Action
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.AddPreset()
    -- TODO: Implement add preset logic
    Debug.LogWarning("Add Preset - Not implemented yet")
end

--=============================================================================
-- CONTENT FRAME MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Initialize Content Frames
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.InitializeContentFrames()
    local container = getglobal("AutoLFM_MainFrame_ContentContainer")
    if not container then
        if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogError then
            AutoLFM.Components.DebugWindow.LogError("MainFrame: ContentContainer not found")
        end
        return
    end

    -- List of all content frames to create
    local contentNames = {
        "Dungeons",
        "Raids",
        "Quests",
        "Broadcasts",
        "Presets",
        "Options",
        "AutoInvite"
    }

    -- Create content frames from virtual templates
    for _, contentName in ipairs(contentNames) do
        local templateName = "AutoLFM_Content_" .. contentName
        local frameName = "AutoLFM_MainFrameContent_" .. contentName

        -- Create frame from template
        local contentFrame = CreateFrame("Frame", frameName, container, templateName)
        if contentFrame then
            contentFrame:SetAllPoints(container)
            contentFrame:Hide()
            if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogInfo then
                AutoLFM.Components.DebugWindow.LogInfo("Created content frame: " .. contentName)
            end
        else
            if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogError then
                AutoLFM.Components.DebugWindow.LogError("Failed to create content frame: " .. contentName)
            end
        end
    end

    -- Show default content (Dungeons)
    AutoLFM.Logic.MainFrame.UpdateContent()
    AutoLFM.Logic.MainFrame.UpdateTabVisuals()
end

--=============================================================================
-- UI HANDLERS (for XML callbacks)
--=============================================================================

AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.MainFrame = {}

function AutoLFM.UI.MainFrame.OnLoad(frame)
    -- Setup UI panel
    UIPanelWindows[frame:GetName()] = { area = "left", pushable = 1 }
    tinsert(UISpecialFrames, frame:GetName())

    -- Initialize content frames
    AutoLFM.Logic.MainFrame.InitializeContentFrames()
end

function AutoLFM.UI.MainFrame.OnShow(frame)
    PlaySound("GAMEDIALOGOPEN")
end

function AutoLFM.UI.MainFrame.OnHide(frame)
    PlaySound("GAMEDIALOGCLOSE")
end

function AutoLFM.UI.MainFrame.OnBottomTabEnter(tabIndex)
    -- Only show highlight if tab is not active or if a side tab is selected
    if tabIndex ~= currentBottomTab or currentSideTab then
        local tab = getglobal("AutoLFM_MainFrame_Tab" .. tabIndex)
        if tab then
            local highlight = getglobal(tab:GetName() .. "_Highlight")
            if highlight then
                highlight:Show()
            end
        end
    end
end

function AutoLFM.UI.MainFrame.OnBottomTabLeave(tabIndex)
    local tab = getglobal("AutoLFM_MainFrame_Tab" .. tabIndex)
    if tab then
        local highlight = getglobal(tab:GetName() .. "_Highlight")
        if highlight then
            highlight:Hide()
        end
    end
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

AutoLFM.Core.Maestro.RegisterInit("MainFrame", function()
    -- Register commands
    AutoLFM.Core.Maestro.RegisterCommand("UI.Toggle", AutoLFM.Logic.MainFrame.Toggle)
    AutoLFM.Core.Maestro.RegisterCommand("UI.Show", AutoLFM.Logic.MainFrame.Show)
    AutoLFM.Core.Maestro.RegisterCommand("UI.Hide", AutoLFM.Logic.MainFrame.Hide)
    AutoLFM.Core.Maestro.RegisterCommand("Tabs.Select.Bottom", AutoLFM.Logic.MainFrame.SelectBottomTab, { silent = true })
    AutoLFM.Core.Maestro.RegisterCommand("Tabs.Select.Side", AutoLFM.Logic.MainFrame.SelectSideTab, { silent = true })
    AutoLFM.Core.Maestro.RegisterCommand("Tabs.Clear.All", AutoLFM.Logic.MainFrame.ClearAll)
    AutoLFM.Core.Maestro.RegisterCommand("Tabs.Add.Preset", AutoLFM.Logic.MainFrame.AddPreset)
end)
