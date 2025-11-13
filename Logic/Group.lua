--=============================================================================
-- AutoLFM: Group
--   Group/Party/Raid information with WoW event handling
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Group = AutoLFM.Logic.Group or {}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local eventFrame = nil
local lastGroupSize = 0

-----------------------------------------------------------------------------
-- Get current group size (works for both party and raid)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Group.GetCurrentSize()
  local raidSize = GetNumRaidMembers()
  if raidSize > 0 then
    return raidSize
  end
  return GetNumPartyMembers() + 1
end

-----------------------------------------------------------------------------
-- Get group stats for dungeons (5-man content)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Group.GetDungeonStats()
  local current = AutoLFM.Logic.Group.GetCurrentSize()
  local target = AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON
  local missing = target - current
  if missing < 0 then missing = 0 end

  return {
    current = current,
    target = target,
    missing = missing
  }
end

-----------------------------------------------------------------------------
-- Get group stats for raids
-----------------------------------------------------------------------------
function AutoLFM.Logic.Group.GetRaidStats(raidSize)
  local current = AutoLFM.Logic.Group.GetCurrentSize()
  local target = raidSize or AutoLFM.Core.Constants.GROUP_SIZE_RAID
  local missing = target - current
  if missing < 0 then missing = 0 end

  return {
    current = current,
    target = target,
    missing = missing
  }
end

-----------------------------------------------------------------------------
-- Group Change Handler
-----------------------------------------------------------------------------
local function OnGroupRosterChange()
  local currentSize = AutoLFM.Logic.Group.GetCurrentSize()

  if currentSize ~= lastGroupSize then
    lastGroupSize = currentSize

    AutoLFM.Core.Maestro.EmitEvent("Group.Changed", currentSize)

    AutoLFM.Logic.Message.UpdatePreview()

    local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
    local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()

    if table.getn(selectedRaids) > 0 then
      local raid = selectedRaids[1]
      local raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index) or raid.sizeMin or AutoLFM.Core.Constants.GROUP_SIZE_RAID

      if currentSize >= raidSize then
        AutoLFM.Core.Maestro.EmitEvent("Group.Full", "raid", currentSize, raidSize)
        AutoLFM.Core.Broadcaster.HandleGroupFull()
      end
    elseif table.getn(selectedDungeons) > 0 then
      if currentSize >= AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON then
        AutoLFM.Core.Maestro.EmitEvent("Group.Full", "dungeon", currentSize, AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON)
        AutoLFM.Core.Broadcaster.HandleGroupFull()
      end
    end
  end
end

-----------------------------------------------------------------------------
-- Event Frame Setup
-----------------------------------------------------------------------------
function AutoLFM.Logic.Group.Init()
  if eventFrame then
    eventFrame:UnregisterAllEvents()
    eventFrame = nil
  end

  eventFrame = CreateFrame("Frame")
  lastGroupSize = AutoLFM.Logic.Group.GetCurrentSize()

  eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
  eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")

  eventFrame:SetScript("OnEvent", function()
    local success, err = pcall(OnGroupRosterChange)
    if not success then
      AutoLFM.Core.Utils.PrintError("Group event error: " .. tostring(err))
    end
  end)
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Group", "Logic.Group.Init")
