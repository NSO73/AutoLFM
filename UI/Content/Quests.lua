--=============================================================================
-- AutoLFM: Quests Content
--   Quests content panel UI
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Quests = AutoLFM.UI.Content.Quests or {}

-----------------------------------------------------------------------------
-- Panel creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Quests.Create(parent, quests)
  if not parent or not quests then return nil end

  AutoLFM.Logic.Widgets.RowList.CreateList({
    parent = parent,
    items = quests,
    rowPrefix = "AutoLFM_QuestRow",
    checkboxPrefix = "AutoLFM_QuestCheckbox",
    getRowData = function(quest, index)
      -- Get color from logic
      local color = AutoLFM.Logic.Content.Quests.GetQuestColor(quest.level)

      -- Format: [lvl] Quest Name
      local mainText = "[" .. quest.level .. "] " .. quest.name

      -- Format tag: (Dungeon), (Raid), (Elite), etc.
      local rightText = ""
      if quest.tag then
        rightText = "(" .. quest.tag .. ")"
      end

      return {
        mainText = mainText,
        rightText = rightText,
        color = color,
        customProperties = {
          questIndex = quest.index,
          questLevel = quest.level
        }
      }
    end,
    onToggle = function(rowIndex, isChecked)
      local questIndex = quests[rowIndex].index
      if isChecked then
        AutoLFM.Core.Maestro.DispatchCommand("Quests.Select", questIndex)
      else
        AutoLFM.Core.Maestro.DispatchCommand("Quests.Deselect", questIndex)
      end
    end
  })

  -- Restore state and attach tooltip handlers
  AutoLFM.UI.Content.Quests.RestoreState(quests)
  AutoLFM.UI.Content.Quests.AttachTooltipHandlers(quests)

  return parent
end

-----------------------------------------------------------------------------
-- State restoration
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Quests.RestoreState(quests)
  if not quests then return end
  for i = 1, table.getn(quests) do
    local check = getglobal("AutoLFM_QuestCheckbox" .. i)
    if check then
      -- Query Quests module
      local isSelected = AutoLFM.Logic.Content.Quests.IsSelected(quests[i].index)
      check:SetChecked(isSelected)
    end
  end
end

-----------------------------------------------------------------------------
-- Tooltip handlers
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Quests.AttachTooltipHandlers(quests)
  if not quests then return end
  for i = 1, table.getn(quests) do
    local row = getglobal("AutoLFM_QuestRow" .. i)
    local quest = quests[i]
    local questIndex = quest.index

    if row then
      -- Add tooltip to OnEnter (hover visual is already handled by RowList)
      local existingOnEnter = row:GetScript("OnEnter")
      row:SetScript("OnEnter", function()
        -- Call existing hover visual effect
        if existingOnEnter then
          existingOnEnter()
        end

        -- Add tooltip with quest zone
        local zone = AutoLFM.Logic.Content.Quests.GetQuestZone(questIndex)
        if zone then
          local scale = UIParent:GetEffectiveScale()
          local x, y = GetCursorPosition()
          x, y = x / scale, y / scale

          GameTooltip:SetOwner(row, "ANCHOR_NONE")
          GameTooltip:ClearAllPoints()
          GameTooltip:SetPoint("TOPLEFT", "UIParent", "BOTTOMLEFT", x + 10, y - 10)
          GameTooltip:SetText(zone, 1, 0.82, 0)
          GameTooltip:Show()
        end
      end)

      -- Add tooltip hide to OnLeave
      local existingOnLeave = row:GetScript("OnLeave")
      row:SetScript("OnLeave", function()
        -- Call existing hover visual reset
        if existingOnLeave then
          existingOnLeave()
        end

        -- Hide tooltip
        GameTooltip:Hide()
      end)
    end
  end
end
