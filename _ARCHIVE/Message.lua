--=============================================================================
-- AutoLFM: Message
--   Message generation logic with customizable templates
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Message = AutoLFM.Logic.Message or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local previewMessage = ""

--=============================================================================
-- TEMPLATE PARSING
--=============================================================================

-----------------------------------------------------------------------------
-- Parse Template with Variables
--   @param template string: Message template
--   @param variables table: Variable name/value pairs
--   @return string: Parsed message
-----------------------------------------------------------------------------
local function ParseTemplate(template, variables)
    if not template then return "" end
    if not variables then return template end

    local result = template

    -- Replace all variables
    for varName, value in pairs(variables) do
        if value then
            result = string.gsub(result, varName, tostring(value))
        end
    end

    return result
end

--=============================================================================
-- VARIABLE COLLECTION
--=============================================================================

-----------------------------------------------------------------------------
-- Get Dungeon Variables
--   @return table: Dungeon template variables
-----------------------------------------------------------------------------
local function GetDungeonVariables()
    local dungeonTags = {}
    local selectedDungeons = {}

    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
        selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
    end

    for i = 1, table.getn(selectedDungeons) do
        local dungeon = selectedDungeons[i]
        if dungeon then
            table.insert(dungeonTags, dungeon.tag)
        end
    end

    local content = table.concat(dungeonTags, " or ")
    local stats = { missing = 0, current = 0, target = 0 }

    if AutoLFM.Logic.Group and AutoLFM.Logic.Group.GetDungeonStats then
        stats = AutoLFM.Logic.Group.GetDungeonStats()
    end

    return {
        content = content,
        missing = stats.missing,
        current = stats.current,
        target = stats.target
    }
end

-----------------------------------------------------------------------------
-- Get Raid Variables
--   @return table: Raid template variables
-----------------------------------------------------------------------------
local function GetRaidVariables()
    local raidTag = ""
    local raidSize = 40

    -- Get the first (and only) selected raid
    local selectedRaids = {}
    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
        selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
    end

    if table.getn(selectedRaids) > 0 then
        local raid = selectedRaids[1]
        if raid then
            raidTag = raid.tag
            -- Get raid size from Raids module
            local raidIndex = raid.index
            if AutoLFM.Logic.Content.Raids.GetRaidSize then
                raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raidIndex) or raid.sizeMin or 40
            end
        end
    end

    local stats = { missing = 0, current = 0, target = 0 }
    if AutoLFM.Logic.Group and AutoLFM.Logic.Group.GetRaidStats then
        stats = AutoLFM.Logic.Group.GetRaidStats(raidSize)
    end

    return {
        content = raidTag,
        missing = stats.missing,
        current = stats.current,
        target = stats.target
    }
end

--=============================================================================
-- MESSAGE GENERATION
--=============================================================================

-----------------------------------------------------------------------------
-- Generate Message from Current Selection
--   @return string: Generated message
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.Generate()
    local message = ""

    -- Get content type and data from Selection module
    local contentType = "none"
    local selectedContent = {}

    if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.GetContentTypeAndData then
        contentType, selectedContent = AutoLFM.Logic.Selection.GetContentTypeAndData()
    end

    -- Get roles string from Selection module
    local rolesString = ""
    if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.GetRolesString then
        rolesString = AutoLFM.Logic.Selection.GetRolesString()
    end

    if contentType == "raids" then
        -- Use raid template
        local vars = GetRaidVariables()
        local template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid

        if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate then
            template = AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate()
        end

        message = ParseTemplate(template, {
            ["_CONS_"] = vars.content,
            ["_MISS_"] = vars.missing,
            ["_CUR_"] = vars.current,
            ["_TAR_"] = vars.target,
            ["_ROL_"] = rolesString
        })
    elseif contentType == "dungeons" then
        -- Use dungeon template
        local vars = GetDungeonVariables()
        local template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon

        if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate then
            template = AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate()
        end

        message = ParseTemplate(template, {
            ["_CONS_"] = vars.content,
            ["_MISS_"] = vars.missing,
            ["_CUR_"] = vars.current,
            ["_TAR_"] = vars.target,
            ["_ROL_"] = rolesString
        })
    elseif rolesString ~= "" then
        -- No dungeons or raids, but roles are selected - show roles only
        message = rolesString
    end

    -- Add custom broadcast message if present
    local customMessage = ""
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetCustomMessage then
        customMessage = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage()
    end

    if customMessage and customMessage ~= "" then
        if message ~= "" then
            message = message .. " " .. customMessage
        else
            message = customMessage
        end
    end

    return message
end

--=============================================================================
-- PREVIEW UPDATE
--=============================================================================

-----------------------------------------------------------------------------
-- Update Preview Message
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.UpdatePreview()
    previewMessage = AutoLFM.Logic.Message.Generate()
end

--=============================================================================
-- PUBLIC GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Get Preview Message
--   @return string: Preview message
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.GetPreviewMessage()
    return previewMessage
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Initialize Message Module
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.Init()
    -- Empty function, listeners removed
end

--=============================================================================
-- PUBLIC API
--=============================================================================

-----------------------------------------------------------------------------
-- Set Dungeon Template
--   @param template string: Template string
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.SetDungeonTemplate(template)
    if not template or template == "" then
        template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon
    end

    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate then
        AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(template)
    end

    AutoLFM.Core.Persistent.SetMessageTemplateDungeon(template)
end

-----------------------------------------------------------------------------
-- Set Raid Template
--   @param template string: Template string
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.SetRaidTemplate(template)
    if not template or template == "" then
        template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid
    end

    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate then
        AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(template)
    end

    AutoLFM.Core.Persistent.SetMessageTemplateRaid(template)
end

-----------------------------------------------------------------------------
-- Reset Dungeon Template
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.ResetDungeonTemplate()
    local defaultTemplate = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon

    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate then
        AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(defaultTemplate)
    end

    AutoLFM.Core.Persistent.SetMessageTemplateDungeon(defaultTemplate)
end

-----------------------------------------------------------------------------
-- Reset Raid Template
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.ResetRaidTemplate()
    local defaultTemplate = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid

    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate then
        AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(defaultTemplate)
    end

    AutoLFM.Core.Persistent.SetMessageTemplateRaid(defaultTemplate)
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("message.init", function()
    AutoLFM.Logic.Message.Init()
end, {
    key = "Messages.Init",
    description = "Initialize message generation with customizable templates"
})
