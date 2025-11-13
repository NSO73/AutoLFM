--=============================================================================
-- AutoLFM: Channels Widget Logic
--   Detects available channels based on player context
--   Handles hardcore mode detection via spellbook
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Widgets = AutoLFM.Logic.Widgets or {}
AutoLFM.Logic.Widgets.Channels = AutoLFM.Logic.Widgets.Channels or {}

-----------------------------------------------------------------------------
-- Hardcore Mode Detection
-----------------------------------------------------------------------------
local isHardcore = false

local function DetectHardcoreCharacter()
  -- Detect hardcore by checking for the "Hardcore" spell in spellbook
  for tab = 1, GetNumSpellTabs() do
    local _, _, offset, numSpells = GetSpellTabInfo(tab)
    for i = 1, numSpells do
      local spellName = GetSpellName(offset + i, "spell")
      if spellName and string.find(string.lower(spellName), "hardcore") then
        return true
      end
    end
  end
  return false
end

local function IsHardcoreMode()
  return isHardcore
end

-----------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.Channels.Init()
  -- Detect hardcore status once on initialization
  isHardcore = DetectHardcoreCharacter()
end

-----------------------------------------------------------------------------
-- Available Channels Detection
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.Channels.GetAvailableChannels()
  local channels = {}

  -- LookingForGroup is always available
  table.insert(channels, "LookingForGroup")

  -- World is always available
  table.insert(channels, "World")

  -- Hardcore - Only available if character is hardcore
  if IsHardcoreMode() then
    table.insert(channels, "Hardcore")
  end

  return channels
end

-----------------------------------------------------------------------------
-- Check if a specific channel is available
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.Channels.IsChannelAvailable(channelName)
  if not channelName then return false end

  if channelName == "LookingForGroup" then
    return true
  end

  if channelName == "World" then
    return true
  end

  if channelName == "Hardcore" then
    return IsHardcoreMode()
  end

  -- Test channels are always available
  if channelName == "testketa" or channelName == "testketata" then
    return true
  end

  return false
end

-----------------------------------------------------------------------------
-- Get channel availability info (for UI display)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.Channels.GetChannelInfo(channelName)
  if not channelName then return nil end

  local info = {
    name = channelName,
    available = false,
    reason = ""
  }

  if channelName == "LookingForGroup" then
    info.available = true

  elseif channelName == "World" then
    info.available = true

  elseif channelName == "Hardcore" then
    info.available = IsHardcoreMode()
    if not info.available then
      info.reason = "Not a Hardcore character"
    end

  elseif channelName == "testketa" or channelName == "testketata" then
    info.available = true
  end

  return info
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Channels", "Logic.Widgets.Channels.Init")
