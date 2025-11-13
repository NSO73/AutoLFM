--=============================================================================
-- AutoLFM: Core Utilities
--   Shared utility functions
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Utils = AutoLFM.Core.Utils or {}

-----------------------------------------------------------------------------
-- Frame Reference Cache (Private)
-----------------------------------------------------------------------------
local frameCache = {}

-----------------------------------------------------------------------------
-- Frame Reference Utilities
-----------------------------------------------------------------------------
function AutoLFM.Core.Utils.GetFrame(frameName)
  if not frameName then return nil end

  if frameCache[frameName] then
    return frameCache[frameName]
  end

  local frame = getglobal(frameName)
  if frame then
    frameCache[frameName] = frame
  end

  return frame
end

function AutoLFM.Core.Utils.ClearFrameCache()
  frameCache = {}
end

-----------------------------------------------------------------------------
-- String Utilities
-----------------------------------------------------------------------------
-- Truncate text to fit within a specific width, using binary search
function AutoLFM.Core.Utils.TruncateByWidth(text, maxWidth, fontString, ellipsis)
  if not text then return "", false end
  if not fontString then return text, false end
  if not maxWidth or maxWidth <= 0 then return text, false end

  ellipsis = ellipsis or "..."

  fontString:SetText(text)
  local textWidth = fontString:GetStringWidth()

  if textWidth <= maxWidth then
    return text, false
  end

  fontString:SetText(ellipsis)
  local ellipsisWidth = fontString:GetStringWidth()
  local availableWidth = maxWidth - ellipsisWidth

  if availableWidth <= 0 then
    return ellipsis, true
  end

  local len = string.len(text)
  local left, right = 1, len
  local result = text

  while left <= right do
    local mid = math.floor((left + right) / 2)
    local truncated = string.sub(text, 1, mid)
    fontString:SetText(truncated)
    local width = fontString:GetStringWidth()

    if width <= availableWidth then
      result = truncated
      left = mid + 1
    else
      right = mid - 1
    end
  end

  -- Try to break at last word boundary if reasonable
  local lastSpace = 1
  for i = string.len(result), 1, -1 do
    if string.sub(result, i, i) == " " then
      lastSpace = i
      break
    end
  end

  if lastSpace > 1 and lastSpace > string.len(result) * 0.7 then
    result = string.sub(result, 1, lastSpace - 1)
  end

  return result .. ellipsis, true
end

-----------------------------------------------------------------------------
-- Color Utilities
-----------------------------------------------------------------------------
function AutoLFM.Core.Utils.RGBToHex(r, g, b)
  if not r or not g or not b then return "ff808080" end
  return string.format("ff%02x%02x%02x",
    math.floor(r * 255),
    math.floor(g * 255),
    math.floor(b * 255))
end

function AutoLFM.Core.Utils.ColorizeText(text, colorKey)
  if not text then return "" end
  if not colorKey then return text end

  local colorConstantKey = string.upper(colorKey)

  local color = AutoLFM.Core.Constants.COLORS[colorConstantKey]
  if not color or not color.hex then return text end

  return "|cff" .. string.lower(color.hex) .. text .. "|r"
end

-- Shorthand alias for ColorizeText
function AutoLFM.Color(text, colorKey)
  return AutoLFM.Core.Utils.ColorizeText(text, colorKey)
end

-----------------------------------------------------------------------------
-- Level-based Priority Calculation
-----------------------------------------------------------------------------
-- Calculate priority (1-5) based on player level vs content level range
-- Priority: 1 = green, 2 = yellow, 3 = orange, 4 = red, 5 = gray
function AutoLFM.Core.Utils.CalculateLevelPriority(playerLevel, minLevel, maxLevel)
  if not playerLevel or not minLevel or not maxLevel then return 5 end
  if minLevel < 1 or maxLevel < 1 or minLevel > maxLevel then return 5 end

  -- Get dynamic green threshold based on player level tier
  local thresholdIndex = math.min(math.floor(playerLevel / 10) + 1, 5)
  local greenThreshold = AutoLFM.Core.Constants.GREEN_THRESHOLDS[thresholdIndex] or 8

  -- Calculate level difference
  local diff
  if minLevel == maxLevel then
    diff = minLevel - playerLevel
  else
    local avg = math.floor((minLevel + maxLevel) / 2)
    diff = avg - playerLevel
  end

  -- Priority assignments based on level difference
  if diff >= 5 then return 4 end          -- Red: 5+ levels above
  if diff >= 3 then return 3 end          -- Orange: 3-4 levels above
  if diff >= -2 then return 2 end         -- Yellow: -2 to +2 levels
  if diff >= -greenThreshold then return 1 end  -- Green: dynamic threshold
  return 5                                -- Gray: below green threshold
end

-- Get color from priority number, color name, or color object
-- Returns: color object OR r, g, b values if returnRGBOnly=true
function AutoLFM.Core.Utils.GetColor(identifier, returnRGBOnly)
  local color

  -- If identifier is a number (priority 1-5)
  if type(identifier) == "number" then
    -- Map priority to color: 1=green, 2=yellow, 3=orange, 4=red, 5=gray
    local priorityColorMap = {
      [1] = AutoLFM.Core.Constants.COLORS.GREEN,
      [2] = AutoLFM.Core.Constants.COLORS.YELLOW,
      [3] = AutoLFM.Core.Constants.COLORS.ORANGE,
      [4] = AutoLFM.Core.Constants.COLORS.RED,
      [5] = AutoLFM.Core.Constants.COLORS.GRAY
    }
    color = priorityColorMap[identifier]
  -- If identifier is a string (color name)
  elseif type(identifier) == "string" then
    color = AutoLFM.Core.Constants.COLORS[string.upper(identifier)]
  -- If identifier is already a color object
  elseif type(identifier) == "table" and identifier.r and identifier.g and identifier.b then
    color = identifier
  end

  -- Fallback to gold if not found
  if not color then
    color = AutoLFM.Core.Constants.COLORS.GOLD
  end

  if returnRGBOnly then
    return color.r, color.g, color.b
  end

  return color
end

-----------------------------------------------------------------------------
-- Font Utilities
-----------------------------------------------------------------------------
-- Set font string color using color key
function AutoLFM.Core.Utils.SetFontColor(fontString, colorKey)
  if not fontString then return end
  local color = AutoLFM.Core.Utils.GetColor(colorKey)
  if color then
    fontString:SetTextColor(color.r, color.g, color.b)
  end
end

-----------------------------------------------------------------------------
-- Checkbox Utilities
-----------------------------------------------------------------------------
-- Silently set checkbox state without triggering OnClick
function AutoLFM.Core.Utils.SetCheckboxState(checkbox, checked)
  if not checkbox then return end

  local oldScript = checkbox:GetScript("OnClick")
  checkbox:SetScript("OnClick", nil)
  checkbox:SetChecked(checked)
  checkbox:SetScript("OnClick", oldScript)
end

-----------------------------------------------------------------------------
-- Chat Output
-----------------------------------------------------------------------------
function AutoLFM.Core.Utils.Print(message, colorKey)
  if not message then return end

  local text = AutoLFM.Core.Utils.ColorizeText(message, colorKey or "gold")

  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(AutoLFM.Core.Constants.CHAT_PREFIX .. text)
  end
end

function AutoLFM.Core.Utils.PrintInfo(message)
  AutoLFM.Core.Utils.Print(message, "white")
end

function AutoLFM.Core.Utils.PrintSuccess(message)
  AutoLFM.Core.Utils.Print(message, "green")
end

function AutoLFM.Core.Utils.PrintError(message)
  AutoLFM.Core.Utils.Print(message, "red")
end

function AutoLFM.Core.Utils.PrintWarning(message)
  AutoLFM.Core.Utils.Print(message, "orange")
end

function AutoLFM.Core.Utils.PrintNote(message)
  AutoLFM.Core.Utils.Print(message, "gray")
end

function AutoLFM.Core.Utils.PrintTitle(message)
  AutoLFM.Core.Utils.Print(message, "blue")
end
