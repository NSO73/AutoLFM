--=============================================================================
-- AutoLFM: Group Test
--   Test utilities for simulating group size changes
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Debug = AutoLFM.Debug or {}
AutoLFM.Debug.GroupTest = AutoLFM.Debug.GroupTest or {}

--=============================================================================
-- Private State
--=============================================================================
local isTestMode = false
local testPartySize = 0
local testRaidSize = 0
local originalGetNumPartyMembers = nil
local originalGetNumRaidMembers = nil

--=============================================================================
-- Override Functions
--=============================================================================
local function OverrideGroupFunctions()
  if isTestMode then return end

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
  if not isTestMode then return end

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

--=============================================================================
-- Public API
--=============================================================================
function AutoLFM.Debug.GroupTest.SetGroupSize(size)
  if not size or size < 1 then
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintError("Group size must be at least 1")
    end
    return
  end

  if size > 40 then
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintError("Group size cannot exceed 40")
    end
    return
  end

  OverrideGroupFunctions()

  if size <= 5 then
    testPartySize = size - 1
    testRaidSize = 0
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintSuccess("Test mode: Party size set to " .. size .. "/5")
    end
  else
    testPartySize = 0
    testRaidSize = size
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintSuccess("Test mode: Raid size set to " .. size .. "/40")
    end
  end

  if AutoLFM.Logic then
    if AutoLFM.Logic.Group then
      if AutoLFM.Logic.Group.GetCurrentSize then
        local currentSize = AutoLFM.Logic.Group.GetCurrentSize()
        if AutoLFM.Core and AutoLFM.Core.Utils then
          AutoLFM.Core.Utils.PrintInfo("Current detected group size: " .. currentSize)
        end
      end
    end
  end

  if AutoLFM.Core and AutoLFM.Core.Maestro then
    AutoLFM.Core.Maestro.EmitEvent("Group.Changed", size)
  end

  if AutoLFM.Logic then
    if AutoLFM.Logic.Message then
      if AutoLFM.Logic.Message.UpdatePreview then
        AutoLFM.Logic.Message.UpdatePreview()
      end
    end
  end
end

function AutoLFM.Debug.GroupTest.Reset()
  RestoreGroupFunctions()
  if AutoLFM.Core and AutoLFM.Core.Utils then
    AutoLFM.Core.Utils.PrintSuccess("Test mode disabled - using real group data")

    if AutoLFM.Logic then
      if AutoLFM.Logic.Group then
        if AutoLFM.Logic.Group.GetCurrentSize then
          local currentSize = AutoLFM.Logic.Group.GetCurrentSize()
          AutoLFM.Core.Utils.PrintInfo("Real group size: " .. currentSize)
        end
      end
    end
  end

  if AutoLFM.Core and AutoLFM.Core.Maestro then
    AutoLFM.Core.Maestro.EmitEvent("Group.Changed", GetNumRaidMembers() > 0 and GetNumRaidMembers() or (GetNumPartyMembers() + 1))
  end

  if AutoLFM.Logic then
    if AutoLFM.Logic.Message then
      if AutoLFM.Logic.Message.UpdatePreview then
        AutoLFM.Logic.Message.UpdatePreview()
      end
    end
  end
end

function AutoLFM.Debug.GroupTest.IsActive()
  return isTestMode
end

function AutoLFM.Debug.GroupTest.GetTestSize()
  if not isTestMode then return nil end

  if testRaidSize > 0 then
    return testRaidSize
  end

  return testPartySize + 1
end

function AutoLFM.Debug.GroupTest.SimulateFull()
  if not AutoLFM.Logic then return end
  if not AutoLFM.Logic.Content then return end

  local selectedRaids = {}
  local selectedDungeons = {}

  if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
    selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
  end

  if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
    selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
  end

  if table.getn(selectedRaids) > 0 then
    local raid = selectedRaids[1]
    local raidSize = AutoLFM.Core.Constants.GROUP_SIZE_RAID or 40

    if AutoLFM.Logic.Content.Raids.GetRaidSize then
      raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index) or raid.sizeMin or raidSize
    end

    AutoLFM.Debug.GroupTest.SetGroupSize(raidSize)
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintInfo("Simulating full raid: " .. raidSize .. "/" .. raidSize)
    end
  elseif table.getn(selectedDungeons) > 0 then
    local dungeonSize = AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON or 5
    AutoLFM.Debug.GroupTest.SetGroupSize(dungeonSize)
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintInfo("Simulating full dungeon: 5/5")
    end
  else
    if AutoLFM.Core and AutoLFM.Core.Utils then
      AutoLFM.Core.Utils.PrintError("No dungeon or raid selected")
    end
  end
end
