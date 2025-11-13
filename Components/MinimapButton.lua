--=============================================================================
-- AutoLFM: Minimap Button
--   Simple minimap button using V3_Settings for position persistence
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Components = AutoLFM.Components or {}
AutoLFM.Components.MinimapButton = AutoLFM.Components.MinimapButton or {}

-----------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.OnLoad(frame)
  -- Load saved position
  local pos = AutoLFM.Core.Persistent.GetMinimapPos()
  if pos and pos.x and pos.y then
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
  end

  -- Load visibility state (default is hidden=false, meaning visible)
  -- XML starts with hidden="false", so we hide if user preference is hidden
  local isHidden = AutoLFM.Core.Persistent.GetMinimapHidden()
  if isHidden then
    frame:Hide()
  end
end

-----------------------------------------------------------------------------
-- Drag & Drop
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.OnDragStop(frame)
  local x, y = frame:GetCenter()
  if x and y then
    AutoLFM.Core.Persistent.SetMinimapPos(x, y)
  end
end

-----------------------------------------------------------------------------
-- Click Handler
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.OnClick(frame, button)
  if button == "LeftButton" and not IsControlKeyDown() then
    -- Toggle main window
    if AutoLFM_MainFrame:IsVisible() then
      HideUIPanel(AutoLFM_MainFrame)
    else
      ShowUIPanel(AutoLFM_MainFrame)
    end
  elseif button == "RightButton" and IsControlKeyDown() then
    -- Reset position
    frame:ClearAllPoints()
    frame:SetPoint("LEFT", Minimap, "LEFT", 16, -68)

    -- Clear saved position
    AutoLFM.Core.Persistent.SetMinimapPos(nil, nil)
  end
end

-----------------------------------------------------------------------------
-- Tooltip
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.OnEnter(frame)
  GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
  GameTooltip:SetText("Auto|cff0070DDL|r|cffffffffF|r|cffff0000M")
  GameTooltip:AddLine("Left-click to open main window.", 1, 1, 1)
  GameTooltip:AddLine("Hold control and drag to move.", 1, 1, 1)
  GameTooltip:AddLine("Hold control and right-click to reset position.", 1, 1, 1)
  GameTooltip:Show()
end

-----------------------------------------------------------------------------
-- Show/Hide Functions
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.Show()
  local frame = AutoLFM_MinimapButton
  if frame then
    frame:Show()
    AutoLFM.Core.Persistent.SetMinimapHidden(false)
  end
end

function AutoLFM.Components.MinimapButton.Hide()
  local frame = AutoLFM_MinimapButton
  if frame then
    frame:Hide()
    AutoLFM.Core.Persistent.SetMinimapHidden(true)
  end
end

function AutoLFM.Components.MinimapButton.Toggle()
  local frame = AutoLFM_MinimapButton
  if frame then
    if frame:IsVisible() then
      AutoLFM.Components.MinimapButton.Hide()
    else
      AutoLFM.Components.MinimapButton.Show()
    end
  end
end

function AutoLFM.Components.MinimapButton.IsHidden()
  return AutoLFM.Core.Persistent.GetMinimapHidden()
end

-----------------------------------------------------------------------------
-- Reset position to default
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.ResetPosition()
  local frame = AutoLFM_MinimapButton
  if frame then
    frame:ClearAllPoints()
    frame:SetPoint("LEFT", Minimap, "LEFT", 16, -68)
    AutoLFM.Core.Persistent.SetMinimapPos(nil, nil)
  end
end

-----------------------------------------------------------------------------
-- Register Commands
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.RegisterCommands()
  -- Reset minimap button position to default
  AutoLFM.Core.Maestro.RegisterCommand("Minimap.ResetPosition", function()
    AutoLFM.Components.MinimapButton.ResetPosition()
  end)
end

-----------------------------------------------------------------------------
-- Initialize minimap button (called after Persistent.Init)
-----------------------------------------------------------------------------
function AutoLFM.Components.MinimapButton.Init()
  local frame = getglobal("AutoLFM_MinimapButton")
  if frame then
    AutoLFM.Components.MinimapButton.OnLoad(frame)
  end

  -- Register commands
  AutoLFM.Components.MinimapButton.RegisterCommands()
end

-----------------------------------------------------------------------------
-- Auto-register initialization (will be called AFTER Persistent.Init)
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("MinimapButton", "Components.MinimapButton.Init")
