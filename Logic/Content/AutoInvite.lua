--=============================================================================
-- AutoLFM: AutoInvite
--   AutoInvite logic and state management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.AutoInvite = AutoLFM.Logic.Content.AutoInvite or {}

-----------------------------------------------------------------------------
-- Content management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.AutoInvite.Load()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  AutoLFM.UI.Content.AutoInvite.Create(content)
  AutoLFM.Logic.Content.AutoInvite.RestoreState()
end

function AutoLFM.Logic.Content.AutoInvite.Unload()
  -- State is automatically saved by UI callbacks
end

-----------------------------------------------------------------------------
-- State management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.AutoInvite.RestoreState()
  -- State restoration will be implemented here
end
