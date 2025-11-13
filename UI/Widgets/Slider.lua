--=============================================================================
-- AutoLFM: Slider Widget
--   Reusable slider component
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Widgets = AutoLFM.UI.Widgets or {}
AutoLFM.UI.Widgets.Slider = AutoLFM.UI.Widgets.Slider or {}

-----------------------------------------------------------------------------
-- Slider Creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.Slider.Create(config)
  if not config or not config.parent then return nil end

  local slider = CreateFrame("Slider", config.name, config.parent)

  -- Set dimensions
  slider:SetWidth(config.width or 150)
  slider:SetHeight(config.height or 17)

  -- Set position
  if config.point then
    slider:SetPoint(config.point.point, config.point.relativeTo, config.point.relativePoint, config.point.x, config.point.y)
  end

  -- Set orientation
  slider:SetOrientation(config.orientation or "HORIZONTAL")

  -- Set range
  slider:SetMinMaxValues(config.minValue or 0, config.maxValue or 100)
  slider:SetValue(config.initialValue or config.minValue or 0)
  slider:SetValueStep(config.valueStep or 1)

  -- Backdrop (like AutoLFM old)
  slider:SetBackdrop({
    bgFile = AutoLFM.Core.Constants.TEXTURE_PATH .. "sliderBackground",
    edgeFile = AutoLFM.Core.Constants.TEXTURE_PATH .. "sliderBorder",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = {left = 3, right = 3, top = 6, bottom = 6}
  })

  -- Thumb texture
  slider:SetThumbTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "sliderButtonHorizontal")

  -- Value display (optional)
  local valueText = nil
  if config.showValue then
    valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetText(math.floor(config.initialValue or config.minValue or 0))
  end

  -- OnValueChanged callback
  slider:SetScript("OnValueChanged", function()
    local value = this:GetValue()

    -- Update value display
    if valueText then
      valueText:SetText(math.floor(value))
    end

    -- Call custom callback
    if config.onValueChanged then
      config.onValueChanged(value)
    end
  end)

  -- Mouse wheel support
  slider:EnableMouseWheel(true)
  slider:SetScript("OnMouseWheel", function()
    local value = this:GetValue()
    local step = config.valueStep or 1
    if arg1 > 0 then
      this:SetValue(math.min(value + step, config.maxValue or 100))
    else
      this:SetValue(math.max(value - step, config.minValue or 0))
    end
  end)

  return slider, valueText
end
