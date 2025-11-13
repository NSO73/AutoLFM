--=============================================================================
-- AutoLFM: Broadcaster
--   Core broadcasting system with validation and auto-stop on group full
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Broadcaster = AutoLFM.Core.Broadcaster or {}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local isActive = false
local lastBroadcastTime = 0
local messageCount = 0
local sessionStartTime = 0
local broadcastFrame = nil
local lastUpdateCheck = 0

-----------------------------------------------------------------------------
-- Validation Rules
-----------------------------------------------------------------------------
local function ValidateMessage()
  local message = AutoLFM.Logic.Message.GetPreviewMessage()
  if not message or message == "" then
    return false, "The LFM message is empty"
  end
  return true, nil
end

local function ValidateChannels()
  local isDryRun = AutoLFM.Logic.Content.Options.GetTestMode()
  if isDryRun then
    return true, nil
  end

  local selectedChannels = AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels()
  if not selectedChannels or not next(selectedChannels) then
    return false, "No channel selected"
  end
  return true, nil
end

local function ValidateContent()
  local hasSelection = AutoLFM.Core.Maestro.HasAnySelection()
  if not hasSelection then
    return false, "No dungeon/raid/quest selected"
  end
  return true, nil
end

local function ValidateGroupSize()
  local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
  local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
  local currentSize = AutoLFM.Logic.Group.GetCurrentSize()

  if table.getn(selectedRaids) > 0 then
    local raid = selectedRaids[1]
    local raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index) or raid.sizeMin or AutoLFM.Core.Constants.GROUP_SIZE_RAID
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

function AutoLFM.Core.Broadcaster.Validate()
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

-----------------------------------------------------------------------------
-- Channel Sending
-----------------------------------------------------------------------------
function AutoLFM.Core.Broadcaster.SendToChannels(message)
  if not message or message == "" then
    return false
  end

  local isDryRun = AutoLFM.Logic.Content.Options.GetTestMode()

  if isDryRun then
    AutoLFM.Core.Utils.Print("[DRY RUN] Broadcast message: ", "blue")
    AutoLFM.Core.Utils.PrintInfo(message)

    messageCount = messageCount + 1
    lastBroadcastTime = GetTime()

    -- Sync stats to Broadcasts module
    if AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
      AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
        startTime = sessionStartTime,
        lastBroadcastTime = lastBroadcastTime,
        messageCount = messageCount,
        isActive = isActive
      })
    end

    AutoLFM.Core.Maestro.EmitEvent("Broadcaster.MessageSent", messageCount)
    return true
  end

  local selectedChannels = AutoLFM.Logic.Content.Broadcasts.GetSelectedChannels()
  if not selectedChannels or not next(selectedChannels) then
    return false
  end

  local sentCount = 0

  for channelName, isSelected in pairs(selectedChannels) do
    if isSelected then
      local channelIndex = GetChannelName(channelName)
      if channelIndex and channelIndex > 0 then
        local success = pcall(SendChatMessage, message, "CHANNEL", nil, channelIndex)
        if success then
          sentCount = sentCount + 1
        end
      end
    end
  end

  if sentCount == 0 then
    return false
  end

  messageCount = messageCount + 1
  lastBroadcastTime = GetTime()

  -- Sync stats to Broadcasts module
  if AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
    AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
      startTime = sessionStartTime,
      lastBroadcastTime = lastBroadcastTime,
      messageCount = messageCount,
      isActive = isActive
    })
  end

  AutoLFM.Core.Maestro.EmitEvent("Broadcaster.MessageSent", messageCount)

  return true
end

-----------------------------------------------------------------------------
-- Start/Stop Operations
-----------------------------------------------------------------------------
function AutoLFM.Core.Broadcaster.Start()
  local isValid, errors = AutoLFM.Core.Broadcaster.Validate()

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
  if AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
    AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
      startTime = sessionStartTime,
      lastBroadcastTime = lastBroadcastTime,
      messageCount = messageCount,
      isActive = isActive
    })
  end

  local message = AutoLFM.Logic.Message.GetPreviewMessage()
  AutoLFM.Core.Broadcaster.SendToChannels(message)

  pcall(PlaySoundFile, AutoLFM.Core.Constants.SOUND_PATH .. AutoLFM.Core.Constants.SOUNDS.START)

  local isDryRun = AutoLFM.Logic.Content.Options.GetTestMode()
  if isDryRun then
    AutoLFM.Core.Utils.PrintSuccess("Broadcast started (DRY RUN MODE - no messages sent to channels)")
  else
    AutoLFM.Core.Utils.PrintSuccess("Broadcast started")
  end

  AutoLFM.Core.Maestro.EmitEvent("Broadcaster.Started")

  return true
end

function AutoLFM.Core.Broadcaster.Stop()
  if not isActive then
    return
  end

  isActive = false

  -- Sync stats to Broadcasts module
  if AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats then
    AutoLFM.Logic.Content.Broadcasts.SetBroadcastStats({
      startTime = sessionStartTime,
      lastBroadcastTime = lastBroadcastTime,
      messageCount = messageCount,
      isActive = isActive
    })
  end

  pcall(PlaySoundFile, AutoLFM.Core.Constants.SOUND_PATH .. AutoLFM.Core.Constants.SOUNDS.STOP)

  AutoLFM.Core.Utils.PrintWarning("Broadcast stopped")
  AutoLFM.Core.Maestro.EmitEvent("Broadcaster.Stopped")
end

function AutoLFM.Core.Broadcaster.Toggle()
  if isActive then
    AutoLFM.Core.Broadcaster.Stop()
  else
    AutoLFM.Core.Broadcaster.Start()
  end
end

-----------------------------------------------------------------------------
-- Group Full Handler
-----------------------------------------------------------------------------
function AutoLFM.Core.Broadcaster.HandleGroupFull()
  if isActive then
    AutoLFM.Core.Broadcaster.Stop()
  end

  pcall(PlaySoundFile, AutoLFM.Core.Constants.SOUND_PATH .. AutoLFM.Core.Constants.SOUNDS.FULL)

  AutoLFM.Core.Utils.PrintSuccess("Group is full! Broadcast stopped and selections cleared")

  AutoLFM.Core.Maestro.DispatchCommand("Selection.ClearAll")

  AutoLFM.Core.Maestro.EmitEvent("Broadcaster.GroupFull")
end

-----------------------------------------------------------------------------
-- State Getters
-----------------------------------------------------------------------------
function AutoLFM.Core.Broadcaster.IsActive()
  return isActive
end

function AutoLFM.Core.Broadcaster.GetStats()
  return {
    isActive = isActive,
    messageCount = messageCount,
    lastBroadcastTime = lastBroadcastTime,
    sessionStartTime = sessionStartTime
  }
end

-----------------------------------------------------------------------------
-- Broadcast Loop (OnUpdate)
-----------------------------------------------------------------------------
local function ShouldBroadcast(currentTime)
  if not isActive then
    return false
  end

  if not lastBroadcastTime or lastBroadcastTime <= 0 then
    return false
  end

  local interval = AutoLFM.Logic.Content.Broadcasts.GetInterval()
  if not interval then
    interval = AutoLFM.Core.Constants.INTERVAL_DEFAULT
  end

  local elapsed = currentTime - lastBroadcastTime
  return elapsed >= interval
end

local function OnBroadcastUpdate()
  local currentTime = GetTime()

  if currentTime - lastUpdateCheck < AutoLFM.Core.Constants.UPDATE_THROTTLE then
    return
  end
  lastUpdateCheck = currentTime

  -- Check if group is full (LF0M)
  local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
  local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
  local currentSize = AutoLFM.Logic.Group.GetCurrentSize()

  if table.getn(selectedDungeons) > 0 then
    if currentSize >= AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON then
      AutoLFM.Core.Broadcaster.HandleGroupFull()
      return
    end
  elseif table.getn(selectedRaids) > 0 then
    local raid = selectedRaids[1]
    local raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raid.index)
    if currentSize >= raidSize then
      AutoLFM.Core.Broadcaster.HandleGroupFull()
      return
    end
  end

  if ShouldBroadcast(currentTime) then
    local message = AutoLFM.Logic.Message.GetPreviewMessage()
    local success = AutoLFM.Core.Broadcaster.SendToChannels(message)

    if not success then
      AutoLFM.Core.Broadcaster.Stop()
    end
  end
end

function AutoLFM.Core.Broadcaster.Init()
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

-----------------------------------------------------------------------------
-- Command Registration
-----------------------------------------------------------------------------
function AutoLFM.Core.Broadcaster.RegisterCommands()
  AutoLFM.Core.Maestro.RegisterCommand("Broadcaster.Start", function()
    AutoLFM.Core.Broadcaster.Start()
  end)

  AutoLFM.Core.Maestro.RegisterCommand("Broadcaster.Stop", function()
    AutoLFM.Core.Broadcaster.Stop()
  end)

  AutoLFM.Core.Maestro.RegisterCommand("Broadcaster.Toggle", function()
    AutoLFM.Core.Broadcaster.Toggle()
  end)
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Broadcaster", function()
  AutoLFM.Core.Broadcaster.Init()
  AutoLFM.Core.Broadcaster.RegisterCommands()
end)
