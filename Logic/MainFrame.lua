--=============================================================================
-- AutoLFM: MainFrame
--   Main frame controller
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.MainFrame = AutoLFM.Logic.MainFrame or {}

function AutoLFM.Logic.MainFrame.SelectBottomTab(tabIndex)
  if AutoLFM.Logic.Widgets.Tabs.SelectBottomTab then
    AutoLFM.Logic.Widgets.Tabs.SelectBottomTab(tabIndex)
  end
end

function AutoLFM.Logic.MainFrame.SelectLineTab(tabIndex)
  if AutoLFM.Logic.Widgets.Tabs.SelectLineTab then
    AutoLFM.Logic.Widgets.Tabs.SelectLineTab(tabIndex)
  end
end

-----------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------
function AutoLFM.Logic.MainFrame.OnLoad(frame)
  if not frame then return end

  if AutoLFM.Components and AutoLFM.Components.DarkUI and AutoLFM.Components.DarkUI.RegisterFrame then
    AutoLFM.Components.DarkUI.RegisterFrame(frame)
  end

  local function updatePreview()
    AutoLFM.Logic.MainFrame.UpdateMessagePreview()
  end

  local function updateClearAllButton()
    AutoLFM.Logic.MainFrame.UpdateClearAllButton()
  end

  local function updateAddPresetButton()
    AutoLFM.Logic.MainFrame.UpdateAddPresetButton()
  end

  local function updateMainButton()
    AutoLFM.Logic.MainFrame.UpdateMainButton()
  end

  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.SelectionChanged", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.AllDeselected", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.SelectionChanged", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.AllDeselected", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.SizeChanged", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Quests.SelectionChanged", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Roles.RoleToggled", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.CustomMessageChanged", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Messages.TemplateChanged", updatePreview, "Update preview text in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Group.Changed", updatePreview, "Update preview text in MainFrame")

  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.SelectionChanged", updateClearAllButton, "Update Clear All button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.AllDeselected", updateClearAllButton, "Update Clear All button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.SelectionChanged", updateClearAllButton, "Update Clear All button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.AllDeselected", updateClearAllButton, "Update Clear All button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Quests.SelectionChanged", updateClearAllButton, "Update Clear All button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Roles.RoleToggled", updateClearAllButton, "Update Clear All button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.CustomMessageChanged", updateClearAllButton, "Update Clear All button in MainFrame")

  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.SelectionChanged", updateAddPresetButton, "Update Add Preset button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.AllDeselected", updateAddPresetButton, "Update Add Preset button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.SelectionChanged", updateAddPresetButton, "Update Add Preset button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.AllDeselected", updateAddPresetButton, "Update Add Preset button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Quests.SelectionChanged", updateAddPresetButton, "Update Add Preset button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Roles.RoleToggled", updateAddPresetButton, "Update Add Preset button in MainFrame")
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.CustomMessageChanged", updateAddPresetButton, "Update Add Preset button in MainFrame")

  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.SelectionChanged", updateMainButton, "Update Start/Stop broadcast button")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.SelectionChanged", updateMainButton, "Update Start/Stop broadcast button")
  AutoLFM.Core.Maestro.RegisterEventListener("Quests.SelectionChanged", updateMainButton, "Update Start/Stop broadcast button")
  AutoLFM.Core.Maestro.RegisterEventListener("Roles.RoleToggled", updateMainButton, "Update Start/Stop broadcast button")
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.CustomMessageChanged", updateMainButton, "Update Start/Stop broadcast button")
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcaster.Started", updateMainButton, "Update Start/Stop broadcast button")
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcaster.Stopped", updateMainButton, "Update Start/Stop broadcast button")
end

local isFirstShow = true

function AutoLFM.Logic.MainFrame.OnShow(frame)
  if not frame then return end

  local wasFirstShow = isFirstShow
  if isFirstShow then
    isFirstShow = false
    AutoLFM.Logic.MainFrame.SelectBottomTab(1)
    if AutoLFM.Logic.Message.UpdatePreview then
      AutoLFM.Logic.Message.UpdatePreview()
    end
    AutoLFM.Logic.MainFrame.UpdateMessagePreview()
  end

  local currentTab = AutoLFM.Core.Maestro.currentTab
  if currentTab then
    if currentTab.bottomTab then
      local tabIndex = AutoLFM.Core.Constants.BOTTOM_TAB_MAP[currentTab.bottomTab]
      if tabIndex and AutoLFM.UI.Widgets.Tabs.UpdateBottomTabs then
        AutoLFM.UI.Widgets.Tabs.UpdateBottomTabs(tabIndex)
      end
    elseif currentTab.lineTab then
      local tabIndex = AutoLFM.Core.Constants.LINE_TAB_MAP[currentTab.lineTab]
      if tabIndex and AutoLFM.UI.Widgets.Tabs.UpdateLineTabs then
        AutoLFM.UI.Widgets.Tabs.UpdateLineTabs(tabIndex)
      end
    end
  end

  if not wasFirstShow and AutoLFM.Logic.Widgets.Tabs.ReloadCurrentTab then
    AutoLFM.Logic.Widgets.Tabs.ReloadCurrentTab()
  end
end

function AutoLFM.Logic.MainFrame.OnHide(frame)
  if not frame then return end
end

function AutoLFM.Logic.MainFrame.UpdateMessagePreview()
  local previewText = getglobal("AutoLFM_MainFrame_MessagePreview_Text")
  local previewButton = getglobal("AutoLFM_MainFrame_MessagePreview_Button")
  if not previewText then return end

  if AutoLFM.Logic.Message and AutoLFM.Logic.Message.UpdatePreview then
    AutoLFM.Logic.Message.UpdatePreview()
  end

  local message = AutoLFM.Logic.Message.GetPreviewMessage()

  if message == "" then
    previewText:SetText("")
    if previewButton then
      previewButton:Hide()
    end
  else
    local truncated, isTruncated = AutoLFM.Core.Utils.TruncateByWidth(
      message,
      AutoLFM.Core.Constants.MESSAGE_PREVIEW_TEXT_WIDTH,
      previewText,
      " |cFFFFFFFF[...]|r"
    )
    previewText:SetText("|cFFFFD100" .. truncated .. "|r")

    if previewButton then
      if isTruncated then
        previewButton:Show()
      else
        previewButton:Hide()
      end
    end
  end
end

function AutoLFM.Logic.MainFrame.ShowFullPreview()
  local message = AutoLFM.Logic.Message.GetPreviewMessage()
  if message and message ~= "" then
    AutoLFM.Core.Utils.Print("Preview: ")
    AutoLFM.Core.Utils.PrintInfo(message)
  end
end

function AutoLFM.Logic.MainFrame.HasAnythingToClear()
  return AutoLFM.Core.Maestro.HasAnySelection()
end

function AutoLFM.Logic.MainFrame.UpdateClearAllButton()
  local button = getglobal("AutoLFM_MainFrame_LineTab3")
  if not button then return end

  local icon = getglobal("AutoLFM_MainFrame_LineTab3_Icon")
  local highlight = getglobal("AutoLFM_MainFrame_LineTab3_Highlight")

  local hasContent = AutoLFM.Logic.MainFrame.HasAnythingToClear()

  if hasContent then
    button:Enable()
    if icon then
      icon:SetVertexColor(1, 1, 1, 1)
    end
    if highlight then
      highlight:Show()
    end
  else
    button:Disable()
    if icon then
      icon:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    end
    if highlight then
      highlight:Hide()
    end
  end
end

function AutoLFM.Logic.MainFrame.ClearAll()
  AutoLFM.Core.Maestro.DispatchCommand("Selection.ClearAll")
end

function AutoLFM.Logic.MainFrame.UpdateAddPresetButton()
  local button = getglobal("AutoLFM_MainFrame_LineTab2")
  if not button then return end

  local icon = getglobal("AutoLFM_MainFrame_LineTab2_Icon")
  local highlight = getglobal("AutoLFM_MainFrame_LineTab2_Highlight")

  local hasContent = AutoLFM.Logic.MainFrame.HasAnythingToClear()

  if hasContent then
    button:Enable()
    if icon then
      icon:SetVertexColor(1, 1, 1, 1)
    end
    if highlight then
      highlight:Show()
    end
  else
    button:Disable()
    if icon then
      icon:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    end
    if highlight then
      highlight:Hide()
    end
  end
end

function AutoLFM.Logic.MainFrame.Toggle()
  local frame = getglobal("AutoLFM_MainFrame")
  if not frame then return end

  if frame:IsVisible() then
    HideUIPanel(frame)
  else
    ShowUIPanel(frame)
  end
end

function AutoLFM.Logic.MainFrame.Show()
  local frame = getglobal("AutoLFM_MainFrame")
  if frame then
    ShowUIPanel(frame)
  end
end

function AutoLFM.Logic.MainFrame.Hide()
  local frame = getglobal("AutoLFM_MainFrame")
  if frame then
    HideUIPanel(frame)
  end
end

function AutoLFM.Logic.MainFrame.UpdateMainButton()
  local button = getglobal("AutoLFM_MainFrame_MainButton")
  if not button then return end

  local isActive = AutoLFM.Core.Broadcaster.IsActive()

  if isActive then
    button:SetText("Stop")
    button:Enable()
  else
    local canStart = AutoLFM.Core.Maestro.HasAnySelection()
    if canStart then
      button:SetText("Start")
      button:Enable()
    else
      button:SetText("Start")
      button:Disable()
    end
  end
end

function AutoLFM.Logic.MainFrame.OnMainButtonClick()
  AutoLFM.Core.Maestro.DispatchCommand("Broadcaster.Toggle")
end
