--=============================================================================
-- AutoLFM: Presets Content
--   Presets panel UI with scrollable list
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Presets = AutoLFM.UI.Content.Presets or {}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local panel = nil
local presetRows = {}

-----------------------------------------------------------------------------
-- Save Preset Popup
-----------------------------------------------------------------------------
StaticPopupDialogs["AUTOLFM_SAVE_PRESET"] = {
  text = "Enter preset name:",
  button1 = "Save",
  button2 = "Cancel",
  hasEditBox = 1,
  maxLetters = 32,
  OnAccept = function()
    local presetName = getglobal(this:GetParent():GetName().."EditBox"):GetText()
    if presetName and presetName ~= "" then
      AutoLFM.Core.Maestro.DispatchCommand("Presets.Save", presetName)
    end
  end,
  OnShow = function()
    getglobal(this:GetName().."EditBox"):SetFocus()
  end,
  OnHide = function()
    getglobal(this:GetName().."EditBox"):SetText("")
  end,
  EditBoxOnEnterPressed = function()
    local presetName = getglobal(this:GetParent():GetName().."EditBox"):GetText()
    if presetName and presetName ~= "" then
      AutoLFM.Core.Maestro.DispatchCommand("Presets.Save", presetName)
    end
    this:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = function()
    this:GetParent():Hide()
  end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
  preferredIndex = 3
}

-----------------------------------------------------------------------------
-- Format Preset Display Info
-----------------------------------------------------------------------------
local function GetPresetContentString(presetData)
  if not presetData then return "" end

  local parts = {}

  -- Dungeons
  if presetData.dungeons and table.getn(presetData.dungeons) > 0 then
    local dungeonNames = {}
    for i = 1, table.getn(presetData.dungeons) do
      local dungeonIndex = presetData.dungeons[i]
      local dungeon = AutoLFM.Core.Constants.DUNGEONS[dungeonIndex]
      if dungeon then
        table.insert(dungeonNames, dungeon.name)
      end
    end
    if table.getn(dungeonNames) > 0 then
      table.insert(parts, table.concat(dungeonNames, ", "))
    end
  end

  -- Raids
  if presetData.raids and table.getn(presetData.raids) > 0 then
    local raidNames = {}
    for i = 1, table.getn(presetData.raids) do
      local raidIndex = presetData.raids[i]
      local raid = AutoLFM.Core.Constants.RAIDS[raidIndex]
      if raid then
        local raidName = raid.name
        if presetData.raidSizes and presetData.raidSizes[raidIndex] then
          raidName = raidName .. " (" .. presetData.raidSizes[raidIndex] .. ")"
        end
        table.insert(raidNames, raidName)
      end
    end
    if table.getn(raidNames) > 0 then
      table.insert(parts, table.concat(raidNames, ", "))
    end
  end

  if table.getn(parts) > 0 then
    return table.concat(parts, ", ")
  end

  return "Empty preset"
end

-----------------------------------------------------------------------------
-- Create Preset Row
-----------------------------------------------------------------------------
local function CreatePresetRow(presetName, presetData, yOffset, isFirst, isLast)
  if not panel or not presetName then return nil end

  local contentStr = GetPresetContentString(presetData)
  local messageStr = presetData.generatedMessage or ""

  -- Constants
  local nameHeight = 16
  local lineSpacing = 1
  local contentMessageSpacing = 5
  local topPadding = 14
  local bottomPadding = 2

  -- Create temporary row to calculate text heights
  local tempRow = CreateFrame("Frame", nil, panel)
  tempRow:SetWidth(300)

  -- Calculate roles width first
  local rolesWidth = 0
  if presetData.roles and table.getn(presetData.roles) > 0 then
    local iconSize = 20
    local iconSpacing = -6
    rolesWidth = (iconSize + iconSpacing) * table.getn(presetData.roles) + iconSpacing
  end

  -- Create temp content text to measure height
  local tempContentText = tempRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  tempContentText:SetWidth(260 - rolesWidth - 5)
  tempContentText:SetJustifyH("LEFT")
  tempContentText:SetText(contentStr)
  local contentHeight = tempContentText:GetHeight()

  -- Create temp message text to measure height
  local messageHeight = 0
  if messageStr ~= "" and string.len(messageStr) > 0 then
    local tempMessageText = tempRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tempMessageText:SetWidth(260)
    tempMessageText:SetJustifyH("LEFT")
    tempMessageText:SetText(messageStr)
    messageHeight = tempMessageText:GetHeight()
  end

  -- Clean up temp frame
  tempRow:Hide()
  tempRow:SetParent(nil)

  -- Calculate row height: top padding + name + spacing + content + (spacing + message if exists) + bottom padding
  local rowHeight = topPadding + nameHeight + lineSpacing + contentHeight + bottomPadding
  if messageStr ~= "" then
    rowHeight = rowHeight + contentMessageSpacing + messageHeight
  end

  local row = CreateFrame("Button", "AutoLFM_PresetRow_"..presetName, panel)
  row:SetWidth(300)
  row:SetHeight(rowHeight)
  row:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -yOffset)

  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetTexture(0, 0, 0, 0)

  -- Bottom border
  local border = row:CreateTexture(nil, "BORDER")
  border:SetTexture(0.3, 0.3, 0.3, 0.5)
  border:SetHeight(1)
  border:SetWidth(300)
  border:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)

  local currentY = -(topPadding - 8)

  -- Name
  local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 10, currentY)
  nameText:SetText(presetName)
  AutoLFM.Core.Utils.SetFontColor(nameText, "gold")
  currentY = currentY - nameHeight - lineSpacing

  -- Roles icons
  local rolesWidth = 0
  if presetData.roles and table.getn(presetData.roles) > 0 then
    local iconSize = 20
    local iconSpacing = -6
    local currentX = 10

    for i = 1, table.getn(presetData.roles) do
      local role = presetData.roles[i]
      local iconTexture = nil

      if role == "tank" then
        iconTexture = AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\tank"
      elseif role == "heal" then
        iconTexture = AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\heal"
      elseif role == "dps" then
        iconTexture = AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\dps"
      end

      if iconTexture then
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(iconTexture)
        icon:SetWidth(iconSize)
        icon:SetHeight(iconSize)
        icon:SetPoint("TOPLEFT", row, "TOPLEFT", currentX, currentY + 1)
        currentX = currentX + iconSize + iconSpacing
      end
    end

    rolesWidth = currentX - 10
  end

  -- Content (dungeons/raids)
  local contentText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  contentText:SetPoint("TOPLEFT", row, "TOPLEFT", 10 + rolesWidth + 5, currentY)
  contentText:SetWidth(260 - rolesWidth - 5)
  contentText:SetJustifyH("LEFT")
  contentText:SetText(contentStr)
  AutoLFM.Core.Utils.SetFontColor(contentText, "white")
  currentY = currentY - contentHeight - contentMessageSpacing

  -- Custom message
  if messageStr ~= "" then
    local messageText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    messageText:SetPoint("TOPLEFT", row, "TOPLEFT", 10, currentY)
    messageText:SetWidth(260)
    messageText:SetJustifyH("LEFT")
    messageText:SetText(messageStr)
    AutoLFM.Core.Utils.SetFontColor(messageText, "yellow")
  end

  -- Buttons container (positioned at right, centered vertically)
  local btnSize = 16
  local btnSpacing = -2

  -- Up button
  if not isFirst then
    local upBtn = CreateFrame("Button", nil, row)
    upBtn:SetWidth(btnSize)
    upBtn:SetHeight(btnSize)
    upBtn:SetPoint("RIGHT", row, "RIGHT", -5, (btnSize + btnSpacing))

    local upTexture = upBtn:CreateTexture(nil, "ARTWORK")
    upTexture:SetAllPoints(upBtn)
    upTexture:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\up")

    local upHighlight = upBtn:CreateTexture(nil, "HIGHLIGHT")
    upHighlight:SetAllPoints(upBtn)
    upHighlight:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\up")
    upHighlight:SetBlendMode("ADD")

    upBtn:SetScript("OnClick", function()
      AutoLFM.Core.Maestro.DispatchCommand("Presets.MoveUp", presetName)
    end)

    upBtn:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Move up")
      GameTooltip:Show()
    end)

    upBtn:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  -- Delete button (centered)
  local deleteBtn = CreateFrame("Button", nil, row)
  deleteBtn:SetWidth(btnSize)
  deleteBtn:SetHeight(btnSize)
  deleteBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)

  local deleteIcon = deleteBtn:CreateTexture(nil, "ARTWORK")
  deleteIcon:SetAllPoints(deleteBtn)
  deleteIcon:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\close")

  local deleteHighlight = deleteBtn:CreateTexture(nil, "HIGHLIGHT")
  deleteHighlight:SetAllPoints(deleteBtn)
  deleteHighlight:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\close")
  deleteHighlight:SetBlendMode("ADD")

  deleteBtn:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Presets.Delete", presetName)
  end)

  deleteBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Delete preset")
    GameTooltip:Show()
  end)

  deleteBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Down button
  if not isLast then
    local downBtn = CreateFrame("Button", nil, row)
    downBtn:SetWidth(btnSize)
    downBtn:SetHeight(btnSize)
    downBtn:SetPoint("RIGHT", row, "RIGHT", -5, -(btnSize + btnSpacing))

    local downTexture = downBtn:CreateTexture(nil, "ARTWORK")
    downTexture:SetAllPoints(downBtn)
    downTexture:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\down")

    local downHighlight = downBtn:CreateTexture(nil, "HIGHLIGHT")
    downHighlight:SetAllPoints(downBtn)
    downHighlight:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\down")
    downHighlight:SetBlendMode("ADD")

    downBtn:SetScript("OnClick", function()
      AutoLFM.Core.Maestro.DispatchCommand("Presets.MoveDown", presetName)
    end)

    downBtn:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Move down")
      GameTooltip:Show()
    end)

    downBtn:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  -- Load on click
  row:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Presets.Load", presetName)
  end)

  row:SetScript("OnEnter", function()
    bg:SetTexture(0.2, 0.2, 0.2, 0.5)
    AutoLFM.Core.Utils.SetFontColor(nameText, "blue")
  end)

  row:SetScript("OnLeave", function()
    bg:SetTexture(0, 0, 0, 0)
    AutoLFM.Core.Utils.SetFontColor(nameText, "gold")
  end)

  row.rowHeight = rowHeight
  return row
end

-----------------------------------------------------------------------------
-- Refresh Preset List (Full Version)
-----------------------------------------------------------------------------
local function RefreshFull()
  if not panel then return end

  -- Clear existing rows
  for _, row in pairs(presetRows) do
    if row then
      row:Hide()
      row:SetParent(nil)
    end
  end
  presetRows = {}

  -- Get presets and order
  local presets = AutoLFM.Core.Persistent.GetPresets()
  local order = AutoLFM.Core.Persistent.GetPresetsOrder()

  -- Build ordered list (include presets not in order at the end)
  local orderedPresets = {}
  for i = 1, table.getn(order) do
    local presetName = order[i]
    if presets[presetName] then
      table.insert(orderedPresets, presetName)
    end
  end

  -- Add any presets not in order
  for presetName, _ in pairs(presets) do
    local found = false
    for i = 1, table.getn(orderedPresets) do
      if orderedPresets[i] == presetName then
        found = true
        break
      end
    end
    if not found then
      table.insert(orderedPresets, presetName)
    end
  end

  -- Create rows in order
  local yOffset = 0
  local totalPresets = table.getn(orderedPresets)
  for i = 1, totalPresets do
    local presetName = orderedPresets[i]
    local presetData = presets[presetName]
    local isFirst = (i == 1)
    local isLast = (i == totalPresets)

    local row = CreatePresetRow(presetName, presetData, yOffset, isFirst, isLast)
    if row then
      table.insert(presetRows, row)
      yOffset = yOffset + (row.rowHeight or 50)
    end
  end

  -- Show "No presets" message if empty
  local noPresetsText = getglobal("AutoLFM_Panel_Presets_NoPresetsText")
  if noPresetsText then
    if table.getn(presetRows) == 0 then
      noPresetsText:Show()
    else
      noPresetsText:Hide()
    end
  end
end

-- Set the global Refresh function to the Full version initially
AutoLFM.UI.Content.Presets.Refresh = RefreshFull

-----------------------------------------------------------------------------
-- Panel Creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Presets.Create(parent)
  if not parent then return nil end

  -- Clean up existing panel if it exists
  local existingPanel = getglobal("AutoLFM_Panel_Presets")
  if existingPanel then
    existingPanel:Hide()
    existingPanel:SetParent(nil)
  end

  panel = CreateFrame("Frame", "AutoLFM_Panel_Presets", parent)
  panel:SetAllPoints()

  -- Ensure we use the Full refresh function (in case it was overridden by condensed)
  AutoLFM.UI.Content.Presets.Refresh = RefreshFull

  -- Initial refresh
  AutoLFM.UI.Content.Presets.Refresh()

  return panel
end

-----------------------------------------------------------------------------
-- Show Save Preset Popup
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Presets.ShowSavePopup()
  StaticPopup_Show("AUTOLFM_SAVE_PRESET")
end

-----------------------------------------------------------------------------
-- Condensed View: Create Compact Preset Row
-----------------------------------------------------------------------------
local function CreateCondensedPresetRow(presetName, presetData, yOffset, isFirst, isLast)
  if not panel or not presetName then return nil end

  local messageStr = presetData.generatedMessage or ""

  -- Constants (same as Full version)
  local nameHeight = 16
  local lineSpacing = 1
  local topPadding = 14
  local bottomPadding = 2

  -- Create temporary row to calculate text heights
  local tempRow = CreateFrame("Frame", nil, panel)
  tempRow:SetWidth(300)

  -- Create temp message text to measure height
  local messageHeight = 0
  if messageStr ~= "" and string.len(messageStr) > 0 then
    local tempMessageText = tempRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tempMessageText:SetWidth(280)
    tempMessageText:SetJustifyH("LEFT")
    tempMessageText:SetText(messageStr)
    messageHeight = tempMessageText:GetHeight()
  end

  -- Clean up temp frame
  tempRow:Hide()
  tempRow:SetParent(nil)

  -- Calculate row height: top padding + name + spacing + message + bottom padding
  local rowHeight = topPadding + nameHeight + lineSpacing + messageHeight + bottomPadding

  local row = CreateFrame("Button", "AutoLFM_PresetRowCond_"..presetName, panel)
  row:SetWidth(300)
  row:SetHeight(rowHeight)
  row:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -yOffset)

  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetTexture(0, 0, 0, 0)

  -- Bottom border
  local border = row:CreateTexture(nil, "BORDER")
  border:SetTexture(0.3, 0.3, 0.3, 0.5)
  border:SetHeight(1)
  border:SetWidth(300)
  border:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)

  local currentY = -(topPadding - 8)

  -- Name
  local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 10, currentY)
  nameText:SetText(presetName)
  AutoLFM.Core.Utils.SetFontColor(nameText, "gold")
  currentY = currentY - nameHeight - lineSpacing

  -- Message (full generated message with word wrap)
  if messageStr ~= "" then
    local messageText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    messageText:SetPoint("TOPLEFT", row, "TOPLEFT", 10, currentY)
    messageText:SetWidth(280)
    messageText:SetJustifyH("LEFT")
    messageText:SetText(messageStr)
    AutoLFM.Core.Utils.SetFontColor(messageText, "white")
  end

  -- Buttons container (positioned at right, horizontally on top line)
  local btnSize = 16
  local btnSpacing = 0
  local currentBtnX = -5

  -- Close/Delete button (rightmost)
  local deleteBtn = CreateFrame("Button", nil, row)
  deleteBtn:SetWidth(btnSize)
  deleteBtn:SetHeight(btnSize)
  deleteBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", currentBtnX, -(topPadding - 10))

  local deleteIcon = deleteBtn:CreateTexture(nil, "ARTWORK")
  deleteIcon:SetAllPoints(deleteBtn)
  deleteIcon:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\close")

  local deleteHighlight = deleteBtn:CreateTexture(nil, "HIGHLIGHT")
  deleteHighlight:SetAllPoints(deleteBtn)
  deleteHighlight:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\close")
  deleteHighlight:SetBlendMode("ADD")

  deleteBtn:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Presets.Delete", presetName)
  end)

  deleteBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Delete preset")
    GameTooltip:Show()
  end)

  deleteBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  currentBtnX = currentBtnX - btnSize - btnSpacing

  -- Down button
  if not isLast then
    local downBtn = CreateFrame("Button", nil, row)
    downBtn:SetWidth(btnSize)
    downBtn:SetHeight(btnSize)
    downBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", currentBtnX, -(topPadding - 10))

    local downTexture = downBtn:CreateTexture(nil, "ARTWORK")
    downTexture:SetAllPoints(downBtn)
    downTexture:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\down")

    local downHighlight = downBtn:CreateTexture(nil, "HIGHLIGHT")
    downHighlight:SetAllPoints(downBtn)
    downHighlight:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\down")
    downHighlight:SetBlendMode("ADD")

    downBtn:SetScript("OnClick", function()
      AutoLFM.Core.Maestro.DispatchCommand("Presets.MoveDown", presetName)
    end)

    downBtn:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Move down")
      GameTooltip:Show()
    end)

    downBtn:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    currentBtnX = currentBtnX - btnSize - btnSpacing
  end

  -- Up button (leftmost)
  if not isFirst then
    local upBtn = CreateFrame("Button", nil, row)
    upBtn:SetWidth(btnSize)
    upBtn:SetHeight(btnSize)
    upBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", currentBtnX, -(topPadding - 10))

    local upTexture = upBtn:CreateTexture(nil, "ARTWORK")
    upTexture:SetAllPoints(upBtn)
    upTexture:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\up")

    local upHighlight = upBtn:CreateTexture(nil, "HIGHLIGHT")
    upHighlight:SetAllPoints(upBtn)
    upHighlight:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\up")
    upHighlight:SetBlendMode("ADD")

    upBtn:SetScript("OnClick", function()
      AutoLFM.Core.Maestro.DispatchCommand("Presets.MoveUp", presetName)
    end)

    upBtn:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Move up")
      GameTooltip:Show()
    end)

    upBtn:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  -- Load on click
  row:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Presets.Load", presetName)
  end)

  row:SetScript("OnEnter", function()
    bg:SetTexture(0.2, 0.2, 0.2, 0.5)
    AutoLFM.Core.Utils.SetFontColor(nameText, "blue")
  end)

  row:SetScript("OnLeave", function()
    bg:SetTexture(0, 0, 0, 0)
    AutoLFM.Core.Utils.SetFontColor(nameText, "gold")
  end)

  row.rowHeight = rowHeight
  return row
end

-----------------------------------------------------------------------------
-- Condensed View: Refresh Preset List
-----------------------------------------------------------------------------
local function RefreshCondensed()
  if not panel then return end

  -- Clear existing rows
  for _, row in pairs(presetRows) do
    if row then
      row:Hide()
      row:SetParent(nil)
    end
  end
  presetRows = {}

  -- Get presets and order
  local presets = AutoLFM.Core.Persistent.GetPresets()
  local order = AutoLFM.Core.Persistent.GetPresetsOrder()

  -- Build ordered list
  local orderedPresets = {}
  for i = 1, table.getn(order) do
    local presetName = order[i]
    if presets[presetName] then
      table.insert(orderedPresets, presetName)
    end
  end

  -- Add any presets not in order
  for presetName, _ in pairs(presets) do
    local found = false
    for i = 1, table.getn(orderedPresets) do
      if orderedPresets[i] == presetName then
        found = true
        break
      end
    end
    if not found then
      table.insert(orderedPresets, presetName)
    end
  end

  -- Create rows
  local yOffset = 0
  local totalPresets = table.getn(orderedPresets)
  for i = 1, totalPresets do
    local presetName = orderedPresets[i]
    local presetData = presets[presetName]

    if presetData then
      local isFirst = (i == 1)
      local isLast = (i == totalPresets)
      local row = CreateCondensedPresetRow(presetName, presetData, yOffset, isFirst, isLast)
      table.insert(presetRows, row)
      yOffset = yOffset + (row.rowHeight or 24)
    end
  end

  -- Show "No presets" message if empty
  local noPresetsText = getglobal("AutoLFM_Panel_Presets_NoPresetsText")
  if noPresetsText then
    if table.getn(presetRows) == 0 then
      noPresetsText:Show()
    else
      noPresetsText:Hide()
    end
  end
end

-----------------------------------------------------------------------------
-- Condensed View: Panel Creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Presets.CreateCondensed(parent)
  if not parent then return nil end

  -- Clean up existing panel if it exists
  local existingPanel = getglobal("AutoLFM_Panel_Presets")
  if existingPanel then
    existingPanel:Hide()
    existingPanel:SetParent(nil)
  end

  panel = CreateFrame("Frame", "AutoLFM_Panel_Presets", parent)
  panel:SetAllPoints()

  -- Override Refresh to use condensed version
  AutoLFM.UI.Content.Presets.Refresh = RefreshCondensed

  -- Initial refresh
  RefreshCondensed()

  return panel
end
