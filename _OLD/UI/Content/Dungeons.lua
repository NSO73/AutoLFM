--=============================================================================
-- AutoLFM: Dungeons Content
--   Dungeons content panel UI
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Dungeons = AutoLFM.UI.Content.Dungeons or {}

-----------------------------------------------------------------------------
-- Panel creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Dungeons.Create(parent, sorted)
  if not parent or not sorted then return nil end

  AutoLFM.Logic.Widgets.RowList.CreateList({
    parent = parent,
    items = sorted,
    rowPrefix = "AutoLFM_DungeonRow",
    checkboxPrefix = "AutoLFM_DungeonCheckbox",
    getRowData = function(entry, index)
      local dungeon = entry.dungeon
      local color = entry.color
      local dungeonIndex = entry.index

      return {
        mainText = dungeon.name,
        rightText = "(" .. dungeon.levelMin .. " - " .. dungeon.levelMax .. ")",
        color = color,
        customProperties = {
          dungeonIndex = dungeonIndex,
          dungeonTag = dungeon.tag
        }
      }
    end,
    onToggle = function(rowIndex, isChecked)
      local dungeonIndex = sorted[rowIndex].index
      if isChecked then
        AutoLFM.Core.Maestro.DispatchCommand("Dungeons.Select", dungeonIndex)
      else
        AutoLFM.Core.Maestro.DispatchCommand("Dungeons.Deselect", dungeonIndex)
      end
    end
  })

  -- Restore state
  AutoLFM.UI.Content.Dungeons.RestoreState(sorted)

  return parent
end

-----------------------------------------------------------------------------
-- State restoration
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Dungeons.RestoreState(sorted)
  if not sorted then return end
  for i = 1, table.getn(sorted) do
    local check = getglobal("AutoLFM_DungeonCheckbox" .. i)
    if check then
      -- Query Dungeons module
      local isSelected = AutoLFM.Logic.Content.Dungeons.IsSelected(sorted[i].index)
      check:SetChecked(isSelected)
    end
  end
end

-----------------------------------------------------------------------------
-- Visibility management
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Dungeons.UpdateVisibility(sorted)
  if not sorted then return end

  local yOffset = 0
  local visible = 0
  local filters = AutoLFM.Logic.Content.Options.GetDungeonFilters()

  for i = 1, table.getn(sorted) do
    local entry = sorted[i]
    local row = getglobal("AutoLFM_DungeonRow" .. i)

    if row then
      -- Read filter state from Options module
      -- If filter is not set (nil), default to true (show all)
      local shouldShow = filters[entry.color.name]
      if shouldShow == nil then
        shouldShow = true
      end

      if shouldShow then
        row:Show()
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", row:GetParent(), "TOPLEFT", 0, -yOffset)
        yOffset = yOffset + AutoLFM.Core.Constants.ROW_HEIGHT
        visible = visible + 1
      else
        row:Hide()
      end
    end
  end

  -- Update parent height
  local firstRow = getglobal("AutoLFM_DungeonRow1")
  if firstRow then
    local parent = firstRow:GetParent()
    if parent and parent.SetHeight then
      parent:SetHeight(math.max(visible * AutoLFM.Core.Constants.ROW_HEIGHT, 1))
    end
  end
end
