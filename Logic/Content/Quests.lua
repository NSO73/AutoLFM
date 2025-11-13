--=============================================================================
-- AutoLFM: Quests
--   Quests tab logic and state management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Quests = AutoLFM.Logic.Content.Quests or {}

-----------------------------------------------------------------------------
-- Private State (owned by this module)
-----------------------------------------------------------------------------
local selectedQuests = {}

-----------------------------------------------------------------------------
-- Get quests from player's quest log
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.GetQuestLog()
  local quests = {}
  local numEntries = GetNumQuestLogEntries()

  for i = 1, numEntries do
    local questLogTitleText, level, questTag, isHeader = GetQuestLogTitle(i)

    -- Only add actual quests, not headers
    if questLogTitleText and not isHeader then
      table.insert(quests, {
        index = i,
        name = questLogTitleText,
        level = level or 1,
        tag = questTag
      })
    end
  end

  return quests
end

-----------------------------------------------------------------------------
-- Calculate quest color based on level difference
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.GetQuestColor(questLevel)
  local playerLevel = UnitLevel("player") or 1
  local priority = AutoLFM.Core.Utils.CalculateLevelPriority(playerLevel, questLevel, questLevel)
  return AutoLFM.Core.Utils.GetColor(priority)
end

-----------------------------------------------------------------------------
-- Content management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.Load()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  local quests = AutoLFM.Logic.Content.Quests.GetQuestLog()
  AutoLFM.UI.Content.Quests.Create(content, quests)
end


-----------------------------------------------------------------------------
-- Quest link creation
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.CreateQuestLink(questIndex)
  if not questIndex or questIndex < 1 then return nil end

  local title, level, _, _, _, _, _, questID = GetQuestLogTitle(questIndex)
  if not title then return nil end

  questID = questID or 0
  level = level or 0
  local cleanTitle = string.gsub(title, "^%[.-%]%s*", "")

  -- Calculate color based on quest level vs player level
  local playerLevel = UnitLevel("player") or 1
  local priority = AutoLFM.Core.Utils.CalculateLevelPriority(playerLevel, level, level)
  local color = AutoLFM.Core.Utils.GetColor(priority)
  local colorCode = AutoLFM.Core.Utils.RGBToHex(color.r, color.g, color.b)

  -- Create quest link format with dynamic color
  return string.format(
    AutoLFM.Core.Constants.LINK_FORMATS.QUEST,
    colorCode,
    questID,
    level,
    cleanTitle
  )
end

-----------------------------------------------------------------------------
-- Custom message manipulation (for quest links)
-----------------------------------------------------------------------------
local function IsQuestLinkInCustomMessage(link)
  if not link then return false end
  local currentText = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""
  local escapedLink = string.gsub(link, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  return string.find(currentText, escapedLink) ~= nil
end

local function AddQuestLinkToCustomMessage(link)
  if not link then return end
  local currentText = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""
  local newText = currentText == "" and link or (currentText .. " " .. link)

  -- Use Maestro command to update message
  AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetCustomMessage", newText)

  -- Update EditBox UI
  local editBox = getglobal("AutoLFM_Panel_Broadcasts_EditBox")
  if editBox then
    editBox:SetText(newText)
  end
end

local function RemoveQuestLinkFromCustomMessage(link)
  if not link then return end
  local currentText = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""
  local escapedLink = string.gsub(link, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  local newText = string.gsub(currentText, escapedLink, "")

  -- Clean up extra spaces
  newText = string.gsub(newText, "%s+", " ")
  newText = string.gsub(newText, "^%s+", "")
  newText = string.gsub(newText, "%s+$", "")

  -- Use Maestro command to update message
  AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetCustomMessage", newText)

  -- Update EditBox UI
  local editBox = getglobal("AutoLFM_Panel_Broadcasts_EditBox")
  if editBox then
    editBox:SetText(newText)
  end
end

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.RegisterCommands()
  -- Select quest command
  AutoLFM.Core.Maestro.RegisterCommand("Quests.Select", function(questIndex)
    if not questIndex then return end
    selectedQuests[questIndex] = true

    -- Add quest link to custom broadcast message
    local link = AutoLFM.Logic.Content.Quests.CreateQuestLink(questIndex)
    if link and not IsQuestLinkInCustomMessage(link) then
      AddQuestLinkToCustomMessage(link)
    end

    AutoLFM.Core.Maestro.EmitEvent("Quests.SelectionChanged", questIndex, true)
  end)

  -- Deselect quest command
  AutoLFM.Core.Maestro.RegisterCommand("Quests.Deselect", function(questIndex)
    if not questIndex then return end
    selectedQuests[questIndex] = nil

    -- Remove quest link from custom broadcast message
    local link = AutoLFM.Logic.Content.Quests.CreateQuestLink(questIndex)
    if link then
      RemoveQuestLinkFromCustomMessage(link)
    end

    AutoLFM.Core.Maestro.EmitEvent("Quests.SelectionChanged", questIndex, false)
  end)

  -- Deselect all quests command (optimized for bulk operations)
  AutoLFM.Core.Maestro.RegisterCommand("Quests.DeselectAll", function()
    -- Clear local state directly (no individual deselect events)
    selectedQuests = {}

    -- Note: Quest links are cleared via Broadcasts.SetCustomMessage("") in ClearAll
    -- No need to remove individual quest links here
  end)
end

-----------------------------------------------------------------------------
-- Public Getters
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.IsSelected(questIndex)
  return selectedQuests[questIndex] and true or false
end

function AutoLFM.Logic.Content.Quests.GetSelected()
  local quests = AutoLFM.Logic.Content.Quests.GetQuestLog()
  local selected = {}
  for i = 1, table.getn(quests) do
    if selectedQuests[quests[i].index] then
      table.insert(selected, quests[i])
    end
  end
  return selected
end

-----------------------------------------------------------------------------
-- Get quest zone by finding the header above it
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.GetQuestZone(questIndex)
  if not questIndex or questIndex <= 0 then return nil end

  for i = questIndex - 1, 1, -1 do
    local headerTitle, headerLevel = GetQuestLogTitle(i)
    if headerTitle and (not headerLevel or headerLevel == 0) then
      return headerTitle
    end
  end

  return nil
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Quests", "Logic.Content.Quests.RegisterCommands")
