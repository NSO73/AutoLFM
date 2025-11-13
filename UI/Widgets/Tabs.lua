--=============================================================================
-- AutoLFM: Tabs UI
--   Tab visual styling and content area management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Widgets = AutoLFM.UI.Widgets or {}
AutoLFM.UI.Widgets.Tabs = AutoLFM.UI.Widgets.Tabs or {}

-----------------------------------------------------------------------------
-- Clear content UI
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.Tabs.ClearContentUI()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  -- Reset scroll position to top
  local scrollFrame = content:GetParent()
  if scrollFrame and scrollFrame.SetVerticalScroll then
    scrollFrame:SetVerticalScroll(0)
  end

  -- Hide all children
  local children = {content:GetChildren()}
  for i = 1, table.getn(children) do
    children[i]:Hide()
  end

  -- Reset content height
  content:SetHeight(AutoLFM.Core.Constants.CONTENT_DEFAULT_HEIGHT)

  -- Force update of scroll range
  if scrollFrame and scrollFrame.UpdateScrollChildRect then
    scrollFrame:UpdateScrollChildRect()
  end
end

-----------------------------------------------------------------------------
-- Update tab visual state
-----------------------------------------------------------------------------
local function UpdateTabVisual(tabIndex, isActive)
  local tab = getglobal("AutoLFM_MainFrame_Tab" .. tabIndex)
  if not tab then return end

  local layers = {tab:GetRegions()}
  local bg = nil
  local text = nil
  local highlight = getglobal("AutoLFM_MainFrame_Tab" .. tabIndex .. "_Highlight")

  for _, region in ipairs(layers) do
    if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
      bg = region
    elseif region:GetObjectType() == "FontString" then
      text = region
    end
  end

  if isActive then
    if bg then bg:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "tabActive") end
    if text then text:SetTextColor(1, 1, 1) end
    if highlight then highlight:Hide() end
    -- Remove hover scripts when active
    tab:SetScript("OnEnter", nil)
    tab:SetScript("OnLeave", nil)
  else
    if bg then bg:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "tabInactive") end
    if text then text:SetTextColor(1, 0.82, 0) end
    -- Add hover scripts when inactive
    tab:SetScript("OnEnter", function()
      if highlight then highlight:Show() end
    end)
    tab:SetScript("OnLeave", function()
      if highlight then highlight:Hide() end
    end)
  end
end

-----------------------------------------------------------------------------
-- Update bottom tabs
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.Tabs.UpdateBottomTabs(activeTabIndex)
  -- Uncheck line tabs
  local lineTab1 = getglobal("AutoLFM_MainFrame_LineTab1")
  local lineTab5 = getglobal("AutoLFM_MainFrame_LineTab5")
  local lineTab4 = getglobal("AutoLFM_MainFrame_LineTab4")
  if lineTab1 then lineTab1:SetChecked(false) end
  if lineTab5 then lineTab5:SetChecked(false) end
  if lineTab4 then lineTab4:SetChecked(false) end

  -- Update all bottom tabs
  for i = 1, 4 do
    UpdateTabVisual(i, i == activeTabIndex)
  end
end

-----------------------------------------------------------------------------
-- Update line tabs
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.Tabs.UpdateLineTabs(activeTabIndex)
  -- Reset all bottom tabs to inactive
  for i = 1, 4 do
    UpdateTabVisual(i, false)
  end

  -- Update line tabs
  local lineTab1 = getglobal("AutoLFM_MainFrame_LineTab1")
  local lineTab5 = getglobal("AutoLFM_MainFrame_LineTab5")
  local lineTab4 = getglobal("AutoLFM_MainFrame_LineTab4")

  if lineTab1 then
    lineTab1:SetChecked(activeTabIndex == 1)
  end

  if lineTab5 then
    lineTab5:SetChecked(activeTabIndex == 5)
  end

  if lineTab4 then
    lineTab4:SetChecked(activeTabIndex == 4)
  end
end
