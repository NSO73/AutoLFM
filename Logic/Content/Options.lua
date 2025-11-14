--=============================================================================
-- AutoLFM: Options
--   Global options management and persistence
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Options = AutoLFM.Logic.Content.Options or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local options = {
    minimapVisible = true,
    darkMode = false,
    presetsCondensed = false,
    testMode = false,
    debugMode = false,
    defaultPanel = "dungeons",
    dungeonFilters = {}
}

--=============================================================================
-- INITIALIZATION AND LOADING
--=============================================================================

-----------------------------------------------------------------------------
-- Load Options from Persistent Storage
--   Loads all options from saved data on startup
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.LoadOptions()
    if not AutoLFM.Core or not AutoLFM.Core.Persistent then return end

    -- Load minimap visibility
    options.minimapVisible = not AutoLFM.Core.Persistent.Get("minimapHidden", false)

    -- Load dark mode
    if AutoLFM.Core.Persistent.GetDarkMode then
        options.darkMode = AutoLFM.Core.Persistent.GetDarkMode()
    end

    -- Load presets view mode
    options.presetsCondensed = AutoLFM.Core.Persistent.Get("presetsCondensed", false)

    -- Load test mode
    options.testMode = AutoLFM.Core.Persistent.Get("testMode", false)

    -- Debug mode is NOT persistent, always starts as false
    options.debugMode = false

    -- Load default panel
    if AutoLFM.Core.Persistent.GetDefaultPanel then
        options.defaultPanel = AutoLFM.Core.Persistent.GetDefaultPanel() or "dungeons"
    end

    -- Load dungeon filters
    local filters = AutoLFM.Core.Persistent.Get("dungeonFilters")
    if filters then
        if AutoLFM.Core.Persistent.DeepCopy then
            options.dungeonFilters = AutoLFM.Core.Persistent.DeepCopy(filters)
        else
            options.dungeonFilters = filters
        end
    end
end

--=============================================================================
-- GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Get Minimap Visibility
--   @return boolean: true if minimap button is visible
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetMinimapVisible()
    return options.minimapVisible
end

-----------------------------------------------------------------------------
-- Get Dark Mode State
--   @return boolean: true if dark mode is enabled
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetDarkMode()
    return options.darkMode
end

-----------------------------------------------------------------------------
-- Get Presets Condensed View
--   @return boolean: true if condensed view is enabled
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetPresetsCondensed()
    return options.presetsCondensed
end

-----------------------------------------------------------------------------
-- Get Test Mode State
--   @return boolean: true if test mode is enabled
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetTestMode()
    return options.testMode
end

-----------------------------------------------------------------------------
-- Get Debug Mode State
--   @return boolean: true if debug mode is enabled
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetDebugMode()
    return options.debugMode
end

-----------------------------------------------------------------------------
-- Get Default Panel
--   @return string: Default panel name (dungeons, raids, quests, broadcasts, presets, options)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetDefaultPanel()
    return options.defaultPanel
end

-----------------------------------------------------------------------------
-- Get Dungeon Filters
--   @return table: Dungeon filter states by color ID
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetDungeonFilters()
    return options.dungeonFilters
end

-----------------------------------------------------------------------------
-- Get All Options
--   @return table: Complete options table
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetAllOptions()
    return options
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.RegisterCommands()
    -- Set minimap visible command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.SetMinimapVisible",
        description = "Set minimap button visibility",
        handler = function(isVisible)
            if isVisible == nil then return end

            options.minimapVisible = isVisible
            AutoLFM.Core.Persistent.Set("minimapHidden", not isVisible)

            -- Update minimap button
            if AutoLFM.Components and AutoLFM.Components.MinimapButton then
                if isVisible then
                    AutoLFM.Components.MinimapButton.Show()
                else
                    AutoLFM.Components.MinimapButton.Hide()
                end
            end

            AutoLFM.Core.Maestro.Emit("Options.MinimapVisibilityChanged", isVisible)
        end
    })

    -- Set dark mode command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.SetDarkMode",
        description = "Enable or disable dark mode",
        handler = function(isEnabled)
            if isEnabled == nil then return end

            options.darkMode = isEnabled
            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.SetDarkMode then
                AutoLFM.Core.Persistent.SetDarkMode(isEnabled)
            end

            if isEnabled then
                AutoLFM.Core.Utils.PrintInfo("Dark mode enabled. Reload UI to apply changes.")
            else
                AutoLFM.Core.Utils.PrintInfo("Dark mode disabled. Reload UI to apply changes.")
            end

            AutoLFM.Core.Maestro.Emit("Options.DarkModeChanged", isEnabled)
        end
    })

    -- Set presets condensed view command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.SetPresetsCondensed",
        description = "Enable or disable condensed presets view",
        handler = function(isEnabled)
            if isEnabled == nil then return end

            options.presetsCondensed = isEnabled
            AutoLFM.Core.Persistent.Set("presetsCondensed", isEnabled)

            if isEnabled then
                AutoLFM.Core.Utils.PrintInfo("Presets condensed view enabled")
            else
                AutoLFM.Core.Utils.PrintInfo("Presets full view enabled")
            end

            AutoLFM.Core.Maestro.Emit("Options.PresetsCondensedChanged", isEnabled)
        end
    })

    -- Set test mode command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.SetTestMode",
        description = "Enable or disable test/dry-run mode",
        handler = function(isEnabled)
            if isEnabled == nil then return end

            options.testMode = isEnabled
            AutoLFM.Core.Persistent.Set("testMode", isEnabled)

            if isEnabled then
                AutoLFM.Core.Utils.PrintInfo("Test mode enabled - broadcasts will be simulated")
            else
                AutoLFM.Core.Utils.PrintInfo("Test mode disabled - broadcasts will be sent normally")
            end

            AutoLFM.Core.Maestro.Emit("Options.TestModeChanged", isEnabled)
        end
    })

    -- Set debug mode command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.SetDebugMode",
        description = "Enable or disable debug mode (session-only)",
        handler = function(isEnabled)
            if isEnabled == nil then return end

            options.debugMode = isEnabled
            -- Do NOT save to Persistent - debug mode is session-only

            -- Show/hide debug window
            if AutoLFM.Debug and AutoLFM.Debug.DebugWindow then
                if isEnabled then
                    AutoLFM.Debug.DebugWindow.Show()
                else
                    AutoLFM.Debug.DebugWindow.Hide()
                end
            end

            AutoLFM.Core.Maestro.Emit("Options.DebugModeChanged", isEnabled)
        end
    })

    -- Set default panel command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.SetDefaultPanel",
        description = "Set the default panel to open (dungeons, raids, quests, broadcasts, presets, options)",
        handler = function(panelName)
            if not panelName then return end

            options.defaultPanel = panelName
            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.SetDefaultPanel then
                AutoLFM.Core.Persistent.SetDefaultPanel(panelName)
            end

            AutoLFM.Core.Utils.PrintInfo("Default panel set to: " .. panelName)
            AutoLFM.Core.Maestro.Emit("Options.DefaultPanelChanged", panelName)
        end
    })

    -- Toggle dungeon filter command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.ToggleDungeonFilter",
        description = "Toggle dungeon filter by color ID",
        handler = function(colorId)
            if not colorId then return end

            -- Toggle filter state
            local currentState = options.dungeonFilters[colorId]
            local newState = not currentState
            options.dungeonFilters[colorId] = newState

            -- Persist the change
            AutoLFM.Core.Persistent.Set("dungeonFilters", options.dungeonFilters)

            AutoLFM.Core.Maestro.Emit("Options.DungeonFilterChanged", colorId, newState)
        end
    })

    -- Reset all dungeon filters command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Options.ResetAllFilters",
        description = "Reset all dungeon filters to default state",
        handler = function()
            -- Reset all filters to enabled (default state)
            options.dungeonFilters = {}
            AutoLFM.Core.Persistent.Set("dungeonFilters", {})

            -- Emit events for each filter
            if AutoLFM.Core.Constants and AutoLFM.Core.Constants.DUNGEON_FILTERS then
                local filters = AutoLFM.Core.Constants.DUNGEON_FILTERS
                for i = 1, table.getn(filters) do
                    AutoLFM.Core.Maestro.Emit("Options.DungeonFilterChanged", filters[i].id, true)
                end
            end

            AutoLFM.Core.Utils.PrintSuccess("All dungeon filters reset to enabled")
            AutoLFM.Core.Maestro.Emit("Options.AllFiltersReset")
        end
    })
end

--=============================================================================
-- UI HANDLERS
--=============================================================================

-- Create UI namespace for XML callbacks
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Options = AutoLFM.UI.Content.Options or {}

local OptionsUI = AutoLFM.UI.Content.Options
local uiFrame = nil

-- Option keys mapping
local OPTIONS = {
    "AutoInvite",
    "AutoAccept",
    "ShowMinimap",
    "PlaySound",
    "DisableInRaid",
    "StopWhenFull",
    "DebugMode"
}

-----------------------------------------------------------------------------
-- UI Lifecycle
-----------------------------------------------------------------------------
function OptionsUI.OnLoad(self)
    uiFrame = self
end

function OptionsUI.OnShow(self)
    OptionsUI.Refresh()
end

-----------------------------------------------------------------------------
-- Event Handlers
-----------------------------------------------------------------------------
function OptionsUI.OnOptionToggle(optionKey, isEnabled)
    -- Dispatch option change command
    AutoLFM.Core.Maestro.Dispatch("Options.Set", optionKey, isEnabled)
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function OptionsUI.Refresh()
    -- Request data refresh from Logic layer
    AutoLFM.Core.Maestro.Dispatch("UI.Options.Refresh", uiFrame)
end

function OptionsUI.SetOption(optionKey, isEnabled)
    local checkbox = getglobal(uiFrame:GetName().."_"..optionKey)
    if checkbox then
        checkbox:SetChecked(isEnabled and 1 or nil)
    end
end

function OptionsUI.GetAllOptions()
    local options = {}
    for _, key in ipairs(OPTIONS) do
        local checkbox = getglobal(uiFrame:GetName().."_"..key)
        if checkbox then
            options[key] = checkbox:GetChecked() == 1
        end
    end
    return options
end

-----------------------------------------------------------------------------
-- Event Listeners
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.On("Options.Changed", function()
    if uiFrame and uiFrame:IsVisible() then
        OptionsUI.Refresh()
    end
end, {
    key = "OptionsUI.Refresh",
    description = "Refreshes options UI when settings change"
})

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("options.init", function()
    AutoLFM.Logic.Content.Options.LoadOptions()
    AutoLFM.Logic.Content.Options.RegisterCommands()
end, {
    name = "Options Management",
    description = "Load and register options commands"
})
