--=============================================================================
-- AutoLFM: Stats Widget Logic
--   Manages automatic statistics updates via OnUpdate
--   Calculates formatted stats from raw State data
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Widgets = AutoLFM.Logic.Widgets or {}
AutoLFM.Logic.Widgets.Stats = AutoLFM.Logic.Widgets.Stats or {}

-----------------------------------------------------------------------------
-- Calculate formatted stats from raw State variables
-----------------------------------------------------------------------------
local function CalculateStats()
  local stats = {
    duration = "00:00",
    messageCount = 0,
    timeUntilNext = "--"
  }

  -- Get raw variables from Broadcasts module
  local broadcastStats = AutoLFM.Logic.Content.Broadcasts.GetBroadcastStats()
  local startTime = broadcastStats.startTime
  local lastTime = broadcastStats.lastBroadcastTime
  local messageCount = broadcastStats.messageCount or 0
  local interval = AutoLFM.Logic.Content.Broadcasts.GetInterval() or 60

  -- Calculate and format duration (MM:SS)
  if startTime then
    local durationSeconds = GetTime() - startTime
    local minutes = math.floor(durationSeconds / 60)
    local seconds = math.floor(durationSeconds - (minutes * 60))
    stats.duration = string.format("%02d:%02d", minutes, seconds)
  end

  stats.messageCount = messageCount

  -- Calculate and format time until next (MM:SS or --)
  if lastTime and interval then
    local elapsed = GetTime() - lastTime
    local remaining = interval - elapsed

    if remaining > 0 then
      local minutes = math.floor(remaining / 60)
      local seconds = math.floor(remaining - (minutes * 60))
      stats.timeUntilNext = string.format("%02d:%02d", minutes, seconds)
    else
      stats.timeUntilNext = "00:00"
    end
  end

  return stats
end

-----------------------------------------------------------------------------
-- Attach update logic to a stats panel
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.Stats.AttachUpdateLogic(panel)
  if not panel then return end

  -- Throttle updates to once per second instead of every frame
  local timeSinceLastUpdate = 0
  local updateInterval = 1.0  -- seconds

  -- Set up OnUpdate script to periodically calculate and update stats
  panel:SetScript("OnUpdate", function()
    timeSinceLastUpdate = timeSinceLastUpdate + arg1

    if timeSinceLastUpdate >= updateInterval then
      timeSinceLastUpdate = 0
      local statsData = CalculateStats()
      if statsData and panel.UpdateStats then
        panel:UpdateStats(statsData)
      end
    end
  end)
end
