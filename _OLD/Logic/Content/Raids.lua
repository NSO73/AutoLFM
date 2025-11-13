--=============================================================================
-- AutoLFM: Raids
--   Raids tab logic and state management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Raids = AutoLFM.Logic.Content.Raids or {}

-----------------------------------------------------------------------------
-- Private State (owned by this module)
-----------------------------------------------------------------------------
local selectedRaids = {}
local raidSelectionOrder = {}
local raidSizes = {}

-----------------------------------------------------------------------------
-- Content management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.Load()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  -- Create UI with current raids
  local raids = AutoLFM.Core.Constants.RAIDS
  AutoLFM.UI.Content.Raids.Create(content, raids)

  -- Restore state after UI creation to sync checkboxes with Maestro
  if AutoLFM.UI.Content.Raids.RestoreState then
    AutoLFM.UI.Content.Raids.RestoreState(raids)
  end
end

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.RegisterCommands()
  -- Select raid command
  AutoLFM.Core.Maestro.RegisterCommand("Raids.Select", function(raidIndex)
    if not raidIndex then return end

    -- Only one raid can be selected at a time
    -- Deselect all other raids before selecting this one
    for i, isSelected in pairs(selectedRaids) do
      if isSelected and i ~= raidIndex then
        AutoLFM.Core.Maestro.DispatchCommand("Raids.Deselect", i)
      end
    end

    selectedRaids[raidIndex] = true
    AutoLFM.Logic.Selection.OnRaidChecked(raidIndex)
    AutoLFM.Core.Maestro.EmitEvent("Raids.SelectionChanged", raidIndex, true)
  end)

  -- Deselect raid command
  AutoLFM.Core.Maestro.RegisterCommand("Raids.Deselect", function(raidIndex)
    if not raidIndex then return end
    selectedRaids[raidIndex] = nil
    AutoLFM.Logic.Selection.OnRaidUnchecked(raidIndex)
    AutoLFM.Core.Maestro.EmitEvent("Raids.SelectionChanged", raidIndex, false)
  end)

  -- Set raid size command
  AutoLFM.Core.Maestro.RegisterCommand("Raids.SetSize", function(raidIndex, size)
    if not raidIndex or not size then return end
    local minSize, maxSize = AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)

    -- Clamp size to valid range
    if size < minSize then size = minSize end
    if size > maxSize then size = maxSize end

    raidSizes[raidIndex] = size
    AutoLFM.Core.Maestro.EmitEvent("Raids.SizeChanged", raidIndex, size)
  end)

  -- Deselect all raids command (optimized for bulk operations)
  AutoLFM.Core.Maestro.RegisterCommand("Raids.DeselectAll", function()
    -- Clear local state directly (no individual deselect events)
    raidSelectionOrder = {}
    selectedRaids = {}
    raidSizes = {}

    -- Update UI: uncheck all raid checkboxes
    local raids = AutoLFM.Core.Constants.RAIDS
    for i = 1, table.getn(raids) do
      local checkbox = getglobal("AutoLFM_RaidCheckbox" .. i)
      if checkbox and checkbox:GetChecked() then
        AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
      end
    end

    -- Emit single event for all deselections
    AutoLFM.Core.Maestro.EmitEvent("Raids.AllDeselected")
  end)
end

-----------------------------------------------------------------------------
-- Public Getters
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.IsSelected(raidIndex)
  return selectedRaids[raidIndex] and true or false
end

function AutoLFM.Logic.Content.Raids.GetSelected()
  local raids = AutoLFM.Core.Constants.RAIDS
  local selected = {}
  for i = 1, table.getn(raids) do
    if selectedRaids[i] then
      table.insert(selected, raids[i])
    end
  end
  return selected
end

function AutoLFM.Logic.Content.Raids.GetSelectionOrder()
  return raidSelectionOrder
end

-----------------------------------------------------------------------------
-- Raid Size Management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)
  local raids = AutoLFM.Core.Constants.RAIDS
  if not raids or not raids[raidIndex] then return 10, 10 end
  return raids[raidIndex].sizeMin or 10, raids[raidIndex].sizeMax or 10
end

function AutoLFM.Logic.Content.Raids.IsRaidVariableSize(raidIndex)
  local minSize, maxSize = AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)
  return minSize ~= maxSize
end

function AutoLFM.Logic.Content.Raids.GetRaidSize(raidIndex)
  -- Return custom size if set, otherwise return minimum size
  local size = raidSizes[raidIndex]
  if size then return size end

  local minSize, maxSize = AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)
  return minSize
end

function AutoLFM.Logic.Content.Raids.GetAllRaidSizes()
  return raidSizes
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Raids", "Logic.Content.Raids.RegisterCommands")
