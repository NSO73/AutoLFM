--=============================================================================
-- AutoLFM: Broadcasts
--   Broadcasts tab logic and state management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Broadcasts = AutoLFM.Logic.Content.Broadcasts or {}

-----------------------------------------------------------------------------
-- Private State (owned by this module)
-----------------------------------------------------------------------------
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
  dungeon = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon,
  raid = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid
}

-----------------------------------------------------------------------------
-- Content management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.Load()
  local content = getglobal("AutoLFM_MainFrame_Content")
  if not content then return end

  AutoLFM.UI.Content.Broadcasts.Create(content)
  AutoLFM.Logic.Content.Broadcasts.RestoreState()
end

function AutoLFM.Logic.Content.Broadcasts.Unload()
  -- State is automatically saved by UI callbacks
end

-----------------------------------------------------------------------------
-- State management
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.RestoreState()
  -- State is automatically restored by UI creation
end

-----------------------------------------------------------------------------
-- Initialization (load from Persistent on startup)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.Init()
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

  -- Load message templates
  local dungeonTemplate = AutoLFM.Core.Persistent.GetMessageTemplateDungeon()
  if dungeonTemplate then
    messageTemplates.dungeon = dungeonTemplate
  end

  local raidTemplate = AutoLFM.Core.Persistent.GetMessageTemplateRaid()
  if raidTemplate then
    messageTemplates.raid = raidTemplate
  end
end

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.RegisterCommands()
  -- Set custom message command
  AutoLFM.Core.Maestro.RegisterCommand("Broadcasts.SetCustomMessage", function(message)
    customBroadcastMessage = message or ""
    AutoLFM.Core.Maestro.EmitEvent("Broadcasts.CustomMessageChanged", message)
  end)

  -- Set interval command (write-through to Persistent)
  AutoLFM.Core.Maestro.RegisterCommand("Broadcasts.SetInterval", function(interval)
    broadcastInterval = interval
    AutoLFM.Core.Persistent.Set("broadcastInterval", interval)
    AutoLFM.Core.Maestro.EmitEvent("Broadcasts.IntervalChanged", interval)
  end)

  -- Toggle channel command (write-through to Persistent)
  AutoLFM.Core.Maestro.RegisterCommand("Broadcasts.ToggleChannel", function(channelName, isChecked)
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
    AutoLFM.Core.Maestro.EmitEvent("Broadcasts.ChannelToggled", channelName, isChecked)
  end)
end

-----------------------------------------------------------------------------
-- Public Getters
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.IsChannelSelected(channelName)
  if not channelName then return false end
  return selectedChannels[channelName] and true or false
end

function AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels()
  local selected = {}
  for channel, isSelected in pairs(selectedChannels) do
    if isSelected then
      table.insert(selected, channel)
    end
  end
  return selected
end

function AutoLFM.Logic.Content.Broadcasts.GetCustomMessage()
  return customBroadcastMessage
end

function AutoLFM.Logic.Content.Broadcasts.GetInterval()
  return broadcastInterval
end

function AutoLFM.Logic.Content.Broadcasts.GetBroadcastStats()
  return broadcastStats
end

function AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate()
  return messageTemplates.dungeon
end

function AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate()
  return messageTemplates.raid
end

-----------------------------------------------------------------------------
-- Public Setters (for broadcaster logic)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(template)
  messageTemplates.dungeon = template
end

function AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(template)
  messageTemplates.raid = template
end
function AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats(stats)
  if stats then
    broadcastStats = stats
  end
end

-----------------------------------------------------------------------------
-- Register Event Listeners
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Broadcasts.RegisterEventListeners()
  -- Listen to Broadcaster.MessageSent to update statistics immediately
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcaster.MessageSent", function(messageCount)
    -- Stats are already synced via SetBroadcastStats in Broadcaster
    -- This listener is for potential UI feedback or additional logic
    if AutoLFM.Debug and AutoLFM.Debug.DebugWindow then
      AutoLFM.Debug.DebugWindow.LogInfo("Message sent - Total: " .. tostring(messageCount))
    end
  end, "Log broadcast statistics when message is sent")

  -- Listen to Broadcaster.GroupFull for UI feedback
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcaster.GroupFull", function()
    -- Broadcaster already stopped and cleared selections
    -- This listener is for potential UI feedback or additional logic
    if AutoLFM.Debug and AutoLFM.Debug.DebugWindow then
      AutoLFM.Debug.DebugWindow.LogInfo("Group is full - Broadcast stopped and selections cleared")
    end
  end, "Log when group is full and broadcast stops")
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Broadcasts", function()
  AutoLFM.Logic.Content.Broadcasts.Init()
  AutoLFM.Logic.Content.Broadcasts.RegisterCommands()
  AutoLFM.Logic.Content.Broadcasts.RegisterEventListeners()
end)