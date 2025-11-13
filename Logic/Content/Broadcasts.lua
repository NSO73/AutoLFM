--=============================================================================
-- AutoLFM: Broadcasts
--   Broadcasts configuration and channel management
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content.Broadcasts = AutoLFM.Logic.Content.Broadcasts or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local customBroadcastMessage = ""
local broadcastInterval = 60
local selectedChannels = {
    LookingForGroup = false,
    World = false,
    Hardcore = false,
    testketa = false,
    testketata = false
}
local broadcastStats = {
    startTime = nil,
    lastBroadcastTime = nil,
    messageCount = 0,
    isActive = false
}
local messageTemplates = {
    dungeon = "",
    raid = ""
}

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Initialize Broadcasts (Load from Persistent on Startup)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.Init()
    -- Initialize default templates from constants
    if AutoLFM.Core.Constants and AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES then
        messageTemplates.dungeon = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon
        messageTemplates.raid = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid
    end

    -- Load broadcast interval
    local interval = AutoLFM.Core.Persistent.Get("broadcastInterval")
    if interval then
        broadcastInterval = interval
    end

    -- Load selected channels
    local channels = AutoLFM.Core.Persistent.Get("selectedChannels")
    if channels then
        selectedChannels = AutoLFM.Core.Persistent.DeepCopy(channels)
    end

    -- Load message templates (override defaults if saved)
    local dungeonTemplate = AutoLFM.Core.Persistent.GetMessageTemplateDungeon()
    if dungeonTemplate then
        messageTemplates.dungeon = dungeonTemplate
    end

    local raidTemplate = AutoLFM.Core.Persistent.GetMessageTemplateRaid()
    if raidTemplate then
        messageTemplates.raid = raidTemplate
    end
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.RegisterCommands()
    -- Set custom message command
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "Broadcasts.SetCustomMessage",
        name = "Set Custom Message",
        description = "Sets the custom broadcast message",
        handler = function(message)
            customBroadcastMessage = message or ""
            AutoLFM.Core.Maestro.Emit("Broadcasts.CustomMessageChanged", message)
        end
    })

    -- Set interval command (write-through to Persistent)
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "Broadcasts.SetInterval",
        name = "Set Broadcast Interval",
        description = "Sets the broadcast interval in seconds",
        handler = function(interval)
            if not interval then return end

            broadcastInterval = interval
            AutoLFM.Core.Persistent.Set("broadcastInterval", interval)
            AutoLFM.Core.Maestro.Emit("Broadcasts.IntervalChanged", interval)
        end
    })

    -- Toggle channel command (write-through to Persistent)
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "broadcasts.toggle_channel",
        name = "Toggle Broadcast Channel",
        description = "Toggles a broadcast channel on or off",
        handler = function(channelName, isChecked)
            if not channelName then return end

            -- Auto-join for LookingForGroup and World if not already joined
            if isChecked and (channelName == "LookingForGroup" or channelName == "World") then
                local channelIndex = GetChannelName(channelName)
                if not channelIndex or channelIndex == 0 then
                    JoinChannelByName(channelName)
                    AutoLFM.Core.Utils.PrintInfo("Auto-joined channel: " .. channelName)
                end
            end

            selectedChannels[channelName] = isChecked
            AutoLFM.Core.Persistent.Set("selectedChannels", selectedChannels)
            AutoLFM.Core.Maestro.Emit("Broadcasts.ChannelToggled", channelName, isChecked)
        end
    })
end

--=============================================================================
-- EVENT LISTENERS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Event Listeners
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.RegisterEventListeners()
    -- Listen to Broadcaster.MessageSent to update statistics immediately
    AutoLFM.Core.Maestro.On("Broadcaster.MessageSent", function(messageCount)
        -- Stats are already synced via SetBroadcastStats in Broadcaster
        -- This listener is for potential UI feedback or additional logic
        if AutoLFM.Debug and AutoLFM.Debug.DebugWindow then
            AutoLFM.Debug.DebugWindow.LogInfo("Message sent - Total: " .. tostring(messageCount))
        end
    end, {
        name = "Log Broadcast Statistics",
        description = "Logs broadcast statistics when message is sent"
    })

    -- Listen to Broadcaster.GroupFull for UI feedback
    AutoLFM.Core.Maestro.On("Broadcaster.GroupFull", function()
        -- Broadcaster already stopped and cleared selections
        -- This listener is for potential UI feedback or additional logic
        if AutoLFM.Debug and AutoLFM.Debug.DebugWindow then
            AutoLFM.Debug.DebugWindow.LogInfo("Group is full - Broadcast stopped and selections cleared")
        end
    end, {
        name = "Log Group Full",
        description = "Logs when group is full and broadcast stops"
    })
end

--=============================================================================
-- PUBLIC GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Check if Channel is Selected
--   @param channelName string: Channel name
--   @return boolean: Selection state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.IsChannelSelected(channelName)
    if not channelName then return false end
    return selectedChannels[channelName] and true or false
end

-----------------------------------------------------------------------------
-- Get Selected Channels
--   @return table: Array of selected channel names
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels()
    local selected = {}
    for channel, isSelected in pairs(selectedChannels) do
        if isSelected then
            table.insert(selected, channel)
        end
    end
    return selected
end

-----------------------------------------------------------------------------
-- Get Custom Message
--   @return string: Custom broadcast message
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.GetCustomMessage()
    return customBroadcastMessage
end

-----------------------------------------------------------------------------
-- Get Interval
--   @return number: Broadcast interval in seconds
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.GetInterval()
    return broadcastInterval
end

-----------------------------------------------------------------------------
-- Get Broadcast Stats
--   @return table: Broadcast statistics
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.GetBroadcastStats()
    return broadcastStats
end

-----------------------------------------------------------------------------
-- Get Dungeon Template
--   @return string: Dungeon message template
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate()
    return messageTemplates.dungeon
end

-----------------------------------------------------------------------------
-- Get Raid Template
--   @return string: Raid message template
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate()
    return messageTemplates.raid
end

--=============================================================================
-- PUBLIC SETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Set Dungeon Template
--   @param template string: Dungeon message template
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(template)
    if not template then return end
    messageTemplates.dungeon = template
end

-----------------------------------------------------------------------------
-- Set Raid Template
--   @param template string: Raid message template
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(template)
    if not template then return end
    messageTemplates.raid = template
end

-----------------------------------------------------------------------------
-- Set Broadcast Stats
--   @param stats table: Broadcast statistics
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats(stats)
    if not stats then return end
    broadcastStats = stats
end

--=============================================================================
-- CONTENT MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Load Broadcasts Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.Load()
    local content = getglobal("AutoLFM_MainFrame_Content")
    if not content then return end

    if AutoLFM.UI.Content and AutoLFM.UI.Content.Broadcasts and AutoLFM.UI.Content.Broadcasts.Create then
        AutoLFM.UI.Content.Broadcasts.Create(content)
    end

    AutoLFM.Logic.Content.Broadcasts.RestoreState()
end

-----------------------------------------------------------------------------
-- Unload Broadcasts Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.Unload()
    -- State is automatically saved by UI callbacks
end

-----------------------------------------------------------------------------
-- Restore State
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.RestoreState()
    -- State is automatically restored by UI creation
end

--=============================================================================
-- UI HANDLERS
--=============================================================================

-- Create UI namespace for XML callbacks
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Broadcasts = AutoLFM.UI.Content.Broadcasts or {}

local BroadcastsUI = AutoLFM.UI.Content.Broadcasts
local uiFrame = nil

-----------------------------------------------------------------------------
-- UI Lifecycle
-----------------------------------------------------------------------------
function BroadcastsUI.OnLoad(self)
    uiFrame = self
end

function BroadcastsUI.OnShow(self)
    BroadcastsUI.Refresh()
end

-----------------------------------------------------------------------------
-- UI Event Handlers
-----------------------------------------------------------------------------
function BroadcastsUI.OnChannelToggle(channelName, isEnabled)
    AutoLFM.Core.Maestro.Dispatch("Broadcasts.ChannelToggle", channelName, isEnabled)
end

function BroadcastsUI.OnIntervalChanged(value)
    AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetInterval", math.floor(value))
end

function BroadcastsUI.OnTemplateChanged(text)
    AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetCustomMessage", text)
end

-----------------------------------------------------------------------------
-- UI Refresh
-----------------------------------------------------------------------------
function BroadcastsUI.Refresh()
    if not uiFrame then return end

    -- TODO: Update UI with current broadcast settings
    -- This will be implemented when UI widgets are ready
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("broadcasts.init", function()
    AutoLFM.Logic.Content.Broadcasts.Init()
    AutoLFM.Logic.Content.Broadcasts.RegisterCommands()
    AutoLFM.Logic.Content.Broadcasts.RegisterEventListeners()
end, {
    name = "Broadcasts Initialization",
    description = "Initialize broadcast configuration and channel management"
})
