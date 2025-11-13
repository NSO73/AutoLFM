--=============================================================================
-- AutoLFM: Group Test
--   Test utilities for simulating group size changes
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Debug = AutoLFM.Debug or {}
AutoLFM.Debug.GroupTest = AutoLFM.Debug.GroupTest or {}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local isTestMode = false
local testPartySize = 0
local testRaidSize = 0
local originalGetNumPartyMembers = nil
local originalGetNumRaidMembers = nil

-----------------------------------------------------------------------------
-- Override Functions
-----------------------------------------------------------------------------
local function OverrideGroupFunctions()
  if isTestMode then
    return
  end

  originalGetNumPartyMembers = GetNumPartyMembers
  originalGetNumRaidMembers = GetNumRaidMembers

  GetNumPartyMembers = function()
    if isTestMode then
      return testPartySize
    end
    return originalGetNumPartyMembers()
  end

  GetNumRaidMembers = function()
    if isTestMode then
      return testRaidSize
    end
    return originalGetNumRaidMembers()
  end

  isTestMode = true
end

local function RestoreGroupFunctions()
  if not isTestMode then
    return
  end

  if originalGetNumPartyMembers then
    GetNumPartyMembers = originalGetNumPartyMembers
    originalGetNumPartyMembers = nil
  end

  if originalGetNumRaidMembers then
    GetNumRaidMembers = originalGetNumRaidMembers
    originalGetNumRaidMembers = nil
  end

  testPartySize = 0
  testRaidSize = 0
  isTestMode = false
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function AutoLFM.Debug.GroupTest.SetGroupSize(size)
  if not size or size < 1 then
    AutoLFM.Core.Utils.PrintError("Group size must be at least 1")
    return
  end

  if size > 40 then
    AutoLFM.Core.Utils.PrintError("Group size cannot exceed 40")
    return
  end

  OverrideGroupFunctions()

  if size <= 5 then
    testPartySize = size - 1
    testRaidSize = 0
    AutoLFM.Core.Utils.PrintSuccess("Test mode: Party size set to " .. size .. "/5")
  else
    testPartySize = 0
    testRaidSize = size
    AutoLFM.Core.Utils.PrintSuccess("Test mode: Raid size set to " .. size .. "/40")
  end

  if AutoLFM.Logic.Group and AutoLFM.Logic.Group.GetCurrentSize then
    local currentSize = AutoLFM.Logic.Group.GetCurrentSize()
    AutoLFM.Core.Utils.PrintInfo("Current detected group size: " .. currentSize)
  end

  AutoLFM.Core.Maestro.EmitEvent("Group.Changed", size)

  if AutoLFM.Logic.Message and AutoLFM.Logic.Message.UpdatePreview then
    AutoLFM.Logic.Message.UpdatePreview()
  end
end

function AutoLFM.Debug.GroupTest.Reset()
  RestoreGroupFunctions()
  AutoLFM.Core.Utils.PrintSuccess("Test mode disabled - using real group data")

  if AutoLFM.Logic.Group and AutoLFM.Logic.Group.GetCurrentSize then
    local currentSize = AutoLFM.Logic.Group.GetCurrentSize()
    AutoLFM.Core.Utils.PrintInfo("Real group size: " .. currentSize)
  end

  AutoLFM.Core.Maestro.EmitEvent("Group.Changed", GetNumRaidMembers() > 0 and GetNumRaidMembers() or (GetNumPartyMembers() + 1))

  if AutoLFM.Logic.Message and AutoLFM.Logic.Message.UpdatePreview then
    AutoLFM.Logic.Message.UpdatePreview()
  end
end

function AutoLFM.Debug.GroupTest.IsActive()
  return isTestMode
end

function AutoLFM.Debug.GroupTest.GetTestSize()
  if not isTestMode then
    return nil
  end

  if testRaidSize > 0 then
    return testRaidSize
  end

  return testPartySize + 1
end

function AutoLFM.Debug.GroupTest.SimulateFull()
  local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
  local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()

  if table.getn(selectedRaids) > 0 then
    local raid = selectedRaids[1]
    local raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index) or raid.sizeMin or AutoLFM.Core.Constants.GROUP_SIZE_RAID
    AutoLFM.Debug.GroupTest.SetGroupSize(raidSize)
    AutoLFM.Core.Utils.PrintInfo("Simulating full raid: " .. raidSize .. "/" .. raidSize)
  elseif table.getn(selectedDungeons) > 0 then
    AutoLFM.Debug.GroupTest.SetGroupSize(AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON)
    AutoLFM.Core.Utils.PrintInfo("Simulating full dungeon: 5/5")
  else
    AutoLFM.Core.Utils.PrintError("No dungeon or raid selected")
  end
end
