--=============================================================================
-- AutoLFM: RowList Logic
--   List management logic for rows (creation, update, reuse)
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Widgets = AutoLFM.Logic.Widgets or {}
AutoLFM.Logic.Widgets.RowList = AutoLFM.Logic.Widgets.RowList or {}

-----------------------------------------------------------------------------
-- Row Update
-----------------------------------------------------------------------------
local function UpdateExistingRow(row, rowData, parent, yOffset)
  -- Update labels
  if row.label and rowData.mainText then
    row.label:SetText(rowData.mainText)
  end

  if row.rightLabel and rowData.rightText then
    row.rightLabel:SetText(rowData.rightText)
  end

  -- Update colors
  if rowData.color then
    if row.label then
      row.label:SetTextColor(rowData.color.r, rowData.color.g, rowData.color.b)
    end
    if row.rightLabel then
      row.rightLabel:SetTextColor(rowData.color.r, rowData.color.g, rowData.color.b)
    end

    -- Update hover effects with new color
    if row.checkbox then
      row:SetScript("OnEnter", function()
        row:SetBackdrop({
          bgFile = AutoLFM.Core.Constants.TEXTURE_PATH .. "white",
          insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        row:SetBackdropColor(rowData.color.r, rowData.color.g, rowData.color.b, 0.3)
        row.label:SetTextColor(1, 1, 1)
        if row.rightLabel then
          row.rightLabel:SetTextColor(1, 1, 1)
        end
        row.checkbox:LockHighlight()
      end)

      row:SetScript("OnLeave", function()
        row:SetBackdrop(nil)
        row.label:SetTextColor(rowData.color.r, rowData.color.g, rowData.color.b)
        if row.rightLabel then
          row.rightLabel:SetTextColor(rowData.color.r, rowData.color.g, rowData.color.b)
        end
        row.checkbox:UnlockHighlight()
      end)
    end
  end

  -- Update custom properties
  if rowData.customProperties then
    for key, value in pairs(rowData.customProperties) do
      row[key] = value
    end
  end

  -- Update position
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOffset)
  row:Show()
end

-----------------------------------------------------------------------------
-- Create List of Selectable Rows
-----------------------------------------------------------------------------
-- config = {
--   parent: Frame to attach rows to
--   items: Array of items to create rows for
--   rowPrefix: Prefix for row frame names (e.g., "AutoLFM_DungeonRow")
--   checkboxPrefix: Prefix for checkbox names (e.g., "AutoLFM_DungeonCheckbox")
--   getRowData: function(item, index) -> {mainText, rightText, color, customProperties}
--   onToggle: function(index, isChecked) - called when checkbox is toggled (optional)
-- }
-- Returns: {rows = {}, totalHeight = number}
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.RowList.CreateList(config)
  if not config or not config.parent or not config.items or not config.getRowData then
    return nil
  end

  local parent = config.parent
  local items = config.items
  local rowPrefix = config.rowPrefix or "AutoLFM_Row"
  local checkboxPrefix = config.checkboxPrefix or "AutoLFM_Checkbox"
  local onToggle = config.onToggle

  -- Hide all existing rows with this prefix
  local i = 1
  while i <= 50 do
    local existingRow = getglobal(rowPrefix .. i)
    if not existingRow then break end  -- Stop when no more rows exist
    existingRow:Hide()
    i = i + 1
  end

  local rows = {}
  local yOffset = 0
  local itemCount = table.getn(items)

  -- Create or update rows
  for i = 1, itemCount do
    local item = items[i]
    local rowData = config.getRowData(item, i)

    if rowData then
      local frameName = rowPrefix .. i
      local checkboxName = checkboxPrefix .. i
      local row = getglobal(frameName)
      local rowIndex = i  -- Capture index for closure

      -- Prepare callback if onToggle is provided
      local onCheckboxClick = nil
      if onToggle then
        onCheckboxClick = function(checkbox, isChecked)
          onToggle(rowIndex, isChecked)
        end
      end

      if row then
        -- Reuse and update existing row
        UpdateExistingRow(row, rowData, parent, yOffset)

        -- Update click handlers for existing row
        if onCheckboxClick then
          row.checkbox:SetScript("OnClick", function()
            -- Read state after a tiny delay to ensure GetChecked() returns new value
            local checkbox = this
            local isChecked = checkbox:GetChecked()
            onCheckboxClick(checkbox, isChecked)
          end)
          row:SetScript("OnClick", function()
            row.checkbox:Click()
          end)
        end
      else
        -- Create new row using UI widget
        row = AutoLFM.UI.Widgets.RowList.Create({
          parent = parent,
          frameName = frameName,
          checkboxName = checkboxName,
          yOffset = yOffset,
          mainText = rowData.mainText or "",
          rightText = rowData.rightText or "",
          color = rowData.color or {r = 1, g = 1, b = 1},
          isChecked = false,
          customProperties = rowData.customProperties,
          onCheckboxClick = onCheckboxClick
        })
      end

      if row then
        rows[i] = row
        yOffset = yOffset + AutoLFM.Core.Constants.ROW_HEIGHT
      end
    end
  end

  -- Update parent height
  parent:SetHeight(math.max(yOffset, 1))

  return {
    rows = rows,
    totalHeight = yOffset
  }
end
