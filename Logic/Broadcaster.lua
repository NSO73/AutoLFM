--=============================================================================
-- AutoLFM: Broadcaster
--   Automatic broadcasting system with validation and group full detection
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Broadcaster = AutoLFM.Logic.Broadcaster or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local isActive = false
local lastBroadcastTime = 0
local messageCount = 0
local sessionStartTime = 0
local broadcastFrame = nil
local lastUpdateCheck = 0

--=============================================================================
-- VALIDATION RULES
--=============================================================================

-----------------------------------------------------------------------------
-- Validate Message
--   @return boolean, string: Valid flag, error message
-----------------------------------------------------------------------------
local function ValidateMessage()
    local message = ""
    if AutoLFM.Logic.Message and AutoLFM.Logic.Message.GetPreviewMessage then
        message = AutoLFM.Logic.Message.GetPreviewMessage()
    end

    if not message or message == "" then
        return false, "The LFM message is empty"
    end

    return true, nil
end

-----------------------------------------------------------------------------
-- Validate Channels
--   @return boolean, string: Valid flag, error message
-----------------------------------------------------------------------------
local function ValidateChannels()
    local isDryRun = false
    if AutoLFM.Logic.Content.Options and AutoLFM.Logic.Content.Options.GetTestMode then
        isDryRun = AutoLFM.Logic.Content.Options.GetTestMode()
    end

    if isDryRun then
        return true, nil
    end

    local selectedChannels = {}
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels then
        selectedChannels = AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels()
    end

    if not selectedChannels or not next(selectedChannels) then
        return false, "No channel selected"
    end

    return true, nil
end

-----------------------------------------------------------------------------
-- Validate Content
--   @return boolean, string: Valid flag, error message
-----------------------------------------------------------------------------
local function ValidateContent()
    local hasSelection = false

    if AutoLFM.Core.Maestro and AutoLFM.Core.Maestro.HasAnySelection then
        hasSelection = AutoLFM.Core.Maestro.HasAnySelection()
    end

    if not hasSelection then
        return false, "No dungeon/raid/quest selected"
    end

    return true, nil
end

-----------------------------------------------------------------------------
-- Validate Group Size
--   @return boolean, string: Valid flag, error message
-----------------------------------------------------------------------------
local function ValidateGroupSize()
    local selectedRaids = {}
    local selectedDungeons = {}
    local currentSize = 0

    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
        selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
    end

    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
        selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
    end

    if AutoLFM.Logic.Group and AutoLFM.Logic.Group.GetCurrentSize then
        currentSize = AutoLFM.Logic.Group.GetCurrentSize()
    end

    if table.getn(selectedRaids) > 0 then
        local raid = selectedRaids[1]
        local raidSize = raid.sizeMin or AutoLFM.Core.Constants.GROUP_SIZE_RAID

        if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetRaidSize then
            raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index) or raidSize
        end

        if currentSize >= raidSize then
            return false, "Your raid group is already full (" .. currentSize .. "/" .. raidSize .. ")"
        end
    elseif table.getn(selectedDungeons) > 0 then
        if currentSize >= AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON then
            return false, "Your dungeon group is already full (" .. currentSize .. "/" .. AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON .. ")"
        end
    end

    return true, nil
end

-----------------------------------------------------------------------------
-- Validate All Rules
--   @return boolean, table: Valid flag, array of error messages
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.Validate()
    local validations = {
        ValidateMessage,
        ValidateChannels,
        ValidateContent,
        ValidateGroupSize
    }

    local errors = {}
    for i = 1, table.getn(validations) do
        local isValid, errorMsg = validations[i]()
        if not isValid and errorMsg then
            table.insert(errors, errorMsg)
        end
    end

    if table.getn(errors) > 0 then
        return false, errors
    end

    return true, nil
end

--=============================================================================
-- CHANNEL SENDING
--=============================================================================

-----------------------------------------------------------------------------
-- Send Message to Channels
--   @param message string: Message to send
--   @return boolean: Success flag
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.SendToChannels(message)
    if not message or message == "" then
        return false
    end

    local isDryRun = false
    if AutoLFM.Logic.Content.Options and AutoLFM.Logic.Content.Options.GetTestMode then
        isDryRun = AutoLFM.Logic.Content.Options.GetTestMode()
    end

    if isDryRun then
        AutoLFM.Core.Utils.Print("[DRY RUN] Broadcast message: ", "blue")
        AutoLFM.Core.Utils.PrintInfo(message)

        messageCount = messageCount + 1
        lastBroadcastTime = GetTime()

        -- Sync stats to Broadcasts module
        if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
            AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
                startTime = sessionStartTime,
                lastBroadcastTime = lastBroadcastTime,
                messageCount = messageCount,
                isActive = isActive
            })
        end

        AutoLFM.Core.Maestro.Emit("Broadcaster.MessageSent", messageCount)
        return true
    end

    local selectedChannels = {}
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels then
        selectedChannels = AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels()
    end

    if not selectedChannels or not next(selectedChannels) then
        return false
    end

    local sentCount = 0

    for i = 1, table.getn(selectedChannels) do
        local channelName = selectedChannels[i]
        local channelIndex = GetChannelName(channelName)
        if channelIndex and channelIndex > 0 then
            local success = pcall(SendChatMessage, message, "CHANNEL", nil, channelIndex)
            if success then
                sentCount = sentCount + 1
            end
        end
    end

    if sentCount == 0 then
        return false
    end

    messageCount = messageCount + 1
    lastBroadcastTime = GetTime()

    -- Sync stats to Broadcasts module
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
        AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
            startTime = sessionStartTime,
            lastBroadcastTime = lastBroadcastTime,
            messageCount = messageCount,
            isActive = isActive
        })
    end

    AutoLFM.Core.Maestro.Emit("Broadcaster.MessageSent", messageCount)

    return true
end

--=============================================================================
-- START/STOP OPERATIONS
--=============================================================================

-----------------------------------------------------------------------------
-- Start Broadcasting
--   @return boolean: Success flag
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.Start()
    local isValid, errors = AutoLFM.Logic.Broadcaster.Validate()

    if not isValid then
        AutoLFM.Core.Utils.PrintError("Broadcast cannot start:")
        for i = 1, table.getn(errors) do
            AutoLFM.Core.Utils.PrintError("  - " .. errors[i])
        end
        return false
    end

    isActive = true
    sessionStartTime = GetTime()
    lastBroadcastTime = GetTime()
    messageCount = 0

    -- Sync stats to Broadcasts module
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
        AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
            startTime = sessionStartTime,
            lastBroadcastTime = lastBroadcastTime,
            messageCount = messageCount,
            isActive = isActive
        })
    end

    local message = ""
    if AutoLFM.Logic.Message and AutoLFM.Logic.Message.GetPreviewMessage then
        message = AutoLFM.Logic.Message.GetPreviewMessage()
    end

    AutoLFM.Logic.Broadcaster.SendToChannels(message)

    pcall(PlaySoundFile, AutoLFM.Core.Constants.SOUND_PATH .. AutoLFM.Core.Constants.SOUNDS.START)

    local isDryRun = false
    if AutoLFM.Logic.Content.Options and AutoLFM.Logic.Content.Options.GetTestMode then
        isDryRun = AutoLFM.Logic.Content.Options.GetTestMode()
    end

    if isDryRun then
        AutoLFM.Core.Utils.PrintSuccess("Broadcast started (DRY RUN MODE - no messages sent to channels)")
    else
        AutoLFM.Core.Utils.PrintSuccess("Broadcast started")
    end

    AutoLFM.Core.Maestro.Emit("Broadcaster.Started")

    return true
end

-----------------------------------------------------------------------------
-- Stop Broadcasting
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.Stop()
    if not isActive then
        return
    end

    isActive = false

    -- Sync stats to Broadcasts module
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
        AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
            startTime = sessionStartTime,
            lastBroadcastTime = lastBroadcastTime,
            messageCount = messageCount,
            isActive = isActive
        })
    end

    pcall(PlaySoundFile, AutoLFM.Core.Constants.SOUND_PATH .. AutoLFM.Core.Constants.SOUNDS.STOP)

    AutoLFM.Core.Utils.PrintWarning("Broadcast stopped")
    AutoLFM.Core.Maestro.Emit("Broadcaster.Stopped")
end

-----------------------------------------------------------------------------
-- Toggle Broadcasting
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.Toggle()
    if isActive then
        AutoLFM.Logic.Broadcaster.Stop()
    else
        AutoLFM.Logic.Broadcaster.Start()
    end
end

--=============================================================================
-- GROUP FULL HANDLER
--=============================================================================

-----------------------------------------------------------------------------
-- Handle Group Full Event
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.HandleGroupFull()
    if isActive then
        AutoLFM.Logic.Broadcaster.Stop()
    end

    pcall(PlaySoundFile, AutoLFM.Core.Constants.SOUND_PATH .. AutoLFM.Core.Constants.SOUNDS.FULL)

    AutoLFM.Core.Utils.PrintSuccess("Group is full! Broadcast stopped and selections cleared")

    AutoLFM.Core.Maestro.Dispatch("Selection.ClearAll")

    AutoLFM.Core.Maestro.Emit("Broadcaster.GroupFull")
end

--=============================================================================
-- STATE GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Check if Broadcasting is Active
--   @return boolean: Active state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.IsActive()
    return isActive
end

-----------------------------------------------------------------------------
-- Get Broadcast Stats
--   @return table: Statistics
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.GetStats()
    return {
        isActive = isActive,
        messageCount = messageCount,
        lastBroadcastTime = lastBroadcastTime,
        sessionStartTime = sessionStartTime
    }
end

--=============================================================================
-- BROADCAST LOOP
--=============================================================================

-----------------------------------------------------------------------------
-- Check if Should Broadcast Now
--   @param currentTime number: Current time
--   @return boolean: Should broadcast flag
-----------------------------------------------------------------------------
local function ShouldBroadcast(currentTime)
    if not isActive then
        return false
    end

    if not lastBroadcastTime or lastBroadcastTime <= 0 then
        return false
    end

    local interval = AutoLFM.Core.Constants.INTERVAL_DEFAULT
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetInterval then
        interval = AutoLFM.Logic.Content.Broadcasts.GetInterval() or interval
    end

    local elapsed = currentTime - lastBroadcastTime
    return elapsed >= interval
end

-----------------------------------------------------------------------------
-- OnUpdate Handler for Broadcast Loop
-----------------------------------------------------------------------------
local function OnBroadcastUpdate()
    local currentTime = GetTime()

    if currentTime - lastUpdateCheck < AutoLFM.Core.Constants.UPDATE_THROTTLE then
        return
    end
    lastUpdateCheck = currentTime

    -- Check if group is full (LF0M)
    local selectedDungeons = {}
    local selectedRaids = {}
    local currentSize = 0

    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
        selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
    end

    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
        selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
    end

    if AutoLFM.Logic.Group and AutoLFM.Logic.Group.GetCurrentSize then
        currentSize = AutoLFM.Logic.Group.GetCurrentSize()
    end

    if table.getn(selectedDungeons) > 0 then
        if currentSize >= AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON then
            AutoLFM.Logic.Broadcaster.HandleGroupFull()
            return
        end
    elseif table.getn(selectedRaids) > 0 then
        local raid = selectedRaids[1]
        local raidSize = raid.sizeMin or AutoLFM.Core.Constants.GROUP_SIZE_RAID

        if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetRaidSize then
            raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index) or raidSize
        end

        if currentSize >= raidSize then
            AutoLFM.Logic.Broadcaster.HandleGroupFull()
            return
        end
    end

    if ShouldBroadcast(currentTime) then
        local message = ""
        if AutoLFM.Logic.Message and AutoLFM.Logic.Message.GetPreviewMessage then
            message = AutoLFM.Logic.Message.GetPreviewMessage()
        end

        local success = AutoLFM.Logic.Broadcaster.SendToChannels(message)

        if not success then
            AutoLFM.Logic.Broadcaster.Stop()
        end
    end
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Initialize Broadcaster
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.Init()
    if broadcastFrame then
        broadcastFrame:SetScript("OnUpdate", nil)
        broadcastFrame = nil
    end

    broadcastFrame = CreateFrame("Frame")
    lastUpdateCheck = 0

    broadcastFrame:SetScript("OnUpdate", function()
        local success, err = pcall(OnBroadcastUpdate)
        if not success then
            AutoLFM.Core.Utils.PrintError("Broadcast loop error: " .. tostring(err))
        end
    end)
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Broadcaster.RegisterCommands()
    -- Start broadcast command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Broadcaster.Start",
        description = "Starts the automatic broadcast system",
        handler = function()
            AutoLFM.Logic.Broadcaster.Start()
        end
    })

    -- Stop broadcast command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Broadcaster.Stop",
        description = "Stops the automatic broadcast system",
        handler = function()
            AutoLFM.Logic.Broadcaster.Stop()
        end
    })

    -- Toggle broadcast command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Broadcaster.Toggle",
        description = "Toggles the automatic broadcast system on/off",
        handler = function()
            AutoLFM.Logic.Broadcaster.Toggle()
        end
    })
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("broadcaster.init", function()
    AutoLFM.Logic.Broadcaster.Init()
    AutoLFM.Logic.Broadcaster.RegisterCommands()
end, {
    key = "Broadcaster.Init",
    description = "Initialize automatic broadcasting with validation and group full detection"
})
