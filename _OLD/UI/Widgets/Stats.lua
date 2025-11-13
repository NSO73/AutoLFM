--=============================================================================
-- AutoLFM: Stats Widget
--   Reusable statistics display component
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Widgets = AutoLFM.UI.Widgets or {}
AutoLFM.UI.Widgets.Stats = AutoLFM.UI.Widgets.Stats or {}

-----------------------------------------------------------------------------
-- Stats Row Creation
-----------------------------------------------------------------------------
local function CreateStatRow(parent, iconTexture, label, initialValue, point)
  if not parent or not label then return nil end

  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(200)
  row:SetHeight(16)

  if point then
    row:SetPoint(point.point, point.relativeTo, point.relativePoint, point.x, point.y)
  end

  -- Icon
  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(16)
  icon:SetHeight(16)
  icon:SetPoint("LEFT", row, "LEFT", 0, 0)
  icon:SetTexture(iconTexture)

  -- Label
  local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  labelText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
  labelText:SetText(label)
  labelText:SetTextColor(1, 1, 1)

  -- Value
  local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  valueText:SetPoint("LEFT", labelText, "RIGHT", 5, 0)
  valueText:SetText(initialValue or "0")
  valueText:SetTextColor(1, 0.82, 0)

  return row, valueText
end

-----------------------------------------------------------------------------
-- Stats Panel Creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.Stats.Create(config)
  if not config or not config.parent then return nil end

  local panel = CreateFrame("Frame", config.name, config.parent)

  -- Set dimensions
  panel:SetWidth(config.width or 200)
  panel:SetHeight(config.height or 70)

  -- Set position
  if config.point then
    panel:SetPoint(config.point.point, config.point.relativeTo, config.point.relativePoint, config.point.x, config.point.y)
  end

  -- Title (optional)
  local title = nil
  if config.title then
    title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -5)
    title:SetText(config.title)
    title:SetTextColor(1, 0.82, 0)
  end

  -- Stats rows
  local stats = {}
  local lastAnchor = title or panel
  local offsetY = title and -25 or -5

  -- Check if horizontal layout is requested
  if config.horizontal then
    -- Duration (left)
    local durationRow, durationValue = CreateStatRow(panel, AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\bag", "Duration:", "00:00", {
      point = "LEFT",
      relativeTo = panel,
      relativePoint = "LEFT",
      x = 5,
      y = 0
    })
    stats.durationValue = durationValue

    -- Sent (center)
    local sentRow, sentValue = CreateStatRow(panel, AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\book", "Sent:", "0", {
      point = "LEFT",
      relativeTo = durationRow,
      relativePoint = "RIGHT",
      x = 20,
      y = 0
    })
    stats.sentValue = sentValue

    -- Next (right of sent)
    local nextRow, nextValue = CreateStatRow(panel, AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\send", "Next:", "--", {
      point = "LEFT",
      relativeTo = sentRow,
      relativePoint = "RIGHT",
      x = 20,
      y = 0
    })
    stats.nextValue = nextValue
  else
    -- Vertical layout (original)
    -- Duration
    local durationRow, durationValue = CreateStatRow(panel, AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\bag", "Duration:", "00:00", {
      point = "TOP",
      relativeTo = lastAnchor,
      relativePoint = title and "BOTTOM" or "TOP",
      x = 0,
      y = offsetY
    })
    stats.durationValue = durationValue

    -- Messages sent
    local sentRow, sentValue = CreateStatRow(panel, AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\book", "Sent:", "0", {
      point = "TOP",
      relativeTo = durationRow,
      relativePoint = "BOTTOM",
      x = 0,
      y = -6
    })
    stats.sentValue = sentValue

    -- Next message
    local nextRow, nextValue = CreateStatRow(panel, AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\send", "Next:", "--", {
      point = "TOP",
      relativeTo = sentRow,
      relativePoint = "BOTTOM",
      x = 0,
      y = -6
    })
    stats.nextValue = nextValue
  end

  -- Update function (called by Logic layer)
  function panel:UpdateStats(statsData)
    if not statsData then return end
    if statsData.duration then stats.durationValue:SetText(statsData.duration) end
    if statsData.messageCount then stats.sentValue:SetText(tostring(statsData.messageCount)) end
    if statsData.timeUntilNext then stats.nextValue:SetText(statsData.timeUntilNext) end
  end

  return panel
end
