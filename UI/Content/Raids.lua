--=============================================================================
-- AutoLFM: Raids Content
--   Raids content panel UI with integrated size controls
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Raids = AutoLFM.UI.Content.Raids or {}

-----------------------------------------------------------------------------
-- Private state
-----------------------------------------------------------------------------
local raidRows = {}

-----------------------------------------------------------------------------
-- Create Raid Row with Integrated Size Controls
-----------------------------------------------------------------------------
local function CreateRaidRow(parent, raid, index, yOffset)
  if not parent or not raid then return nil end

  local isVariableSize = raid.sizeMin ~= raid.sizeMax

  -- Determine right text
  local rightText
  if isVariableSize then
    rightText = "(" .. raid.sizeMin .. " - " .. raid.sizeMax .. ")"
  else
    rightText = "(" .. raid.sizeMin .. ")"
  end

  local frameName = "AutoLFM_RaidRow" .. index
  local checkboxName = "AutoLFM_RaidCheckbox" .. index
  local existingRow = getglobal(frameName)

  -- Callback for checkbox
  local onCheckboxClick = function(checkbox, isChecked)
    if isChecked then
      AutoLFM.Core.Maestro.DispatchCommand("Raids.Select", index)
    else
      AutoLFM.Core.Maestro.DispatchCommand("Raids.Deselect", index)
    end
    -- Update the row's size controls visibility
    AutoLFM.UI.Content.Raids.UpdateRowSizeControls(index, isChecked)
  end

  local row
  if existingRow then
    -- Reuse existing row
    row = existingRow

    -- Update text and color
    if row.label then
      row.label:SetText(raid.name)
      row.label:SetTextColor(AutoLFM.Core.Constants.COLORS.GOLD.r, AutoLFM.Core.Constants.COLORS.GOLD.g, AutoLFM.Core.Constants.COLORS.GOLD.b)
    end
    if row.rightLabel then
      row.rightLabel:SetText(rightText)
      row.rightLabel:SetTextColor(AutoLFM.Core.Constants.COLORS.GOLD.r, AutoLFM.Core.Constants.COLORS.GOLD.g, AutoLFM.Core.Constants.COLORS.GOLD.b)
    end

    -- Update custom properties
    row.raidTag = raid.tag
    row.raidIndex = index
    row.isVariableSize = isVariableSize

    -- Update position
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOffset)
    row:Show()

    -- Update checkbox callback
    if row.checkbox then
      row.checkbox:SetScript("OnClick", function()
        local checkbox = this
        local isChecked = checkbox:GetChecked()
        onCheckboxClick(checkbox, isChecked)
      end)
    end

    -- Update row click callback
    row:SetScript("OnClick", function()
      if row.checkbox then
        row.checkbox:Click()
      end
    end)
  else
    -- Create new row using RowList widget
    local rowConfig = {
      parent = parent,
      frameName = frameName,
      checkboxName = checkboxName,
      yOffset = yOffset,
      mainText = raid.name,
      rightText = rightText,
      color = AutoLFM.Core.Constants.COLORS.GOLD,
      isChecked = AutoLFM.Logic.Content.Raids.IsSelected(index),
      customProperties = {
        raidTag = raid.tag,
        raidIndex = index,
        isVariableSize = isVariableSize
      },
      onCheckboxClick = onCheckboxClick
    }

    row = AutoLFM.UI.Widgets.RowList.Create(rowConfig)
    if not row then return nil end
  end

  -- For fixed-size raids, don't add controls
  if not isVariableSize then
    return row
  end

  -- For variable-size raids, reuse or create slider + editbox on the right
  local minSize, maxSize = raid.sizeMin, raid.sizeMax
  -- Query Raids module for current size
  local currentSize = AutoLFM.Logic.Content.Raids.GetRaidSize(index) or minSize

  -- Create a reference table to hold editbox reference for closure
  local controls = {}

  -- Check if controls already exist
  local existingEditBox = getglobal("AutoLFM_RaidSizeEditBox" .. index)
  local existingSlider = getglobal("AutoLFM_RaidSizeSlider" .. index)

  if existingEditBox and existingSlider then
    -- Reuse existing controls
    controls.editBox = existingEditBox
    controls.slider = existingSlider

    -- Update values and callbacks
    controls.editBox:SetText(tostring(currentSize))
    controls.editBox:SetScript("OnTextChanged", function()
      local value = tonumber(controls.editBox:GetText())
      if value and value >= minSize and value <= maxSize then
        AutoLFM.Core.Maestro.DispatchCommand("Raids.SetSize", index, value)
        if controls.slider then
          controls.slider:SetValue(value)
        end
      end
    end)

    controls.slider:SetMinMaxValues(minSize, maxSize)
    controls.slider:SetValue(currentSize)
    controls.slider:SetScript("OnValueChanged", function()
      local value = this:GetValue()
      AutoLFM.Core.Maestro.DispatchCommand("Raids.SetSize", index, value)
      if controls.editBox then
        controls.editBox:SetText(tostring(math.floor(value)))
      end
    end)
  else
    -- Create new controls
    -- EditBox (small, for size display/input)
    controls.editBox = AutoLFM.UI.Widgets.EditBox.Create({
      parent = row,
      name = "AutoLFM_RaidSizeEditBox" .. index,
      width = 30,
      height = 18,
      maxLetters = 2,
      justify = "CENTER",
      insetX = 3,
      insetY = 2,
      useBackdrop = false,
      bgAlpha = 0.3,
      border = true,
      point = {
        point = "RIGHT",
        relativeTo = row,
        relativePoint = "RIGHT",
        x = -5,
        y = 0
      },
      onTextChanged = function()
        local value = tonumber(controls.editBox:GetText())
        if value and value >= minSize and value <= maxSize then
          AutoLFM.Core.Maestro.DispatchCommand("Raids.SetSize", index, value)
          if controls.slider then
            controls.slider:SetValue(value)
          end
        end
      end
    })
    controls.editBox:SetText(tostring(currentSize))

    -- Slider (next to editbox)
    controls.slider = AutoLFM.UI.Widgets.Slider.Create({
      parent = row,
      name = "AutoLFM_RaidSizeSlider" .. index,
      width = 80,
      height = 15,
      minValue = minSize,
      maxValue = maxSize,
      initialValue = currentSize,
      valueStep = 1,
      point = {
        point = "RIGHT",
        relativeTo = controls.editBox,
        relativePoint = "LEFT",
        x = -5,
        y = 0
      },
      onValueChanged = function(value)
        AutoLFM.Core.Maestro.DispatchCommand("Raids.SetSize", index, value)
        if controls.editBox then
          controls.editBox:SetText(tostring(math.floor(value)))
        end
      end
    })

    controls.editBox:Hide()
    controls.slider:Hide()
  end

  -- Setup common scripts (for both new and reused controls)
  -- Select all text when clicking on editbox
  controls.editBox:SetScript("OnEditFocusGained", function()
    controls.editBox:HighlightText()
  end)

  -- Propagate hover state to row when mouse is over editbox
  controls.editBox:SetScript("OnEnter", function()
    if row.GetScript and row:GetScript("OnEnter") then
      row:GetScript("OnEnter")()
    end
  end)
  controls.editBox:SetScript("OnLeave", function()
    if row.GetScript and row:GetScript("OnLeave") then
      row:GetScript("OnLeave")()
    end
  end)

  -- Propagate hover state to row when mouse is over slider
  controls.slider:SetScript("OnEnter", function()
    if row.GetScript and row:GetScript("OnEnter") then
      row:GetScript("OnEnter")()
    end
  end)
  controls.slider:SetScript("OnLeave", function()
    if row.GetScript and row:GetScript("OnLeave") then
      row:GetScript("OnLeave")()
    end
  end)

  -- Store references
  row.sizeSlider = controls.slider
  row.sizeEditBox = controls.editBox
  row.isVariableSize = isVariableSize
  row.sizeRangeLabel = row.rightLabel  -- Keep reference to the original label

  -- Show controls if already selected
  if AutoLFM.Logic.Content.Raids.IsSelected(index) then
    if row.sizeRangeLabel then row.sizeRangeLabel:Hide() end
    controls.slider:Show()
    controls.editBox:Show()
  end

  return row
end

-----------------------------------------------------------------------------
-- Panel creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Raids.Create(parent, raids)
  if not parent or not raids then return nil end

  -- Clear existing rows reference (frames will be reused)
  raidRows = {}

  -- Create raid rows
  local yOffset = 0
  for i = 1, table.getn(raids) do
    local raid = raids[i]
    if raid then
      local row = CreateRaidRow(parent, raid, i, yOffset)
      if row then
        raidRows[i] = row
        yOffset = yOffset + (AutoLFM.Core.Constants.ROW_HEIGHT or 20)
      end
    end
  end

  return parent
end

-----------------------------------------------------------------------------
-- Update Row Size Controls
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Raids.UpdateRowSizeControls(raidIndex, isChecked)
  local row = raidRows[raidIndex]
  if not row or not row.isVariableSize then return end

  if isChecked then
    -- Hide the size range label
    if row.sizeRangeLabel then row.sizeRangeLabel:Hide() end

    -- Show slider and editbox
    if row.sizeSlider then row.sizeSlider:Show() end
    if row.sizeEditBox then row.sizeEditBox:Show() end

    -- Update values - query Raids module
    local raids = AutoLFM.Core.Constants.RAIDS
    local minSize = raids[raidIndex] and raids[raidIndex].sizeMin or 10
    local currentSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raidIndex) or minSize
    if row.sizeSlider then row.sizeSlider:SetValue(currentSize) end
    if row.sizeEditBox then row.sizeEditBox:SetText(tostring(currentSize)) end
  else
    -- Hide slider and editbox
    if row.sizeSlider then row.sizeSlider:Hide() end
    if row.sizeEditBox then row.sizeEditBox:Hide() end

    -- Show the size range label again
    if row.sizeRangeLabel then row.sizeRangeLabel:Show() end
  end
end

-----------------------------------------------------------------------------
-- State restoration
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Raids.RestoreState(raids)
  if not raids then return end

  -- First pass: uncheck all raids to ensure clean state
  for i = 1, table.getn(raids) do
    local check = getglobal("AutoLFM_RaidCheckbox" .. i)
    if check then
      AutoLFM.Core.Utils.SetCheckboxState(check, false)
      AutoLFM.UI.Content.Raids.UpdateRowSizeControls(i, false)
    end
  end

  -- Find the selected raid index (should be max 1) - query Raids module
  local selectedRaidIndex = nil
  for i = 1, table.getn(raids) do
    if AutoLFM.Logic.Content.Raids.IsSelected(i) then
      selectedRaidIndex = i
      break  -- Only one raid should be selected
    end
  end

  -- Second pass: restore only the actually selected raid
  if selectedRaidIndex then
    local check = getglobal("AutoLFM_RaidCheckbox" .. selectedRaidIndex)
    if check then
      -- Use SetCheckboxState to avoid triggering OnClick during restoration
      AutoLFM.Core.Utils.SetCheckboxState(check, true)
      AutoLFM.UI.Content.Raids.UpdateRowSizeControls(selectedRaidIndex, true)
    end

    -- Synchronize the selection order tracker with the restored state (called once)
    if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.ResetRaidSelectionOrder then
      AutoLFM.Logic.Selection.ResetRaidSelectionOrder(selectedRaidIndex)
    end
  end
end
