--=============================================================================
-- AutoLFM: Persistent Storage
--   Centralized access to SavedVariables
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Persistent = AutoLFM.Core.Persistent or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local characterID = nil

-----------------------------------------------------------------------------
-- Get Character Data
-----------------------------------------------------------------------------
local function GetCharData()
    if not V3_Settings or not characterID then return nil end
    return V3_Settings[characterID]
end

-----------------------------------------------------------------------------
-- Ensure Character Data Exists
-----------------------------------------------------------------------------
local function EnsureCharData()
    if not V3_Settings then
        V3_Settings = {}
    end

    if not characterID then return nil end

    if not V3_Settings[characterID] then
        -- Detect initial dark mode from ShaguTweaks if available
        local initialDarkMode = AutoLFM.Core.Constants.DEFAULTS.DARK_MODE
        if initialDarkMode == nil then
            if ShaguTweaks and ShaguTweaks.DarkMode then
                initialDarkMode = true
            else
                initialDarkMode = false
            end
        end

        V3_Settings[characterID] = {
            broadcastInterval = AutoLFM.Core.Constants.DEFAULTS.BROADCAST_INTERVAL,
            darkMode = initialDarkMode,
            defaultPanel = AutoLFM.Core.Constants.DEFAULTS.DEFAULT_PANEL,
            dungeonFilters = AutoLFM.Core.Constants.DEFAULTS.DUNGEON_FILTERS,
            messageTemplateDungeon = AutoLFM.Core.Constants.DEFAULTS.MESSAGE_TEMPLATE_DUNGEON,
            messageTemplateRaid = AutoLFM.Core.Constants.DEFAULTS.MESSAGE_TEMPLATE_RAID,
            minimapHidden = AutoLFM.Core.Constants.DEFAULTS.MINIMAP_HIDDEN,
            minimapPos = AutoLFM.Core.Constants.DEFAULTS.MINIMAP_POS,
            presetsCondensed = AutoLFM.Core.Constants.DEFAULTS.PRESETS_CONDENSED,
            selectedChannels = AutoLFM.Core.Constants.DEFAULTS.SELECTED_CHANNELS,
            welcomeShown = AutoLFM.Core.Constants.DEFAULTS.WELCOME_SHOWN
        }
    end

    return V3_Settings[characterID]
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Initialize SavedVariables
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.Init()
    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or not realm then return end

    characterID = name .. "-" .. realm
    EnsureCharData()

    -- Initialize Presets
    if not V3_Presets then
        V3_Presets = {}
    end
    if not V3_Presets[characterID] then
        V3_Presets[characterID] = {
            data = {},
            order = {}
        }
    end
end

-----------------------------------------------------------------------------
-- Get Character ID
--   @return string: Character ID (name-realm)
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.GetCharacterID()
    return characterID
end

--=============================================================================
-- GENERIC GET/SET
--=============================================================================

-----------------------------------------------------------------------------
-- Get Setting
--   @param key string: Setting key
--   @param defaultValue any: Default value if not found
--   @return any: Setting value
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.Get(key, defaultValue)
    local charData = GetCharData()
    if not charData then
        return defaultValue
    end

    local value = charData[key]
    if value == nil then
        return defaultValue
    end

    return value
end

-----------------------------------------------------------------------------
-- Set Setting
--   @param key string: Setting key
--   @param value any: Setting value
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.Set(key, value)
    local charData = EnsureCharData()
    if not charData then return end

    charData[key] = value
end

--=============================================================================
-- MINIMAP BUTTON SETTINGS
--=============================================================================

function AutoLFM.Core.Persistent.GetMinimapPos()
    return AutoLFM.Core.Persistent.Get("minimapPos")
end

function AutoLFM.Core.Persistent.SetMinimapPos(x, y)
    if x and y then
        AutoLFM.Core.Persistent.Set("minimapPos", { x = x, y = y })
    else
        AutoLFM.Core.Persistent.Set("minimapPos", nil)
    end
end

function AutoLFM.Core.Persistent.GetMinimapHidden()
    return AutoLFM.Core.Persistent.Get("minimapHidden", AutoLFM.Core.Constants.DEFAULTS.MINIMAP_HIDDEN)
end

function AutoLFM.Core.Persistent.SetMinimapHidden(hidden)
    AutoLFM.Core.Persistent.Set("minimapHidden", hidden == true)
end

--=============================================================================
-- WELCOME POPUP SETTINGS
--=============================================================================

function AutoLFM.Core.Persistent.GetWelcomeShown()
    return AutoLFM.Core.Persistent.Get("welcomeShown", AutoLFM.Core.Constants.DEFAULTS.WELCOME_SHOWN)
end

function AutoLFM.Core.Persistent.SetWelcomeShown(shown)
    AutoLFM.Core.Persistent.Set("welcomeShown", shown == true)
end

--=============================================================================
-- DARK MODE SETTINGS
--=============================================================================

function AutoLFM.Core.Persistent.GetDarkMode()
    return AutoLFM.Core.Persistent.Get("darkMode", false)
end

function AutoLFM.Core.Persistent.SetDarkMode(isEnabled)
    AutoLFM.Core.Persistent.Set("darkMode", isEnabled == true)
end

--=============================================================================
-- PRESETS VIEW SETTINGS
--=============================================================================

function AutoLFM.Core.Persistent.GetPresetsCondensed()
    return AutoLFM.Core.Persistent.Get("presetsCondensed", false)
end

function AutoLFM.Core.Persistent.SetPresetsCondensed(isEnabled)
    AutoLFM.Core.Persistent.Set("presetsCondensed", isEnabled == true)
end

--=============================================================================
-- DEFAULT PANEL SETTINGS
--=============================================================================

function AutoLFM.Core.Persistent.GetDefaultPanel()
    return AutoLFM.Core.Persistent.Get("defaultPanel", AutoLFM.Core.Constants.DEFAULTS.DEFAULT_PANEL)
end

function AutoLFM.Core.Persistent.SetDefaultPanel(panelName)
    AutoLFM.Core.Persistent.Set("defaultPanel", panelName)
end

--=============================================================================
-- DUNGEON FILTER SETTINGS
--=============================================================================

function AutoLFM.Core.Persistent.GetDungeonFilters()
    local filters = AutoLFM.Core.Persistent.Get("dungeonFilters")
    if not filters then
        filters = AutoLFM.Core.Constants.DEFAULTS.DUNGEON_FILTERS
    end
    return filters
end

function AutoLFM.Core.Persistent.SetDungeonFilter(filterId, enabled)
    local filters = AutoLFM.Core.Persistent.GetDungeonFilters()
    if filters then
        filters[filterId] = enabled
        AutoLFM.Core.Persistent.Set("dungeonFilters", filters)
    end
end

--=============================================================================
-- MESSAGE TEMPLATE SETTINGS
--=============================================================================

function AutoLFM.Core.Persistent.GetMessageTemplateDungeon()
    return AutoLFM.Core.Persistent.Get("messageTemplateDungeon", AutoLFM.Core.Constants.DEFAULTS.MESSAGE_TEMPLATE_DUNGEON)
end

function AutoLFM.Core.Persistent.SetMessageTemplateDungeon(template)
    AutoLFM.Core.Persistent.Set("messageTemplateDungeon", template or AutoLFM.Core.Constants.DEFAULTS.MESSAGE_TEMPLATE_DUNGEON)
end

function AutoLFM.Core.Persistent.GetMessageTemplateRaid()
    return AutoLFM.Core.Persistent.Get("messageTemplateRaid", AutoLFM.Core.Constants.DEFAULTS.MESSAGE_TEMPLATE_RAID)
end

function AutoLFM.Core.Persistent.SetMessageTemplateRaid(template)
    AutoLFM.Core.Persistent.Set("messageTemplateRaid", template or AutoLFM.Core.Constants.DEFAULTS.MESSAGE_TEMPLATE_RAID)
end

--=============================================================================
-- PRESETS MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Get All Presets
--   @return table: All presets for current character
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.GetPresets()
    if not V3_Presets or not characterID then return {} end
    if not V3_Presets[characterID] then return {} end
    return V3_Presets[characterID].data or {}
end

-----------------------------------------------------------------------------
-- Save Preset
--   @param presetName string: Preset name
--   @param presetData table: Preset data
--   @return boolean: Success
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.SavePreset(presetName, presetData)
    if not V3_Presets or not characterID or not presetName then return false end

    if not V3_Presets[characterID] then
        V3_Presets[characterID] = {
            data = {},
            order = {}
        }
    end

    V3_Presets[characterID].data[presetName] = AutoLFM.Core.Persistent.DeepCopy(presetData)

    -- Add to order if new preset
    local order = V3_Presets[characterID].order
    local found = false
    for i = 1, table.getn(order) do
        if order[i] == presetName then
            found = true
            break
        end
    end
    if not found then
        table.insert(order, presetName)
    end

    return true
end

-----------------------------------------------------------------------------
-- Delete Preset
--   @param presetName string: Preset name
--   @return boolean: Success
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.DeletePreset(presetName)
    if not V3_Presets or not characterID or not presetName then return false end

    if V3_Presets[characterID] and V3_Presets[characterID].data[presetName] then
        V3_Presets[characterID].data[presetName] = nil

        -- Remove from order
        local order = V3_Presets[characterID].order
        for i = 1, table.getn(order) do
            if order[i] == presetName then
                table.remove(order, i)
                break
            end
        end

        return true
    end

    return false
end

-----------------------------------------------------------------------------
-- Check if Preset Exists
--   @param presetName string: Preset name
--   @return boolean: true if preset exists
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.PresetExists(presetName)
    if not V3_Presets or not characterID or not presetName then return false end
    return V3_Presets[characterID] and V3_Presets[characterID].data[presetName] ~= nil
end

-----------------------------------------------------------------------------
-- Get Presets Order
--   @return table: Ordered list of preset names
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.GetPresetsOrder()
    if not V3_Presets or not characterID then return {} end
    if not V3_Presets[characterID] then
        V3_Presets[characterID] = {
            data = {},
            order = {}
        }
    end
    return V3_Presets[characterID].order
end

-----------------------------------------------------------------------------
-- Set Presets Order
--   @param order table: Ordered list of preset names
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.SetPresetsOrder(order)
    if not V3_Presets or not characterID or not order then return end
    if not V3_Presets[characterID] then
        V3_Presets[characterID] = {
            data = {},
            order = {}
        }
    end
    V3_Presets[characterID].order = order
end

-----------------------------------------------------------------------------
-- Move Preset Up
--   @param presetName string: Preset name
--   @return boolean: Success
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.MovePresetUp(presetName)
    if not presetName or not V3_Presets or not characterID then return false end
    if not V3_Presets[characterID] then return false end

    local order = V3_Presets[characterID].order
    for i = 1, table.getn(order) do
        if order[i] == presetName then
            if i > 1 then
                -- Swap with previous
                local temp = order[i - 1]
                order[i - 1] = order[i]
                order[i] = temp
                return true
            end
            return false
        end
    end
    return false
end

-----------------------------------------------------------------------------
-- Move Preset Down
--   @param presetName string: Preset name
--   @return boolean: Success
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.MovePresetDown(presetName)
    if not presetName or not V3_Presets or not characterID then return false end
    if not V3_Presets[characterID] then return false end

    local order = V3_Presets[characterID].order
    for i = 1, table.getn(order) do
        if order[i] == presetName then
            if i < table.getn(order) then
                -- Swap with next
                local temp = order[i + 1]
                order[i + 1] = order[i]
                order[i] = temp
                return true
            end
            return false
        end
    end
    return false
end

--=============================================================================
-- UTILITY FUNCTIONS
--=============================================================================

-----------------------------------------------------------------------------
-- Deep Copy Table
--   @param obj any: Object to copy
--   @return any: Deep copy of object
-----------------------------------------------------------------------------
function AutoLFM.Core.Persistent.DeepCopy(obj)
    if type(obj) ~= "table" then
        return obj
    end

    local copy = {}
    for k, v in pairs(obj) do
        if type(v) == "table" then
            copy[k] = AutoLFM.Core.Persistent.DeepCopy(v)
        else
            copy[k] = v
        end
    end

    return copy
end
