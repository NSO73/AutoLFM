--=============================================================================
-- AutoLFM: AutoInvite Content
--   AutoInvite panel UI
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.AutoInvite = AutoLFM.UI.Content.AutoInvite or {}

-----------------------------------------------------------------------------
-- Panel creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.AutoInvite.Create(parent)
  if not parent then return nil end

  -- Set parent height to fit content without scrolling
  parent:SetHeight(AutoLFM.Core.Constants.CONTENT_DEFAULT_HEIGHT)

  local panel = CreateFrame("Frame", "AutoLFM_Panel_AutoInvite", parent)
  panel:SetAllPoints()

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -10)
  title:SetText("AUTO INVITE")

  -- Placeholder for future auto-invite features
  local text = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("CENTER", 0, 0)
  text:SetText("Auto-invite features will be implemented here")
  text:SetTextColor(0.5, 0.5, 0.5)

  return panel
end
