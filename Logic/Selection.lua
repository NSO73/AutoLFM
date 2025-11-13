--=============================================================================
-- AutoLFM: Selection
--   Selection constraints management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Selection = AutoLFM.Logic.Selection or {}

-----------------------------------------------------------------------------
-- Dungeon selection constraints
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.OnDungeonChecked(dungeonIndex)
  -- Uncheck all raids (dungeons and raids are mutually exclusive)
  AutoLFM.Core.Maestro.DispatchCommand("Raids.DeselectAll")

  -- Get selection order from Dungeons module
  local selectionOrder = AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
  table.insert(selectionOrder, dungeonIndex)

  -- If more than MAX_DUNGEONS selected, uncheck the oldest one
  if table.getn(selectionOrder) > AutoLFM.Core.Constants.MAX_DUNGEONS then
    local oldestIndex = table.remove(selectionOrder, 1)

    -- Deselect via command
    AutoLFM.Core.Maestro.DispatchCommand("Dungeons.Deselect", oldestIndex)

    -- Find and uncheck the oldest dungeon checkbox (prevent OnClick from firing)
    local checkbox = AutoLFM.Logic.Selection.FindDungeonCheckbox(oldestIndex)
    if checkbox then
      AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
    end
  end
end

function AutoLFM.Logic.Selection.OnDungeonUnchecked(dungeonIndex)
  -- Remove from selection order in Dungeons module
  local selectionOrder = AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
  for i = 1, table.getn(selectionOrder) do
    if selectionOrder[i] == dungeonIndex then
      table.remove(selectionOrder, i)
      break
    end
  end
end

-----------------------------------------------------------------------------
-- Raid selection constraints
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.OnRaidChecked(raidIndex)
  -- Uncheck all dungeons (dungeons and raids are mutually exclusive)
  AutoLFM.Core.Maestro.DispatchCommand("Dungeons.DeselectAll")

  -- Get selection order from Raids module
  local selectionOrder = AutoLFM.Logic.Content.Raids.GetSelectionOrder()

  -- If another raid is selected, uncheck it (only 1 raid allowed)
  if table.getn(selectionOrder) > 0 then
    local oldRaidIndex = selectionOrder[1]

    -- Deselect via command
    AutoLFM.Core.Maestro.DispatchCommand("Raids.Deselect", oldRaidIndex)

    -- Find and uncheck the old raid checkbox (prevent OnClick from firing)
    local checkbox = AutoLFM.Logic.Selection.FindRaidCheckbox(oldRaidIndex)
    if checkbox then
      AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
    end

    -- Hide the old raid's size controls
    if AutoLFM.UI.Content.Raids and AutoLFM.UI.Content.Raids.UpdateRowSizeControls then
      AutoLFM.UI.Content.Raids.UpdateRowSizeControls(oldRaidIndex, false)
    end

    -- Replace the old raid with the new one in selection order
    selectionOrder[1] = raidIndex
  else
    -- No raid was selected before, add the new one
    table.insert(selectionOrder, raidIndex)
  end
end

function AutoLFM.Logic.Selection.OnRaidUnchecked(raidIndex)
  -- Remove from selection order in Raids module
  local selectionOrder = AutoLFM.Logic.Content.Raids.GetSelectionOrder()
  for i = 1, table.getn(selectionOrder) do
    if selectionOrder[i] == raidIndex then
      table.remove(selectionOrder, i)
      break
    end
  end
end

-----------------------------------------------------------------------------
-- Helper functions to find checkboxes
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.FindDungeonCheckbox(dungeonIndex)
  -- Search through all dungeon checkboxes to find the one with this dungeonIndex
  local i = 1
  while i <= AutoLFM.Core.Constants.MAX_CHECKBOX_SEARCH_ITERATIONS do
    local checkbox = getglobal("AutoLFM_DungeonCheckbox" .. i)
    if not checkbox then break end  -- Stop when no more checkboxes exist
    local row = checkbox:GetParent()
    if row and row.dungeonIndex == dungeonIndex then
      return checkbox
    end
    i = i + 1
  end
  return nil
end

function AutoLFM.Logic.Selection.FindRaidCheckbox(raidIndex)
  -- Raid checkboxes use simple index (no sorting)
  return getglobal("AutoLFM_RaidCheckbox" .. raidIndex)
end

-----------------------------------------------------------------------------
-- Get current selection info
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetDungeonSelectionCount()
  local selectionOrder = AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
  return table.getn(selectionOrder)
end

function AutoLFM.Logic.Selection.GetRaidSelectionCount()
  local selectionOrder = AutoLFM.Logic.Content.Raids.GetSelectionOrder()
  return table.getn(selectionOrder)
end

function AutoLFM.Logic.Selection.GetSelectionType()
  if AutoLFM.Logic.Selection.GetDungeonSelectionCount() > 0 then
    return "dungeons"
  elseif AutoLFM.Logic.Selection.GetRaidSelectionCount() > 0 then
    return "raids"
  else
    return "none"
  end
end

-----------------------------------------------------------------------------
-- Get content type and selected data
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetContentTypeAndData()
  local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
  if table.getn(selectedRaids) > 0 then
    return "raids", selectedRaids
  end

  local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
  if table.getn(selectedDungeons) > 0 then
    return "dungeons", selectedDungeons
  end

  return "none", {}
end

-----------------------------------------------------------------------------
-- Get roles formatted string
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetRolesString()
  local roles = AutoLFM.Logic.Roles.GetSelectedRoles()
  local selectedRoles = {}
  local allRoles = {"Tank", "Heal", "DPS"}

  -- Build list of selected roles
  if roles.tank then
    table.insert(selectedRoles, "Tank")
  end
  if roles.heal then
    table.insert(selectedRoles, "Heal")
  end
  if roles.dps then
    table.insert(selectedRoles, "DPS")
  end

  local count = table.getn(selectedRoles)

  if count == 0 then
    return ""
  end

  if count == table.getn(allRoles) then
    return "Need All"
  end

  return "Need " .. table.concat(selectedRoles, " & ")
end

-----------------------------------------------------------------------------
-- Clear All Selection (Dungeons, Raids, Quests, Roles, Message)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.ClearAll()
  -- Use optimized DeselectAll commands (single event per category instead of N events)
  AutoLFM.Core.Maestro.DispatchCommand("Dungeons.DeselectAll")
  AutoLFM.Core.Maestro.DispatchCommand("Raids.DeselectAll")
  AutoLFM.Core.Maestro.DispatchCommand("Quests.DeselectAll")
  AutoLFM.Core.Maestro.DispatchCommand("Roles.DeselectAll")

  -- Clear custom broadcast message
  -- The UI will update automatically via Broadcasts.CustomMessageChanged event listener
  AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetCustomMessage", "")
end

-----------------------------------------------------------------------------
-- Register Commands
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.RegisterCommands()
  AutoLFM.Core.Maestro.RegisterCommand("Selection.ClearAll", function()
    AutoLFM.Logic.Selection.ClearAll()
    -- Emit a final event after everything is cleared
    AutoLFM.Core.Maestro.EmitEvent("Selection.AllCleared")
  end)
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Selection", "Logic.Selection.RegisterCommands")
