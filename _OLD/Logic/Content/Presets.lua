--=============================================================================
-- AutoLFM: Presets Logic
--   Preset save/load/delete operations using Maestro
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Presets = AutoLFM.Logic.Content.Presets or {}

-----------------------------------------------------------------------------
-- Capture Current State
-----------------------------------------------------------------------------
local function CaptureCurrentState()
  local state = {}

  -- Capture selected dungeons
  state.dungeons = {}
  local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
  for i = 1, table.getn(selectedDungeons) do
    local dungeon = selectedDungeons[i]
    if dungeon then
      table.insert(state.dungeons, dungeon.index)
    end
  end

  -- Capture selected raids
  state.raids = {}
  local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
  for i = 1, table.getn(selectedRaids) do
    local raid = selectedRaids[i]
    if raid then
      table.insert(state.raids, raid.index)
    end
  end

  -- Capture raid sizes
  state.raidSizes = AutoLFM.Core.Persistent.DeepCopy(AutoLFM.Logic.Content.Raids.GetAllRaidSizes())

  -- Capture selected quests
  state.quests = {}
  local selectedQuests = AutoLFM.Logic.Content.Quests.GetSelected()
  for i = 1, table.getn(selectedQuests) do
    local quest = selectedQuests[i]
    if quest then
      table.insert(state.quests, quest.index)
    end
  end

  -- Capture roles
  state.roles = {}
  local selectedRoles = AutoLFM.Logic.Roles.GetSelectedRoles()
  if selectedRoles.tank then
    table.insert(state.roles, "tank")
  end
  if selectedRoles.heal then
    table.insert(state.roles, "heal")
  end
  if selectedRoles.dps then
    table.insert(state.roles, "dps")
  end

  -- Capture generated message
  state.generatedMessage = AutoLFM.Logic.Message.Generate()

  -- Capture custom message
  state.customMessage = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""

  -- Capture broadcast interval
  state.interval = AutoLFM.Logic.Content.Broadcasts.GetInterval()

  -- Capture selected channels
  local channels = {}
  if AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("LookingForGroup") then
    channels.LookingForGroup = true
  end
  if AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("World") then
    channels.World = true
  end
  if AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("Hardcore") then
    channels.Hardcore = true
  end
  state.channels = channels

  -- Capture message templates
  state.messageTemplateDungeon = AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate()
  state.messageTemplateRaid = AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate()

  return state
end

-----------------------------------------------------------------------------
-- Load Preset State
-----------------------------------------------------------------------------
local function LoadPresetState(presetData)
  if not presetData then return end

  -- Clear all current selections
  AutoLFM.Logic.Selection.ClearAll()

  -- Load dungeons
  if presetData.dungeons then
    for i = 1, table.getn(presetData.dungeons) do
      local dungeonIndex = presetData.dungeons[i]
      AutoLFM.Core.Maestro.DispatchCommand("Dungeons.Select", dungeonIndex)
    end
  end

  -- Load raids
  if presetData.raids then
    for i = 1, table.getn(presetData.raids) do
      local raidIndex = presetData.raids[i]
      AutoLFM.Core.Maestro.DispatchCommand("Raids.Select", raidIndex)
    end
  end

  -- Load raid sizes
  if presetData.raidSizes then
    for raidIndex, size in pairs(presetData.raidSizes) do
      AutoLFM.Core.Maestro.DispatchCommand("Raids.SetSize", raidIndex, size)
    end
  end

  -- Load quests
  if presetData.quests then
    for i = 1, table.getn(presetData.quests) do
      local questIndex = presetData.quests[i]
      AutoLFM.Core.Maestro.DispatchCommand("Quests.Select", questIndex)
    end
  end

  -- Load roles
  if presetData.roles then
    for i = 1, table.getn(presetData.roles) do
      local role = presetData.roles[i]
      AutoLFM.Core.Maestro.DispatchCommand("Roles.Toggle", role)
    end
  end

  -- Load custom message
  if presetData.customMessage then
    AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetCustomMessage", presetData.customMessage)
    -- UI will be updated automatically via Broadcasts.CustomMessageChanged event listener
  end

  -- Load broadcast interval
  if presetData.interval then
    AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetInterval", presetData.interval)
  end

  -- Load selected channels
  if presetData.channels then
    for channelName, isSelected in pairs(presetData.channels) do
      AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.ToggleChannel", channelName, isSelected)
    end
  end

  -- Load message templates
  if presetData.messageTemplateDungeon then
    AutoLFM.Core.Maestro.DispatchCommand("Messages.SetDungeonTemplate", presetData.messageTemplateDungeon)
    -- UI will be updated automatically via Messages.DungeonTemplateChanged event listener
  end

  if presetData.messageTemplateRaid then
    AutoLFM.Core.Maestro.DispatchCommand("Messages.SetRaidTemplate", presetData.messageTemplateRaid)
    -- UI will be updated automatically via Messages.RaidTemplateChanged event listener
  end
end

-----------------------------------------------------------------------------
-- Maestro Commands
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Presets.Init()
  -- Save Preset Command
  AutoLFM.Core.Maestro.RegisterCommand("Presets.Save", function(presetName)
    if not presetName or presetName == "" then
      AutoLFM.Core.Utils.PrintError("Preset name cannot be empty")
      return
    end

    -- Check if preset already exists
    if AutoLFM.Core.Persistent.PresetExists(presetName) then
      AutoLFM.Core.Utils.PrintError("A preset with the name " .. AutoLFM.Core.Utils.ColorizeText(presetName, "yellow") .. " already exists")
      return
    end

    local currentState = CaptureCurrentState()
    local success = AutoLFM.Core.Persistent.SavePreset(presetName, currentState)

    if success then
      AutoLFM.Core.Utils.PrintSuccess("Preset saved: " .. AutoLFM.Core.Utils.ColorizeText(presetName, "yellow"))

      -- Refresh UI if visible
      if AutoLFM.UI.Content.Presets.Refresh then
        AutoLFM.UI.Content.Presets.Refresh()
      end
    else
      AutoLFM.Core.Utils.PrintError("Failed to save preset")
    end
  end)

  -- Load Preset Command
  AutoLFM.Core.Maestro.RegisterCommand("Presets.Load", function(presetName)
    if not presetName or presetName == "" then
      AutoLFM.Core.Utils.PrintError("Preset name cannot be empty")
      return
    end

    local presets = AutoLFM.Core.Persistent.GetPresets()
    local presetData = presets[presetName]

    if not presetData then
      AutoLFM.Core.Utils.PrintError("Preset not found: " .. presetName)
      return
    end

    LoadPresetState(presetData)
    AutoLFM.Core.Utils.PrintSuccess("Preset loaded: " .. AutoLFM.Core.Utils.ColorizeText(presetName, "yellow"))
  end)

  -- Delete Preset Command
  AutoLFM.Core.Maestro.RegisterCommand("Presets.Delete", function(presetName)
    if not presetName or presetName == "" then
      AutoLFM.Core.Utils.PrintError("Preset name cannot be empty")
      return
    end

    local success = AutoLFM.Core.Persistent.DeletePreset(presetName)

    if success then
      AutoLFM.Core.Utils.PrintSuccess("Preset deleted: " .. AutoLFM.Core.Utils.ColorizeText(presetName, "yellow"))

      -- Refresh UI if visible
      if AutoLFM.UI.Content.Presets.Refresh then
        AutoLFM.UI.Content.Presets.Refresh()
      end
    else
      AutoLFM.Core.Utils.PrintError("Failed to delete preset")
    end
  end)

  -- Move Preset Up Command
  AutoLFM.Core.Maestro.RegisterCommand("Presets.MoveUp", function(presetName)
    if not presetName or presetName == "" then
      return
    end

    local success = AutoLFM.Core.Persistent.MovePresetUp(presetName)

    if success then
      -- Refresh UI if visible
      if AutoLFM.UI.Content.Presets.Refresh then
        AutoLFM.UI.Content.Presets.Refresh()
      end
    end
  end)

  -- Move Preset Down Command
  AutoLFM.Core.Maestro.RegisterCommand("Presets.MoveDown", function(presetName)
    if not presetName or presetName == "" then
      return
    end

    local success = AutoLFM.Core.Persistent.MovePresetDown(presetName)

    if success then
      -- Refresh UI if visible
      if AutoLFM.UI.Content.Presets.Refresh then
        AutoLFM.UI.Content.Presets.Refresh()
      end
    end
  end)
end

-----------------------------------------------------------------------------
-- Content Management
-----------------------------------------------------------------------------
-- Store event listener reference to avoid multiple registrations
local viewModeChangeListener = nil

function AutoLFM.Logic.Content.Presets.Load()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  -- Determine which UI to load based on presets view mode
  local isCondensed = AutoLFM.Core.Persistent.GetPresetsCondensed()

  if isCondensed then
    -- Load condensed UI
    if AutoLFM.UI.Content.Presets.CreateCondensed then
      AutoLFM.UI.Content.Presets.CreateCondensed(content)
    else
      -- Fallback to normal UI if condensed not implemented yet
      AutoLFM.UI.Content.Presets.Create(content)
    end
  else
    -- Load full UI
    AutoLFM.UI.Content.Presets.Create(content)
  end

  -- Register view mode change listener only once
  if not viewModeChangeListener then
    viewModeChangeListener = function(isCondensed)
      -- Reload the Presets tab if it's currently displayed
      if AutoLFM.Core.Maestro.currentTab and AutoLFM.Core.Maestro.currentTab.lineTab == "presets" then
        AutoLFM.Logic.Widgets.Tabs.ReloadCurrentTab()
      end
    end
    AutoLFM.Core.Maestro.RegisterEventListener("Presets.ViewModeChanged", viewModeChangeListener, "Reload Presets tab when view mode changes")
  end
end

function AutoLFM.Logic.Content.Presets.Unload()
  -- Unregister event listener when tab is closed
  -- Note: We can't remove specific listeners in current implementation,
  -- but that's OK as the listener checks if the tab is active
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Presets", "Logic.Content.Presets.Init")
