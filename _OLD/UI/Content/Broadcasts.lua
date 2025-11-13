--=============================================================================
-- AutoLFM: Broadcasts Content
--   Custom broadcasts panel UI
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Broadcasts = AutoLFM.UI.Content.Broadcasts or {}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local panel = nil
local editBox = nil
local statsPanel = nil
local channelsPanel = nil
local dungeonTemplateEditBox = nil
local raidTemplateEditBox = nil

-----------------------------------------------------------------------------
-- Panel creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Broadcasts.Create(parent)
  if not parent then return nil end

  -- Set parent height to fit content without scrolling
  parent:SetHeight(AutoLFM.Core.Constants.CONTENT_DEFAULT_HEIGHT)

  panel = CreateFrame("Frame", "AutoLFM_Panel_Broadcasts", parent)
  panel:SetAllPoints()

  -- EditBox for custom broadcast message
  editBox = AutoLFM.UI.Widgets.EditBox.Create({
    parent = panel,
    name = "AutoLFM_Panel_Broadcasts_EditBox",
    placeholder = "(Use custom message)",
    point = {
      point = "TOPLEFT",
      relativeTo = panel,
      relativePoint = "TOPLEFT",
      x = 5,
      y = -5
    },
    width = 280,
    height = 24,
    maxLetters = 150,
    multiline = true,
    border = true,
    justifyV = "MIDDLE",
    enableLinkIntegration = true,
    onTextChanged = function()
      AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetCustomMessage", editBox:GetText() or "")
    end
  })

  -- Restore saved message from state
  local savedMessage = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage()
  if savedMessage then
    editBox:SetText(savedMessage)
  end

  -- Interval Slider
  local sliderIcon = panel:CreateTexture(nil, "ARTWORK")
  sliderIcon:SetWidth(16)
  sliderIcon:SetHeight(16)
  sliderIcon:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -10)
  sliderIcon:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\tool")

  local sliderLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sliderLabel:SetPoint("LEFT", sliderIcon, "RIGHT", 5, 0)
  sliderLabel:SetText("Interval:")
  sliderLabel:SetTextColor(1, 1, 1)

  local slider, sliderValue = AutoLFM.UI.Widgets.Slider.Create({
    parent = panel,
    name = "AutoLFM_Panel_Broadcasts_Slider",
    width = 145,
    height = 17,
    minValue = AutoLFM.Core.Constants.INTERVAL_MIN,
    maxValue = AutoLFM.Core.Constants.INTERVAL_MAX,
    initialValue = AutoLFM.Logic.Content.Broadcasts.GetInterval() or 60,
    valueStep = AutoLFM.Core.Constants.INTERVAL_STEP,
    showValue = false,
    point = {
      point = "LEFT",
      relativeTo = sliderLabel,
      relativePoint = "RIGHT",
      x = 10,
      y = 0
    },
    onValueChanged = function(value)
      -- Use new command architecture
      AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetInterval", value)
    end
  })

  -- Custom value text with " secs"
  local customValueText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  customValueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
  local initialInterval = AutoLFM.Logic.Content.Broadcasts.GetInterval() or 60
  customValueText:SetText(math.floor(initialInterval) .. " secs")

  -- Update custom value text
  slider:SetScript("OnValueChanged", function()
    local value = this:GetValue()
    customValueText:SetText(math.floor(value) .. " secs")
    -- Use new command architecture
    AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.SetInterval", value)
  end)

  -- Channels icon and label
  local channelsIcon = panel:CreateTexture(nil, "ARTWORK")
  channelsIcon:SetWidth(16)
  channelsIcon:SetHeight(16)
  channelsIcon:SetPoint("TOPLEFT", sliderIcon, "BOTTOMLEFT", 0, -12)
  channelsIcon:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\channel")

  local channelsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  channelsLabel:SetPoint("LEFT", channelsIcon, "RIGHT", 5, 0)
  channelsLabel:SetText("Channels:")
  channelsLabel:SetTextColor(1, 1, 1)

  -- Channels Panel (all possible channels, availability checked dynamically)
  channelsPanel = AutoLFM.UI.Widgets.Channels.Create({
    parent = panel,
    name = "AutoLFM_Panel_Broadcasts_Channels",
    width = 150,
    height = 90,
    title = nil,  -- No title, we have icon + label above
    channels = {"LookingForGroup", "World", "Hardcore", "testketa", "testketata"},  -- All possible channels
    point = {
      point = "TOPLEFT",
      relativeTo = channelsIcon,
      relativePoint = "BOTTOMLEFT",
      x = 0,
      y = -5
    },
    onToggle = function(channelName, isChecked)
      -- Use new command architecture
      AutoLFM.Core.Maestro.DispatchCommand("Broadcasts.ToggleChannel", channelName, isChecked)
    end,
    getChannelState = function(channelName)
      -- Query Broadcasts module
      return AutoLFM.Logic.Content.Broadcasts.IsChannelSelected(channelName)
    end
  })

  -- Stats Panel (vertical layout on the right, aligned with Channels)
  statsPanel = AutoLFM.UI.Widgets.Stats.Create({
    parent = panel,
    name = "AutoLFM_Panel_Broadcasts_Stats",
    width = 200,
    height = 80,
    title = nil,
    point = {
      point = "TOPLEFT",
      relativeTo = channelsIcon,
      relativePoint = "TOPRIGHT",
      x = 150,
      y = -16
    }
  })

  -- Attach update logic (Logic layer)
  if AutoLFM.Logic.Widgets.Stats and AutoLFM.Logic.Widgets.Stats.AttachUpdateLogic then
    AutoLFM.Logic.Widgets.Stats.AttachUpdateLogic(statsPanel)
  end

  -- Message Templates Section (below channels/stats)
  local dungeonIcon = panel:CreateTexture(nil, "ARTWORK")
  dungeonIcon:SetWidth(16)
  dungeonIcon:SetHeight(16)
  dungeonIcon:SetPoint("TOPLEFT", channelsIcon, "BOTTOMLEFT", 0, -85)
  dungeonIcon:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\chat")

  local dungeonLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dungeonLabel:SetPoint("LEFT", dungeonIcon, "RIGHT", 5, 0)
  dungeonLabel:SetText("Dungeons Template:")
  dungeonLabel:SetTextColor(1, 1, 1)

  -- Dungeon Template EditBox (create first)
  dungeonTemplateEditBox = CreateFrame("EditBox", "AutoLFM_DungeonTemplateEditBox", panel)
  dungeonTemplateEditBox:SetWidth(285)
  dungeonTemplateEditBox:SetHeight(24)
  dungeonTemplateEditBox:SetPoint("TOPLEFT", dungeonIcon, "BOTTOMLEFT", 0, 0)
  dungeonTemplateEditBox:SetFontObject(GameFontNormalSmall)
  dungeonTemplateEditBox:SetAutoFocus(false)
  dungeonTemplateEditBox:SetMaxLetters(100)

  -- Store current text in a local variable
  local dungeonCurrentText = AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate() or ""
  dungeonTemplateEditBox:SetText(dungeonCurrentText)

  -- Reset Button (Dungeon) - on same line as label, aligned right
  local dungeonResetBtn = CreateFrame("Button", "AutoLFM_DungeonTemplateResetBtn", panel, "UIPanelButtonTemplate")
  dungeonResetBtn:SetWidth(50)
  dungeonResetBtn:SetHeight(18)
  dungeonResetBtn:SetPoint("LEFT", dungeonLabel, "RIGHT", 95 , 0)
  dungeonResetBtn:SetText("Reset")
  dungeonResetBtn:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Messages.ResetDungeonTemplate")
    dungeonCurrentText = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon
    dungeonTemplateEditBox:SetText(dungeonCurrentText)
    AutoLFM.Core.Utils.PrintInfo("Dungeon template reset to default")
  end)

  -- Save Button (Dungeon) - on same line as label, left of Reset
  local dungeonSaveBtn = CreateFrame("Button", "AutoLFM_DungeonTemplateSaveBtn", panel, "UIPanelButtonTemplate")
  dungeonSaveBtn:SetWidth(50)
  dungeonSaveBtn:SetHeight(18)
  dungeonSaveBtn:SetPoint("RIGHT", dungeonResetBtn, "LEFT", -3, 0)
  dungeonSaveBtn:SetText("Save")
  dungeonSaveBtn:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Messages.SetDungeonTemplate", dungeonCurrentText)
    AutoLFM.Core.Utils.PrintSuccess("Dungeon template saved!")
  end)

  -- Backdrop for EditBox
  dungeonTemplateEditBox:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  dungeonTemplateEditBox:SetBackdropColor(0, 0, 0, 0.5)
  dungeonTemplateEditBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  dungeonTemplateEditBox:SetTextInsets(6, 6, 0, 0)

  -- Enable editbox interaction
  dungeonTemplateEditBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  dungeonTemplateEditBox:SetScript("OnEnterPressed", function()
    this:ClearFocus()
  end)
  dungeonTemplateEditBox:SetScript("OnTextChanged", function()
    -- Update local variable
    dungeonCurrentText = this:GetText() or ""
  end)

  -- Tooltip with available variables
  dungeonTemplateEditBox:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Available Variables:", 1, 1, 1)
    for var, desc in pairs(AutoLFM.Core.Constants.MESSAGE_VARIABLES) do
      GameTooltip:AddDoubleLine(var, desc, 0.5, 1, 0.5, 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
  end)
  dungeonTemplateEditBox:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local raidIcon = panel:CreateTexture(nil, "ARTWORK")
  raidIcon:SetWidth(16)
  raidIcon:SetHeight(16)
  raidIcon:SetPoint("TOPLEFT", dungeonIcon, "BOTTOMLEFT", 0, -25)
  raidIcon:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\chat")

  local raidLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  raidLabel:SetPoint("LEFT", raidIcon, "RIGHT", 5, 0)
  raidLabel:SetText("Raids Template:")
  raidLabel:SetTextColor(1, 1, 1)

  -- Raid Template EditBox (create first)
  raidTemplateEditBox = CreateFrame("EditBox", "AutoLFM_RaidTemplateEditBox", panel)
  raidTemplateEditBox:SetWidth(285)
  raidTemplateEditBox:SetHeight(24)
  raidTemplateEditBox:SetPoint("TOPLEFT", raidIcon, "BOTTOMLEFT", 0, 0)
  raidTemplateEditBox:SetFontObject(GameFontNormalSmall)
  raidTemplateEditBox:SetAutoFocus(false)
  raidTemplateEditBox:SetMaxLetters(100)

  -- Store current text in a local variable
  local raidCurrentText = AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate() or ""
  raidTemplateEditBox:SetText(raidCurrentText)

  -- Reset Button (Raid)
  local raidResetBtn = CreateFrame("Button", "AutoLFM_RaidTemplateResetBtn", panel, "UIPanelButtonTemplate")
  raidResetBtn:SetWidth(50)
  raidResetBtn:SetHeight(18)
  raidResetBtn:SetPoint("TOP", dungeonResetBtn, "BOTTOM", 0, -22)
  raidResetBtn:SetText("Reset")
  raidResetBtn:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Messages.ResetRaidTemplate")
    raidCurrentText = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid
    raidTemplateEditBox:SetText(raidCurrentText)
    AutoLFM.Core.Utils.PrintInfo("Raid template reset to default")
  end)

  -- Save Button (Raid)
  local raidSaveBtn = CreateFrame("Button", "AutoLFM_RaidTemplateSaveBtn", panel, "UIPanelButtonTemplate")
  raidSaveBtn:SetWidth(50)
  raidSaveBtn:SetHeight(18)
  raidSaveBtn:SetPoint("RIGHT", raidResetBtn, "LEFT", -3, 0)
  raidSaveBtn:SetText("Save")
  raidSaveBtn:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Messages.SetRaidTemplate", raidCurrentText)
    AutoLFM.Core.Utils.PrintSuccess("Raid template saved!")
  end)

  -- Backdrop for EditBox
  raidTemplateEditBox:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  raidTemplateEditBox:SetBackdropColor(0, 0, 0, 0.5)
  raidTemplateEditBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  raidTemplateEditBox:SetTextInsets(6, 6, 0, 0)

  -- Enable editbox interaction
  raidTemplateEditBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  raidTemplateEditBox:SetScript("OnEnterPressed", function()
    this:ClearFocus()
  end)
  raidTemplateEditBox:SetScript("OnTextChanged", function()
    -- Update local variable
    raidCurrentText = this:GetText() or ""
  end)

  -- Tooltip with available variables
  raidTemplateEditBox:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Available Variables:", 1, 1, 1)
    for var, desc in pairs(AutoLFM.Core.Constants.MESSAGE_VARIABLES) do
      GameTooltip:AddDoubleLine(var, desc, 0.5, 1, 0.5, 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
  end)
  raidTemplateEditBox:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Register event listeners
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.CustomMessageChanged", function(message)
    if editBox then
      -- Update EditBox text without triggering onTextChanged
      local currentText = editBox:GetText()
      if currentText ~= message then
        editBox:SetText(message or "")
        editBox:ClearFocus()
      end
    end
  end, "Update custom message text in Broadcasts UI")

  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.IntervalChanged", function(interval)
    if slider and customValueText then
      slider:SetValue(interval)
      customValueText:SetText(math.floor(interval) .. " secs")
    end
  end, "Update interval slider in Broadcasts UI")

  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.ChannelToggled", function(channelName, isChecked)
    if channelsPanel and channelsPanel.UpdateCheckbox then
      channelsPanel.UpdateCheckbox(channelName, isChecked)
    end
  end, "Update channel checkbox in Broadcasts UI")

  AutoLFM.Core.Maestro.RegisterEventListener("Messages.TemplateChanged", function(templateType, template)
    if templateType == "dungeon" and dungeonTemplateEditBox then
      local currentText = dungeonTemplateEditBox:GetText()
      if currentText ~= template then
        dungeonTemplateEditBox:SetText(template or "")
        dungeonTemplateEditBox:ClearFocus()
      end
    elseif templateType == "raid" and raidTemplateEditBox then
      local currentText = raidTemplateEditBox:GetText()
      if currentText ~= template then
        raidTemplateEditBox:SetText(template or "")
        raidTemplateEditBox:ClearFocus()
      end
    end
  end, "Update template text in Broadcasts UI")

  return panel
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Broadcasts.UpdateChannels()
  if channelsPanel and channelsPanel.UpdateChannels then
    channelsPanel:UpdateChannels()
  end
end
