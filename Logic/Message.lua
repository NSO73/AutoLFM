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
    -- Templates are already loaded by Maestro.Init()

    -- Register event listeners to auto-update preview message
    local function updatePreview()
        AutoLFM.Logic.Message.UpdatePreview()
    end

    -- Listen to all events that affect the message
    AutoLFM.Core.Maestro.On("Dungeons.SelectionChanged", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when dungeon selection changes"
    })

    AutoLFM.Core.Maestro.On("Dungeons.AllDeselected", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when all dungeons are deselected"
    })

    AutoLFM.Core.Maestro.On("Raids.SelectionChanged", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when raid selection changes"
    })

    AutoLFM.Core.Maestro.On("Raids.AllDeselected", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when all raids are deselected"
    })

    AutoLFM.Core.Maestro.On("Raids.SizeChanged", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when raid size changes"
    })

    AutoLFM.Core.Maestro.On("Quests.SelectionChanged", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when quest selection changes"
    })

    AutoLFM.Core.Maestro.On("Roles.Toggled", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when role is toggled"
    })

    AutoLFM.Core.Maestro.On("Broadcasts.CustomMessageChanged", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when custom message changes"
    })

    AutoLFM.Core.Maestro.On("Messages.TemplateChanged", updatePreview, {
        key = "Messages.UpdatePreview",
        description = "Updates message preview when template changes"
    })
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.RegisterCommands()
    -- Set dungeon template command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Messages.SetDungeonTemplate",
        description = "Sets the message template for dungeons",
        handler = function(template)
            if not template or template == "" then
                template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon
            end

            if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate then
                AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(template)
            end

            AutoLFM.Core.Persistent.SetMessageTemplateDungeon(template)
            AutoLFM.Core.Maestro.Emit("Messages.TemplateChanged", "dungeon", template)
        end
    })

    -- Set raid template command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Messages.SetRaidTemplate",
        description = "Sets the message template for raids",
        handler = function(template)
            if not template or template == "" then
                template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid
            end

            if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate then
                AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(template)
            end

            AutoLFM.Core.Persistent.SetMessageTemplateRaid(template)
            AutoLFM.Core.Maestro.Emit("Messages.TemplateChanged", "raid", template)
        end
    })

    -- Reset dungeon template to default
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Messages.ResetDungeonTemplate",
        description = "Resets the dungeon template to default",
        handler = function()
            local defaultTemplate = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon

            if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate then
                AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(defaultTemplate)
            end

            AutoLFM.Core.Persistent.SetMessageTemplateDungeon(defaultTemplate)
            AutoLFM.Core.Maestro.Emit("Messages.TemplateChanged", "dungeon", defaultTemplate)
        end
    })

    -- Reset raid template to default
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Messages.ResetRaidTemplate",
        description = "Resets the raid template to default",
        handler = function()
            local defaultTemplate = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid

            if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate then
                AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(defaultTemplate)
            end

            AutoLFM.Core.Persistent.SetMessageTemplateRaid(defaultTemplate)
            AutoLFM.Core.Maestro.Emit("Messages.TemplateChanged", "raid", defaultTemplate)
        end
    })

    -- Preview message in chat
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Messages.Preview",
        description = "Previews the generated message in chat",
        handler = function()
            local message = AutoLFM.Logic.Message.BuildMessage()
            if message and message ~= "" then
                AutoLFM.Core.Utils.PrintInfo("Preview: " .. message)
            else
                AutoLFM.Core.Utils.PrintWarning("No message to preview (select dungeons/raids first)")
            end
        end
    })
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("message.init", function()
    AutoLFM.Logic.Message.Init()
    AutoLFM.Logic.Message.RegisterCommands()
end, {
    key = "Messages.Init",
    description = "Initialize message generation with customizable templates"
})
