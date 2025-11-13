--=============================================================================
-- AutoLFM: Group
--   Group/Party/Raid information with WoW event handling
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Group = AutoLFM.Logic.Group or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local eventFrame = nil
local lastGroupSize = 0

--=============================================================================
-- GROUP SIZE DETECTION
--=============================================================================

-----------------------------------------------------------------------------
-- Get Current Group Size
--   Works for both party (1-5) and raid (1-40)
--   @return number: Current group size
-----------------------------------------------------------------------------
function AutoLFM.Logic.Group.GetCurrentSize()
    local raidSize = GetNumRaidMembers()
    if raidSize and raidSize > 0 then
        return raidSize
    end
    local partySize = GetNumPartyMembers()
    return (partySize or 0) + 1  -- +1 for player
end

-----------------------------------------------------------------------------
-- Get Dungeon Group Stats
--   @return table: { current, target, missing }
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
-- Get Raid Group Stats
--   @param raidSize number: Target raid size (optional, defaults to 40)
--   @return table: { current, target, missing }
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

--=============================================================================
-- GROUP CHANGE HANDLING
--=============================================================================

-----------------------------------------------------------------------------
-- Group Roster Change Handler
-----------------------------------------------------------------------------
local function OnGroupRosterChange()
    local currentSize = AutoLFM.Logic.Group.GetCurrentSize()

    if currentSize ~= lastGroupSize then
        lastGroupSize = currentSize

        -- Emit group changed event
        AutoLFM.Core.Maestro.Emit("Group.Changed", currentSize)

        -- Update message preview
        if AutoLFM.Logic and AutoLFM.Logic.Message and AutoLFM.Logic.Message.UpdatePreview then
            AutoLFM.Logic.Message.UpdatePreview()
        end

        -- Check if group is full
        if AutoLFM.Logic.Content and AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Dungeons then
            local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
            local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()

            if selectedRaids and table.getn(selectedRaids) > 0 then
                local raid = selectedRaids[1]
                local raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index) or raid.sizeMin or AutoLFM.Core.Constants.GROUP_SIZE_RAID

                if currentSize >= raidSize then
                    AutoLFM.Core.Maestro.Emit("Group.Full", "raid", currentSize, raidSize)
                    if AutoLFM.Logic.Broadcaster and AutoLFM.Logic.Broadcaster.HandleGroupFull then
                        AutoLFM.Logic.Broadcaster.HandleGroupFull()
                    end
                end
            elseif selectedDungeons and table.getn(selectedDungeons) > 0 then
                if currentSize >= AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON then
                    AutoLFM.Core.Maestro.Emit("Group.Full", "dungeon", currentSize, AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON)
                    if AutoLFM.Logic.Broadcaster and AutoLFM.Logic.Broadcaster.HandleGroupFull then
                        AutoLFM.Logic.Broadcaster.HandleGroupFull()
                    end
                end
            end
        end
    end
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Initialize Group Event Handling
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
AutoLFM.Core.Maestro.RegisterInit("group.init", function()
    AutoLFM.Logic.Group.Init()
end, {
    key = "Group.Init",
    description = "Initialize group size detection and event handling"
})
