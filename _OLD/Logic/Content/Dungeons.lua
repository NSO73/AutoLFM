--=============================================================================
-- AutoLFM: Dungeons
--   Dungeons tab logic and state management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Dungeons = AutoLFM.Logic.Content.Dungeons or {}

-----------------------------------------------------------------------------
-- Private State (owned by this module)
-----------------------------------------------------------------------------
local selectedDungeons = {}
local dungeonSelectionOrder = {}

-----------------------------------------------------------------------------
-- Dungeon color calculation
-----------------------------------------------------------------------------
local function GetDungeonColor(dungeon, playerLevel)
  if not dungeon or not dungeon.levelMin or not playerLevel then
    return AutoLFM.Core.Constants.COLORS.GRAY
  end

  local priority = AutoLFM.Core.Utils.CalculateLevelPriority(playerLevel, dungeon.levelMin, dungeon.levelMax)
  return AutoLFM.Core.Utils.GetColor(priority)
end

-----------------------------------------------------------------------------
-- Sorting and filtering
-----------------------------------------------------------------------------
local function GetSortedDungeons()
  local playerLevel = UnitLevel("player") or 1
  local dungeons = AutoLFM.Core.Constants.DUNGEONS
  local sorted = {}
  local filters = AutoLFM.Core.Persistent.GetDungeonFilters()

  for i = 1, table.getn(dungeons) do
    local dungeon = dungeons[i]
    local color = GetDungeonColor(dungeon, playerLevel)

    -- Use color.name to check filter state (string key)
    if filters[color.name] then
      table.insert(sorted, {
        index = i,
        dungeon = dungeon,
        color = color
      })
    end
  end

  -- Sort by color priority (green first, then yellow, orange, red, gray)
  table.sort(sorted, function(a, b)
    if a.color.priority ~= b.color.priority then
      return a.color.priority < b.color.priority
    end
    return a.dungeon.levelMin < b.dungeon.levelMin
  end)

  return sorted
end

-----------------------------------------------------------------------------
-- Filter management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.GetFilterState(colorId)
  local filters = AutoLFM.Core.Persistent.GetDungeonFilters()
  return filters[colorId] or false
end

function AutoLFM.Logic.Content.Dungeons.GetAllFilters()
  return AutoLFM.Core.Persistent.GetDungeonFilters()
end

-----------------------------------------------------------------------------
-- Content management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.Load()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  -- Create UI with sorted dungeons
  local sorted = GetSortedDungeons()
  AutoLFM.UI.Content.Dungeons.Create(content, sorted)
end

function AutoLFM.Logic.Content.Dungeons.Refresh()
  AutoLFM.Logic.Content.Dungeons.Load()
end

function AutoLFM.Logic.Content.Dungeons.GetSortedDungeons()
  return GetSortedDungeons()
end

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.RegisterCommands()
  -- Select dungeon command
  AutoLFM.Core.Maestro.RegisterCommand("Dungeons.Select", function(dungeonIndex)
    if not dungeonIndex then return end
    selectedDungeons[dungeonIndex] = true
    AutoLFM.Logic.Selection.OnDungeonChecked(dungeonIndex)
    AutoLFM.Core.Maestro.EmitEvent("Dungeons.SelectionChanged", dungeonIndex, true)
  end)

  -- Deselect dungeon command
  AutoLFM.Core.Maestro.RegisterCommand("Dungeons.Deselect", function(dungeonIndex)
    if not dungeonIndex then return end
    selectedDungeons[dungeonIndex] = nil
    AutoLFM.Logic.Selection.OnDungeonUnchecked(dungeonIndex)
    AutoLFM.Core.Maestro.EmitEvent("Dungeons.SelectionChanged", dungeonIndex, false)
  end)

  -- Deselect all dungeons command (optimized for bulk operations)
  AutoLFM.Core.Maestro.RegisterCommand("Dungeons.DeselectAll", function()
    -- Clear local state directly (no individual deselect events)
    dungeonSelectionOrder = {}
    selectedDungeons = {}

    -- Update UI: uncheck all dungeon checkboxes
    local i = 1
    while i <= AutoLFM.Core.Constants.MAX_CHECKBOX_SEARCH_ITERATIONS do
      local checkbox = getglobal("AutoLFM_DungeonCheckbox" .. i)
      if not checkbox then break end
      if checkbox:GetChecked() then
        AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
      end
      i = i + 1
    end

    -- Emit single event for all deselections
    AutoLFM.Core.Maestro.EmitEvent("Dungeons.AllDeselected")
  end)

  -- Register event listener for filter changes
  -- When a filter changes in Options, refresh the dungeon list visibility
  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.FilterChanged", function(colorId, enabled)
    -- Refresh dungeons display ONLY if currently on the Dungeons tab
    if AutoLFM.Core.Maestro.currentTab.bottomTab == "dungeons" and AutoLFM.UI.Content.Dungeons.UpdateVisibility then
      local sorted = GetSortedDungeons()
      AutoLFM.UI.Content.Dungeons.UpdateVisibility(sorted)
    end
  end, "Refresh dungeon list visibility")
end

-----------------------------------------------------------------------------
-- Public Getters
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.IsSelected(dungeonIndex)
  return selectedDungeons[dungeonIndex] and true or false
end

function AutoLFM.Logic.Content.Dungeons.GetSelected()
  local sorted = GetSortedDungeons()
  local selected = {}
  for i = 1, table.getn(sorted) do
    if selectedDungeons[sorted[i].index] then
      table.insert(selected, sorted[i].dungeon)
    end
  end
  return selected
end

function AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
  return dungeonSelectionOrder
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Dungeons", "Logic.Content.Dungeons.RegisterCommands")
