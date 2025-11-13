--=============================================================================
-- AutoLFM: RowList Widget
--   Reusable row widget with checkbox, labels, and hover effects
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Widgets = AutoLFM.UI.Widgets or {}
AutoLFM.UI.Widgets.RowList = AutoLFM.UI.Widgets.RowList or {}

-----------------------------------------------------------------------------
-- Hover Effects
-----------------------------------------------------------------------------
local function SetupRowHover(frame, checkbox, label, rightLabel, bgColor, textColor)
  if not frame or not checkbox or not label or not bgColor or not textColor then return end

  frame:SetScript("OnEnter", function()
    frame:SetBackdrop({
      bgFile = AutoLFM.Core.Constants.TEXTURE_PATH .. "white",
      insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, 0.3)
    label:SetTextColor(1, 1, 1)
    if rightLabel then
      rightLabel:SetTextColor(1, 1, 1)
    end
    checkbox:LockHighlight()
  end)

  frame:SetScript("OnLeave", function()
    frame:SetBackdrop(nil)
    label:SetTextColor(textColor.r, textColor.g, textColor.b)
    if rightLabel then
      rightLabel:SetTextColor(textColor.r, textColor.g, textColor.b)
    end
    checkbox:UnlockHighlight()
  end)
end

-----------------------------------------------------------------------------
-- Click Handlers
-----------------------------------------------------------------------------
local function SetupClickToToggle(frame, checkbox, onToggleFunc)
  if not frame or not checkbox then return end

  frame:SetScript("OnClick", function()
    checkbox:SetChecked(not checkbox:GetChecked())
    if onToggleFunc then
      onToggleFunc(checkbox:GetChecked())
    end
  end)
end

local function SetupCheckboxClick(checkbox, onToggleFunc)
  if not checkbox or not onToggleFunc then return end

  checkbox:SetScript("OnClick", function()
    -- In WoW 1.12, GetChecked() may return old state during OnClick
    -- We need to use 'this' which is the checkbox being clicked
    local isChecked = this:GetChecked()
    onToggleFunc(isChecked)
  end)
end

-----------------------------------------------------------------------------
-- Frame Creation
-----------------------------------------------------------------------------
local function CreateRowFrame(config)
  local frame = CreateFrame("Button", config.frameName, config.parent)
  frame:SetHeight(config.rowHeight or AutoLFM.Core.Constants.ROW_HEIGHT)
  frame:SetWidth(config.rowWidth or 300)
  frame:SetPoint("TOPLEFT", config.parent, "TOPLEFT", 0, -(config.yOffset or 0))
  return frame
end

local function CreateCheckbox(frame, config)
  local checkbox = CreateFrame("CheckButton", config.checkboxName, frame, "UICheckButtonTemplate")
  checkbox:SetWidth(config.checkboxSize or AutoLFM.Core.Constants.CHECKBOX_SIZE)
  checkbox:SetHeight(config.checkboxSize or AutoLFM.Core.Constants.CHECKBOX_SIZE)
  checkbox:SetPoint("LEFT", frame, "LEFT", 0, 0)

  if config.isChecked ~= nil then
    checkbox:SetChecked(config.isChecked)
  end

  return checkbox
end

local function CreateLabels(frame, config)
  local rightLabel = nil
  if config.rightText then
    rightLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightLabel:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    rightLabel:SetText(config.rightText)
  end

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("LEFT", frame.checkbox, "RIGHT", 2, 0)
  label:SetText(config.mainText or "")

  return label, rightLabel
end

local function ApplyColors(label, rightLabel, color)
  if not color then return end

  local r = color.r or 1
  local g = color.g or 1
  local b = color.b or 1

  label:SetTextColor(r, g, b)
  if rightLabel then
    rightLabel:SetTextColor(r, g, b)
  end
end

local function ApplyCustomProperties(frame, properties)
  if not properties then return end

  for key, value in pairs(properties) do
    frame[key] = value
  end
end

-----------------------------------------------------------------------------
-- Create Single Selectable Row
-----------------------------------------------------------------------------
-- config = {
--   parent = parent frame,
--   frameName = "FrameName",
--   checkboxName = "CheckboxName",
--   yOffset = 0,
--   mainText = "Main text",
--   rightText = "(optional right text)",
--   color = {r=1, g=1, b=1},
--   isChecked = true/false,
--   onCheckboxClick = function(checkbox, isChecked) end,
--   customProperties = {key=value, ...}
-- }
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.RowList.Create(config)
  if not config or not config.parent then return nil end

  -- Create frame and checkbox
  local frame = CreateRowFrame(config)
  local checkbox = CreateCheckbox(frame, config)
  frame.checkbox = checkbox

  -- Create labels
  local label, rightLabel = CreateLabels(frame, config)
  frame.label = label
  frame.rightLabel = rightLabel

  -- Apply colors
  ApplyColors(label, rightLabel, config.color)

  -- Add custom properties
  ApplyCustomProperties(frame, config.customProperties)

  -- Setup hover effects
  if config.color then
    SetupRowHover(frame, checkbox, label, rightLabel, config.color, config.color)
  end

  -- Setup click handlers
  if config.onCheckboxClick then
    SetupClickToToggle(frame, checkbox, function(isChecked)
      config.onCheckboxClick(checkbox, isChecked)
    end)

    SetupCheckboxClick(checkbox, function(isChecked)
      config.onCheckboxClick(checkbox, isChecked)
    end)
  end

  return frame
end
