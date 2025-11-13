--=============================================================================
-- AutoLFM: Options
--   Options logic and state management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Options = AutoLFM.Logic.Content.Options or {}

-----------------------------------------------------------------------------
-- Private State (owned by this module)
-----------------------------------------------------------------------------
local options = {
  minimapVisible = true,
  darkUI = false,
  presetsCondensed = false,
  testMode = false,
  debugMode = false,
  dungeonFilters = {}  -- { [colorId] = true/false }
}

-----------------------------------------------------------------------------
-- Initialization (load from Persistent on startup)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.LoadOptions()
  options.minimapVisible = not AutoLFM.Core.Persistent.Get("minimapHidden", false)
  options.darkUI = AutoLFM.Core.Persistent.GetDarkMode()
  options.presetsCondensed = AutoLFM.Core.Persistent.Get("presetsCondensed", false)
  options.testMode = AutoLFM.Core.Persistent.Get("testMode", false)
  -- debugMode is NOT persistent, always starts as false
  options.debugMode = false

  -- Load dungeon filters
  local filters = AutoLFM.Core.Persistent.Get("dungeonFilters")
  if filters then
    options.dungeonFilters = AutoLFM.Core.Persistent.DeepCopy(filters)
  end
end

-----------------------------------------------------------------------------
-- Initialize Commands
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.Init()
  -- Minimap Visibility Command
  AutoLFM.Core.Maestro.RegisterCommand("Options.SetMinimapVisible", function(isVisible)
    options.minimapVisible = isVisible
    AutoLFM.Core.Persistent.Set("minimapHidden", not isVisible)

    -- Update minimap button visibility
    if AutoLFM.Components.MinimapButton then
      if isVisible then
        AutoLFM.Components.MinimapButton.Show()
      else
        AutoLFM.Components.MinimapButton.Hide()
      end
    end

    AutoLFM.Core.Maestro.EmitEvent("Options.MinimapVisibilityChanged", isVisible)
  end)

  -- Dark Mode Command
  AutoLFM.Core.Maestro.RegisterCommand("Options.SetDarkMode", function(isEnabled)
    options.darkUI = isEnabled
    AutoLFM.Core.Persistent.SetDarkMode(isEnabled)
    if isEnabled then
      AutoLFM.Core.Utils.PrintInfo("Dark UI enabled. Reload UI to apply changes.")
    else
      AutoLFM.Core.Utils.PrintInfo("Dark UI disabled. Reload UI to apply changes.")
    end

    AutoLFM.Core.Maestro.EmitEvent("Options.DarkModeChanged", isEnabled)
  end)

  -- Presets Condensed Command
  AutoLFM.Core.Maestro.RegisterCommand("Options.SetPresetsCondensed", function(isEnabled)
    options.presetsCondensed = isEnabled
    AutoLFM.Core.Persistent.SetPresetsCondensed(isEnabled)
    if isEnabled then
      AutoLFM.Core.Utils.PrintInfo("Presets condensed view enabled")
    else
      AutoLFM.Core.Utils.PrintInfo("Presets full view enabled")
    end

    -- Emit event to refresh Presets tab if it's currently displayed
    AutoLFM.Core.Maestro.EmitEvent("Presets.ViewModeChanged", isEnabled)
  end)

  -- Default Panel Command
  AutoLFM.Core.Maestro.RegisterCommand("Options.SetDefaultPanel", function(panelName)
    if not panelName then return end
    AutoLFM.Core.Persistent.SetDefaultPanel(panelName)

    -- Also update current tab immediately (not just at next reload)
    local bottomTabs = {"dungeons", "raids", "quests", "broadcasts"}
    local lineTabs = {"presets"}
    local isBottomTab = false
    local isLineTab = false

    for i = 1, table.getn(bottomTabs) do
      if bottomTabs[i] == panelName then
        isBottomTab = true
        break
      end
    end

    if not isBottomTab then
      for i = 1, table.getn(lineTabs) do
        if lineTabs[i] == panelName then
          isLineTab = true
          break
        end
      end
    end

    if isBottomTab then
      AutoLFM.Core.Maestro.DispatchCommand("MainFrame.SwitchToBottomTab", panelName)
    elseif isLineTab then
      AutoLFM.Core.Maestro.DispatchCommand("MainFrame.SwitchToLineTab", panelName)
    end

    AutoLFM.Core.Utils.PrintInfo("Default panel set to: " .. AutoLFM.Core.Utils.ColorizeText(panelName, "yellow"))
  end)

  -- Dry Run Command
  AutoLFM.Core.Maestro.RegisterCommand("Options.SetTestMode", function(isEnabled)
    options.testMode = isEnabled
    AutoLFM.Core.Persistent.Set("testMode", isEnabled)

    AutoLFM.Core.Maestro.EmitEvent("Options.TestModeChanged", isEnabled)
  end)

  -- Debug Command (NOT persistent, resets to false on reload)
  AutoLFM.Core.Maestro.RegisterCommand("Options.SetDebugMode", function(isEnabled)
    options.debugMode = isEnabled
    -- Do NOT save to Persistent - debug mode is session-only

    -- Open/Close Debug Window when Debug Mode changes
    if AutoLFM.Debug and AutoLFM.Debug.DebugWindow then
      if isEnabled then
        AutoLFM.Debug.DebugWindow.Show()
      else
        AutoLFM.Debug.DebugWindow.Hide()
      end
    end

    AutoLFM.Core.Maestro.EmitEvent("Options.DebugModeChanged", isEnabled)
  end)

  -- Dungeon Filter Command
  AutoLFM.Core.Maestro.RegisterCommand("Options.ToggleDungeonFilter", function(colorId)
    if not colorId then return end

    -- Toggle filter state
    local currentState = options.dungeonFilters[colorId]
    local newState = not currentState
    options.dungeonFilters[colorId] = newState

    -- Persist the change
    AutoLFM.Core.Persistent.Set("dungeonFilters", options.dungeonFilters)

    -- Emit event
    AutoLFM.Core.Maestro.EmitEvent("Dungeons.FilterChanged", colorId, newState)
  end)

  -- Reset All Filters Command
  AutoLFM.Core.Maestro.RegisterCommand("Options.ResetAllFilters", function()
    -- Reset all filters to enabled (default state)
    options.dungeonFilters = {}
    AutoLFM.Core.Persistent.Set("dungeonFilters", {})

    -- Emit events for each filter to update UI
    local filters = AutoLFM.Core.Constants.DUNGEON_FILTERS
    for i = 1, table.getn(filters) do
      AutoLFM.Core.Maestro.EmitEvent("Dungeons.FilterChanged", filters[i].id, true)
    end

    AutoLFM.Core.Utils.PrintSuccess("All dungeon filters reset to enabled")
  end)
end

-----------------------------------------------------------------------------
-- Public Getters
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.GetMinimapVisible()
  return options.minimapVisible
end

function AutoLFM.Logic.Content.Options.GetDarkUI()
  return options.darkUI
end

function AutoLFM.Logic.Content.Options.GetPresetsCondensed()
  return options.presetsCondensed
end

function AutoLFM.Logic.Content.Options.GetTestMode()
  return options.testMode
end

function AutoLFM.Logic.Content.Options.GetDebugMode()
  return options.debugMode
end

function AutoLFM.Logic.Content.Options.GetDungeonFilters()
  return options.dungeonFilters
end

function AutoLFM.Logic.Content.Options.GetAllOptions()
  return options
end

-----------------------------------------------------------------------------
-- Content management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.Load()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  AutoLFM.UI.Content.Options.Create(content)
  AutoLFM.Logic.Content.Options.RestoreState()
end

function AutoLFM.Logic.Content.Options.Unload()
  -- No state to save on unload
end

-----------------------------------------------------------------------------
-- State management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Options.RestoreState()
  if AutoLFM.UI.Content.Options.RestoreState then
    AutoLFM.UI.Content.Options.RestoreState()
  end
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Options", function()
  AutoLFM.Logic.Content.Options.LoadOptions()
  AutoLFM.Logic.Content.Options.Init()
end)
