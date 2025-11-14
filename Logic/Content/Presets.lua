--=============================================================================
-- AutoLFM: Presets
--   Preset save/load/delete/reorder operations
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Presets = AutoLFM.Logic.Content.Presets or {}

--=============================================================================
-- PRESET STATE CAPTURE AND RESTORE
--=============================================================================

-----------------------------------------------------------------------------
-- Capture Current State for Preset
--   Captures all current selections and settings
--   @return table: Current state
-----------------------------------------------------------------------------
local function CaptureCurrentState()
    if not AutoLFM.Logic then return {} end

    local state = {}

    -- Capture selected dungeons
    state.dungeons = {}
    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
        local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
        for i = 1, table.getn(selectedDungeons) do
            local dungeon = selectedDungeons[i]
            if dungeon then
                table.insert(state.dungeons, dungeon.index)
            end
        end
    end

    -- Capture selected raids
    state.raids = {}
    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
        local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
        for i = 1, table.getn(selectedRaids) do
            local raid = selectedRaids[i]
            if raid then
                table.insert(state.raids, raid.index)
            end
        end
    end

    -- Capture raid sizes
    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetAllRaidSizes then
        local raidSizes = AutoLFM.Logic.Content.Raids.GetAllRaidSizes()
        if raidSizes then
            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.DeepCopy then
                state.raidSizes = AutoLFM.Core.Persistent.DeepCopy(raidSizes)
            else
                state.raidSizes = raidSizes
            end
        end
    end

    -- Capture selected quests
    state.quests = {}
    if AutoLFM.Logic.Content.Quests and AutoLFM.Logic.Content.Quests.GetSelected then
        local selectedQuests = AutoLFM.Logic.Content.Quests.GetSelected()
        for i = 1, table.getn(selectedQuests) do
            local quest = selectedQuests[i]
            if quest then
                table.insert(state.quests, quest.index)
            end
        end
    end

    -- Capture roles
    state.roles = {}
    if AutoLFM.Logic.Roles and AutoLFM.Logic.Roles.GetSelectedRoles then
        local selectedRoles = AutoLFM.Logic.Roles.GetSelectedRoles()
        if selectedRoles then
            if selectedRoles.tank then
                table.insert(state.roles, "tank")
            end
            if selectedRoles.heal then
                table.insert(state.roles, "heal")
            end
            if selectedRoles.dps then
                table.insert(state.roles, "dps")
            end
        end
    end

    -- Capture custom message
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetCustomMessage then
        state.customMessage = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""
    end

    -- Capture broadcast interval
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetInterval then
        state.interval = AutoLFM.Logic.Content.Broadcasts.GetInterval()
    end

    -- Capture selected channels
    state.channels = {}
    if AutoLFM.Logic.Content.Broadcasts then
        if AutoLFM.Logic.Content.Broadcasts.IsChannelSelected then
            if AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("LookingForGroup") then
                state.channels.LookingForGroup = true
            end
            if AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("World") then
                state.channels.World = true
            end
            if AutoLFM.Logic.Content.Broadcasts.IsChannelSelected("Hardcore") then
                state.channels.Hardcore = true
            end
        end
    end

    -- Capture message templates
    if AutoLFM.Logic.Content.Broadcasts then
        if AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate then
            state.messageTemplateDungeon = AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate()
        end
        if AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate then
            state.messageTemplateRaid = AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate()
        end
    end

    return state
end

-----------------------------------------------------------------------------
-- Load Preset State
--   Restores selections and settings from a preset
--   @param presetData table: Preset data to restore
-----------------------------------------------------------------------------
local function LoadPresetState(presetData)
    if not presetData then return end
    if not AutoLFM.Core or not AutoLFM.Core.Maestro then return end

    -- Clear all current selections
    if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.ClearAll then
        AutoLFM.Logic.Selection.ClearAll()
    end

    -- Load dungeons
    if presetData.dungeons then
        for i = 1, table.getn(presetData.dungeons) do
            local dungeonIndex = presetData.dungeons[i]
            AutoLFM.Core.Maestro.Dispatch("Dungeons.Select", dungeonIndex)
        end
    end

    -- Load raids
    if presetData.raids then
        for i = 1, table.getn(presetData.raids) do
            local raidIndex = presetData.raids[i]
            AutoLFM.Core.Maestro.Dispatch("Raids.Select", raidIndex)
        end
    end

    -- Load raid sizes
    if presetData.raidSizes then
        for raidIndex, size in pairs(presetData.raidSizes) do
            AutoLFM.Core.Maestro.Dispatch("Raids.SetSize", raidIndex, size)
        end
    end

    -- Load quests
    if presetData.quests then
        for i = 1, table.getn(presetData.quests) do
            local questIndex = presetData.quests[i]
            AutoLFM.Core.Maestro.Dispatch("Quests.Select", questIndex)
        end
    end

    -- Load roles
    if presetData.roles then
        for i = 1, table.getn(presetData.roles) do
            local role = presetData.roles[i]
            AutoLFM.Core.Maestro.Dispatch("Roles.Toggle", role)
        end
    end

    -- Load custom message
    if presetData.customMessage then
        AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetCustomMessage", presetData.customMessage)
    end

    -- Load broadcast interval
    if presetData.interval then
        AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetInterval", presetData.interval)
    end

    -- Load selected channels
    if presetData.channels then
        for channelName, isSelected in pairs(presetData.channels) do
            if isSelected then
                AutoLFM.Core.Maestro.Dispatch("Broadcasts.SelectChannel", channelName)
            else
                AutoLFM.Core.Maestro.Dispatch("Broadcasts.DeselectChannel", channelName)
            end
        end
    end

    -- Load message templates
    if presetData.messageTemplateDungeon then
        AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetDungeonTemplate", presetData.messageTemplateDungeon)
    end

    if presetData.messageTemplateRaid then
        AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetRaidTemplate", presetData.messageTemplateRaid)
    end
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Presets.RegisterCommands()
    -- Save Preset Command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Presets.Save",
        description = "Save current selections and settings as a preset",
        handler = function(presetName)
            if not presetName or presetName == "" then
                AutoLFM.Core.Utils.PrintError("Preset name cannot be empty")
                return
            end

            -- Check if preset already exists
            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.PresetExists then
                if AutoLFM.Core.Persistent.PresetExists(presetName) then
                    AutoLFM.Core.Utils.PrintError("Preset '" .. presetName .. "' already exists")
                    return
                end
            end

            local currentState = CaptureCurrentState()
            local success = false

            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.SavePreset then
                success = AutoLFM.Core.Persistent.SavePreset(presetName, currentState)
            end

            if success then
                AutoLFM.Core.Utils.PrintSuccess("Preset saved: " .. presetName)
                AutoLFM.Core.Maestro.Emit("Presets.Saved", presetName)

                -- Refresh UI if visible
                if AutoLFM.UI and AutoLFM.UI.Content and AutoLFM.UI.Content.Presets and AutoLFM.UI.Content.Presets.Refresh then
                    AutoLFM.UI.Content.Presets.Refresh()
                end
            else
                AutoLFM.Core.Utils.PrintError("Failed to save preset")
            end
        end
    })

    -- Load Preset Command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Presets.Load",
        description = "Load a preset and restore its selections and settings",
        handler = function(presetName)
            if not presetName or presetName == "" then
                AutoLFM.Core.Utils.PrintError("Preset name cannot be empty")
                return
            end

            local presets = {}
            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.GetPresets then
                presets = AutoLFM.Core.Persistent.GetPresets()
            end

            local presetData = presets[presetName]

            if not presetData then
                AutoLFM.Core.Utils.PrintError("Preset not found: " .. presetName)
                return
            end

            LoadPresetState(presetData)
            AutoLFM.Core.Utils.PrintSuccess("Preset loaded: " .. presetName)
            AutoLFM.Core.Maestro.Emit("Presets.Loaded", presetName)
        end
    })

    -- Delete Preset Command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Presets.Delete",
        description = "Delete a preset",
        handler = function(presetName)
            if not presetName or presetName == "" then
                AutoLFM.Core.Utils.PrintError("Preset name cannot be empty")
                return
            end

            local success = false

            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.DeletePreset then
                success = AutoLFM.Core.Persistent.DeletePreset(presetName)
            end

            if success then
                AutoLFM.Core.Utils.PrintSuccess("Preset deleted: " .. presetName)
                AutoLFM.Core.Maestro.Emit("Presets.Deleted", presetName)

                -- Refresh UI if visible
                if AutoLFM.UI and AutoLFM.UI.Content and AutoLFM.UI.Content.Presets and AutoLFM.UI.Content.Presets.Refresh then
                    AutoLFM.UI.Content.Presets.Refresh()
                end
            else
                AutoLFM.Core.Utils.PrintError("Failed to delete preset")
            end
        end
    })

    -- Move Preset Up Command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Presets.MoveUp",
        description = "Move a preset up in the list",
        handler = function(presetName)
            if not presetName or presetName == "" then return end

            local success = false

            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.MovePresetUp then
                success = AutoLFM.Core.Persistent.MovePresetUp(presetName)
            end

            if success then
                AutoLFM.Core.Maestro.Emit("Presets.MovedUp", presetName)

                -- Refresh UI if visible
                if AutoLFM.UI and AutoLFM.UI.Content and AutoLFM.UI.Content.Presets and AutoLFM.UI.Content.Presets.Refresh then
                    AutoLFM.UI.Content.Presets.Refresh()
                end
            end
        end
    })

    -- Move Preset Down Command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Presets.MoveDown",
        description = "Move a preset down in the list",
        handler = function(presetName)
            if not presetName or presetName == "" then return end

            local success = false

            if AutoLFM.Core.Persistent and AutoLFM.Core.Persistent.MovePresetDown then
                success = AutoLFM.Core.Persistent.MovePresetDown(presetName)
            end

            if success then
                AutoLFM.Core.Maestro.Emit("Presets.MovedDown", presetName)

                -- Refresh UI if visible
                if AutoLFM.UI and AutoLFM.UI.Content and AutoLFM.UI.Content.Presets and AutoLFM.UI.Content.Presets.Refresh then
                    AutoLFM.UI.Content.Presets.Refresh()
                end
            end
        end
    })
end

--=============================================================================
-- UI HANDLERS
--=============================================================================

-- Create UI namespace for XML callbacks
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Presets = AutoLFM.UI.Content.Presets or {}

local PresetsUI = AutoLFM.UI.Content.Presets
local presetRows = {}
local uiFrame = nil

-----------------------------------------------------------------------------
-- UI Lifecycle
-----------------------------------------------------------------------------
function PresetsUI.OnLoad(self)
    uiFrame = self
end

function PresetsUI.OnShow(self)
    PresetsUI.Refresh()
end

-----------------------------------------------------------------------------
-- UI Management
-----------------------------------------------------------------------------
function PresetsUI.Refresh()
    -- Clear existing rows
    PresetsUI.ClearRows()

    -- Request preset data and create rows
    AutoLFM.Core.Maestro.Dispatch("UI.Presets.Refresh", uiFrame, presetRows)
end

function PresetsUI.ClearRows()
    for _, row in ipairs(presetRows) do
        row:Hide()
        row:SetParent(nil)
    end
    presetRows = {}
end

-----------------------------------------------------------------------------
-- Event Handlers
-----------------------------------------------------------------------------
function PresetsUI.OnLoadPreset(row)
    local presetName = row.presetName
    if not presetName then return end

    -- Dispatch load preset command
    AutoLFM.Core.Maestro.Dispatch("Preset.Load", presetName)
end

function PresetsUI.OnDeletePreset(row)
    local presetName = row.presetName
    if not presetName then return end

    -- Show confirmation and dispatch delete
    StaticPopupDialogs["AUTOLFM_DELETE_PRESET"] = {
        text = "Delete preset '" .. presetName .. "'?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            AutoLFM.Core.Maestro.Dispatch("Preset.Delete", presetName)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("AUTOLFM_DELETE_PRESET")
end

function PresetsUI.OnPresetEnter(row)
    local presetName = row.presetName
    local presetData = row.presetData

    if not presetName then return end

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(presetName, 1, 1, 1)

    if presetData then
        -- Show preset details in tooltip
        GameTooltip:AddLine("Click Load to apply this preset", 0.8, 0.8, 0.8)
    end

    GameTooltip:Show()
end

-----------------------------------------------------------------------------
-- Save Preset Popup
-----------------------------------------------------------------------------
function PresetsUI.ShowSavePopup()
    local popup = getglobal("AutoLFM_SavePresetPopup")
    if popup then
        popup:Show()
    end
end

function PresetsUI.OnSaveConfirm()
    local popup = getglobal("AutoLFM_SavePresetPopup")
    if not popup then return end

    local input = getglobal(popup:GetName().."_NameInput")
    if not input then return end

    local presetName = input:GetText()
    if presetName and presetName ~= "" then
        -- Dispatch save preset command
        AutoLFM.Core.Maestro.Dispatch("Preset.Save", presetName)
        popup:Hide()
    end
end

function PresetsUI.OnSaveCancel()
    local popup = getglobal("AutoLFM_SavePresetPopup")
    if popup then
        popup:Hide()
    end
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function PresetsUI.GetPresetRows()
    return presetRows
end

function PresetsUI.ShowEmptyMessage()
    local emptyMsg = getglobal(uiFrame:GetName().."_EmptyMessage")
    if emptyMsg then
        emptyMsg:Show()
    end
end

function PresetsUI.HideEmptyMessage()
    local emptyMsg = getglobal(uiFrame:GetName().."_EmptyMessage")
    if emptyMsg then
        emptyMsg:Hide()
    end
end

-----------------------------------------------------------------------------
-- Event Listeners
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.On("Preset.Changed", function()
    if uiFrame and uiFrame:IsVisible() then
        PresetsUI.Refresh()
    end
end, {
    key = "PresetsUI.RefreshOnChange",
    description = "Refreshes presets UI when preset changes"
})

AutoLFM.Core.Maestro.On("Preset.Loaded", function()
    if uiFrame and uiFrame:IsVisible() then
        PresetsUI.Refresh()
    end
end, {
    key = "PresetsUI.RefreshOnLoad",
    description = "Refreshes presets UI when preset is loaded"
})

AutoLFM.Core.Maestro.On("Preset.Deleted", function()
    if uiFrame and uiFrame:IsVisible() then
        PresetsUI.Refresh()
    end
end, {
    key = "PresetsUI.RefreshOnDelete",
    description = "Refreshes presets UI when preset is deleted"
})

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("presets.init", function()
    AutoLFM.Logic.Content.Presets.RegisterCommands()
end, {
    name = "Presets Commands",
    description = "Register preset save/load/delete/reorder commands"
})
