--=============================================================================
-- AutoLFM: Event Definitions
--   Pre-register all events with descriptions for better debugging
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Events = AutoLFM.Core.Events or {}

-----------------------------------------------------------------------------
-- Register All Events
--   Called during initialization to register events with descriptions
-----------------------------------------------------------------------------
function AutoLFM.Core.Events.RegisterAll()
    if not AutoLFM.Core.Maestro then return end

    local events = {
        -- Dungeon Events
        {
            key = "Dungeons.SelectionChanged",
            description = "Fired when a dungeon is selected or deselected"
        },
        {
            key = "Dungeons.FilterChanged",
            description = "Fired when dungeon color filter settings change"
        },
        {
            key = "Dungeons.AllDeselected",
            description = "Fired when all dungeons are deselected at once"
        },
        {
            key = "Dungeons.StateChanged",
            description = "Fired when dungeon UI state changes"
        },

        -- Raid Events
        {
            key = "Raids.SelectionChanged",
            description = "Fired when a raid is selected or deselected"
        },
        {
            key = "Raids.SizeChanged",
            description = "Fired when raid size selection changes"
        },
        {
            key = "Raids.AllDeselected",
            description = "Fired when all raids are deselected at once"
        },
        {
            key = "Raid.StateChanged",
            description = "Fired when raid UI state changes"
        },

        -- Quest Events
        {
            key = "Quests.SelectionChanged",
            description = "Fired when a quest is selected or deselected"
        },
        {
            key = "Quest.StateChanged",
            description = "Fired when quest UI state changes"
        },
        {
            key = "QuestLog.Updated",
            description = "Fired when quest log data is refreshed"
        },

        -- Role Events
        {
            key = "Roles.RoleToggled",
            description = "Fired when a role (tank/heal/dps) is toggled"
        },
        {
            key = "Roles.Toggled",
            description = "Fired when a role selection changes (with role and state)"
        },

        -- Broadcast Events
        {
            key = "Broadcasts.CustomMessageChanged",
            description = "Fired when custom broadcast message is updated"
        },
        {
            key = "Broadcasts.IntervalChanged",
            description = "Fired when broadcast interval is changed"
        },
        {
            key = "Broadcasts.ChannelToggled",
            description = "Fired when a broadcast channel is enabled or disabled"
        },

        -- Broadcaster Events
        {
            key = "Broadcaster.MessageSent",
            description = "Fired when a broadcast message is sent to channels"
        },
        {
            key = "Broadcaster.GroupFull",
            description = "Fired when group reaches full capacity (LF0M)"
        },
        {
            key = "Broadcaster.Started",
            description = "Fired when automatic broadcasting starts"
        },
        {
            key = "Broadcaster.Stopped",
            description = "Fired when automatic broadcasting stops"
        },
        {
            key = "Broadcaster.StateChanged",
            description = "Fired when broadcaster state changes (started/stopped)"
        },

        -- Message Events
        {
            key = "Messages.TemplateChanged",
            description = "Fired when message template for dungeons or raids changes"
        },
        {
            key = "Messages.PreviewUpdated",
            description = "Fired when message preview needs to be refreshed"
        },

        -- Preset Events
        {
            key = "Presets.ViewModeChanged",
            description = "Fired when preset view mode changes (normal/condensed)"
        },
        {
            key = "Preset.Changed",
            description = "Fired when preset UI state changes"
        },
        {
            key = "Preset.Loaded",
            description = "Fired when a preset is loaded"
        },
        {
            key = "Preset.Deleted",
            description = "Fired when a preset is deleted"
        },

        -- Options Events
        {
            key = "Options.MinimapVisibilityChanged",
            description = "Fired when minimap button visibility changes"
        },
        {
            key = "Options.DarkModeChanged",
            description = "Fired when dark mode is enabled or disabled"
        },
        {
            key = "Options.TestModeChanged",
            description = "Fired when test mode is enabled or disabled"
        },
        {
            key = "Options.DebugModeChanged",
            description = "Fired when debug mode is enabled or disabled"
        },
        {
            key = "Options.Changed",
            description = "Fired when options UI state changes"
        },

        -- Selection Events
        {
            key = "Selection.AllCleared",
            description = "Fired when all selections are cleared (dungeons, raids, quests, roles)"
        },

        -- Group Events
        {
            key = "Group.Changed",
            description = "Fired when group composition changes"
        },
        {
            key = "Group.Full",
            description = "Fired when group reaches capacity for selected content"
        }
    }

    -- Register all events with descriptions
    for i = 1, table.getn(events) do
        AutoLFM.Core.Maestro.RegisterEvent(events[i])
    end
end

-----------------------------------------------------------------------------
-- Initialize - Register on addon load
-----------------------------------------------------------------------------
if AutoLFM.Core and AutoLFM.Core.Maestro then
    AutoLFM.Core.Maestro.RegisterInit("events", function()
        AutoLFM.Core.Events.RegisterAll()
    end)
end
