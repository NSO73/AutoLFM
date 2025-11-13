--=============================================================================
-- AutoLFM: Channels Widget
--   Reusable channels selector component
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Widgets = AutoLFM.UI.Widgets or {}
AutoLFM.UI.Widgets.Channels = AutoLFM.UI.Widgets.Channels or {}

-----------------------------------------------------------------------------
-- Channel Checkbox Creation
-----------------------------------------------------------------------------
local function CreateChannelCheckbox(parent, channelName, onToggle, lastCheckbox)
  if not parent or not channelName then return nil end

  local checkbox = CreateFrame("CheckButton", nil, parent)
  checkbox:SetWidth(AutoLFM.Core.Constants.CHECKBOX_SIZE)
  checkbox:SetHeight(AutoLFM.Core.Constants.CHECKBOX_SIZE)

  -- Position
  if lastCheckbox then
    checkbox:SetPoint("TOPLEFT", lastCheckbox, "BOTTOMLEFT", 0, -2)
  else
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, 0)
  end

  -- Normal texture
  checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")

  -- Pushed texture
  checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")

  -- Highlight
  checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")

  -- Checked texture
  local checkedTexture = checkbox:CreateTexture(nil, "ARTWORK")
  checkedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  checkedTexture:SetAllPoints()
  checkbox:SetCheckedTexture(checkedTexture)

  -- Label
  local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
  label:SetText(channelName)

  -- Set initial availability
  local isAvailable = true
  if AutoLFM.Logic.Widgets.Channels.IsChannelAvailable then
    isAvailable = AutoLFM.Logic.Widgets.Channels.IsChannelAvailable(channelName)
  end
  if isAvailable then
    label:SetTextColor(1, 0.82, 0)
    checkbox:Enable()
  else
    label:SetTextColor(0.5, 0.5, 0.5)
    checkbox:Disable()
  end

  -- Click handler
  checkbox:SetScript("OnClick", function()
    if onToggle then
      onToggle(channelName, this:GetChecked())
    end
  end)

  -- Hover effects with tooltip (re-check availability dynamically)
  checkbox:SetScript("OnEnter", function()
    local currentAvailable = true
    if AutoLFM.Logic.Widgets.Channels.IsChannelAvailable then
      currentAvailable = AutoLFM.Logic.Widgets.Channels.IsChannelAvailable(channelName)
    end
    if currentAvailable then
      label:SetTextColor(0, 0.5, 1)
    else
      -- Show tooltip for unavailable channel with reason
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Channel not available", 1, 0.82, 0)

      -- Get detailed reason if available
      if AutoLFM.Logic.Widgets.Channels.GetChannelInfo then
        local channelInfo = AutoLFM.Logic.Widgets.Channels.GetChannelInfo(channelName)
        if channelInfo and channelInfo.reason and channelInfo.reason ~= "" then
          GameTooltip:AddLine(channelInfo.reason, 1, 1, 1)
        end
      end

      GameTooltip:Show()
    end
  end)

  checkbox:SetScript("OnLeave", function()
    local currentAvailable = true
    if AutoLFM.Logic.Widgets.Channels.IsChannelAvailable then
      currentAvailable = AutoLFM.Logic.Widgets.Channels.IsChannelAvailable(channelName)
    end
    if currentAvailable then
      label:SetTextColor(1, 0.82, 0)
    end
    GameTooltip:Hide()
  end)

  return checkbox, label
end

-----------------------------------------------------------------------------
-- Channels Panel Creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.Channels.Create(config)
  if not config or not config.parent then return nil end

  local panel = CreateFrame("Frame", config.name, config.parent)

  -- Set dimensions
  panel:SetWidth(config.width or 150)
  panel:SetHeight(config.height or 120)

  -- Set position
  if config.point then
    panel:SetPoint(config.point.point, config.point.relativeTo, config.point.relativePoint, config.point.x, config.point.y)
  end

  -- Available channels
  local channels = config.channels or (AutoLFM.Logic.Widgets.Channels.GetAvailableChannels and
                   AutoLFM.Logic.Widgets.Channels.GetAvailableChannels() or {"LookingForGroup", "World", "Hardcore"})
  local checkboxes = {}
  local labels = {}
  local lastCheckbox = nil

  for _, channelName in ipairs(channels) do
    local checkbox, label = CreateChannelCheckbox(panel, channelName, config.onToggle, lastCheckbox)
    checkboxes[channelName] = checkbox
    labels[channelName] = label
    lastCheckbox = checkbox

    -- Set initial state
    if config.getChannelState then
      checkbox:SetChecked(config.getChannelState(channelName))
    end
  end

  -- Update function to refresh checkbox states and availability
  function panel:UpdateChannels()
    for channelName, checkbox in pairs(checkboxes) do
      -- Update checked state
      if config.getChannelState then
        checkbox:SetChecked(config.getChannelState(channelName))
      end

      -- Update availability
      local isAvailable = true
      if AutoLFM.Logic.Widgets.Channels.IsChannelAvailable then
        isAvailable = AutoLFM.Logic.Widgets.Channels.IsChannelAvailable(channelName)
      end
      local label = labels[channelName]

      if isAvailable then
        label:SetTextColor(1, 0.82, 0)
        checkbox:Enable()
      else
        label:SetTextColor(0.5, 0.5, 0.5)
        checkbox:Disable()
      end
    end
  end

  return panel, checkboxes
end
