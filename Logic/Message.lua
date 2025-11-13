--=============================================================================
-- AutoLFM: Message
--   Message generation logic with customizable templates
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Message = AutoLFM.Logic.Message or {}

-----------------------------------------------------------------------------
-- Private State (owned by this module)
-----------------------------------------------------------------------------
local previewMessage = ""

function AutoLFM.Logic.Message.Init()
  -- Templates are already loaded by Maestro.Init()

  -- Register event listeners to auto-update preview message
  local function updatePreview()
    AutoLFM.Logic.Message.UpdatePreview()
  end

  -- Listen to all events that affect the message
  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.SelectionChanged", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.AllDeselected", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.SelectionChanged", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.AllDeselected", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Raids.SizeChanged", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Quests.SelectionChanged", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Roles.RoleToggled", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Broadcasts.CustomMessageChanged", updatePreview, "Update message preview")
  AutoLFM.Core.Maestro.RegisterEventListener("Messages.TemplateChanged", updatePreview, "Update message preview")
end

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.RegisterCommands()
  -- Set dungeon template command
  AutoLFM.Core.Maestro.RegisterCommand("Messages.SetDungeonTemplate", function(template)
    if not template or template == "" then
      template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon
    end
    AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(template)
    AutoLFM.Core.Persistent.SetMessageTemplateDungeon(template)
    AutoLFM.Core.Maestro.EmitEvent("Messages.TemplateChanged", "dungeon", template)
  end)

  -- Set raid template command
  AutoLFM.Core.Maestro.RegisterCommand("Messages.SetRaidTemplate", function(template)
    if not template or template == "" then
      template = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid
    end
    AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(template)
    AutoLFM.Core.Persistent.SetMessageTemplateRaid(template)
    AutoLFM.Core.Maestro.EmitEvent("Messages.TemplateChanged", "raid", template)
  end)

  -- Reset dungeon template to default
  AutoLFM.Core.Maestro.RegisterCommand("Messages.ResetDungeonTemplate", function()
    local defaultTemplate = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.dungeon
    AutoLFM.Logic.Content.Broadcasts.SetDungeonTemplate(defaultTemplate)
    AutoLFM.Core.Persistent.SetMessageTemplateDungeon(defaultTemplate)
    AutoLFM.Core.Maestro.EmitEvent("Messages.TemplateChanged", "dungeon", defaultTemplate)
  end)

  -- Reset raid template to default
  AutoLFM.Core.Maestro.RegisterCommand("Messages.ResetRaidTemplate", function()
    local defaultTemplate = AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES.raid
    AutoLFM.Logic.Content.Broadcasts.SetRaidTemplate(defaultTemplate)
    AutoLFM.Core.Persistent.SetMessageTemplateRaid(defaultTemplate)
    AutoLFM.Core.Maestro.EmitEvent("Messages.TemplateChanged", "raid", defaultTemplate)
  end)
end

-----------------------------------------------------------------------------
-- Template Parsing
-----------------------------------------------------------------------------
local function ParseTemplate(template, variables)
  if not template then return "" end

  local result = template

  -- Replace all variables
  for varName, value in pairs(variables) do
    if value then
      result = string.gsub(result, varName, tostring(value))
    end
  end

  return result
end

-----------------------------------------------------------------------------
-- Variable Collection
-----------------------------------------------------------------------------
local function GetDungeonVariables()
  local dungeonTags = {}
  local selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
  for i = 1, table.getn(selectedDungeons) do
    local dungeon = selectedDungeons[i]
    if dungeon then
      table.insert(dungeonTags, dungeon.tag)
    end
  end

  local content = table.concat(dungeonTags, " or ")
  local stats = AutoLFM.Logic.Group.GetDungeonStats()

  return {
    content = content,
    missing = stats.missing,
    current = stats.current,
    target = stats.target
  }
end

local function GetRaidVariables()
  local raidTag = ""
  local raidSize = 40

  -- Get the first (and only) selected raid
  local selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
  if table.getn(selectedRaids) > 0 then
    local raid = selectedRaids[1]
    if raid then
      raidTag = raid.tag
      -- Get raid size from Raids module
      local raidIndex = raid.index
      raidSize = AutoLFM.Logic.Content.Raids.GetRaidSize(raidIndex) or raid.sizeMin or 40
    end
  end

  local stats = AutoLFM.Logic.Group.GetRaidStats(raidSize)

  return {
    content = raidTag,
    missing = stats.missing,
    current = stats.current,
    target = stats.target
  }
end

-----------------------------------------------------------------------------
-- Message Generation
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.Generate()
  local message = ""

  -- Get content type and data from Selection module
  local contentType, selectedContent = AutoLFM.Logic.Selection.GetContentTypeAndData()

  -- Get roles string from Selection module
  local rolesString = AutoLFM.Logic.Selection.GetRolesString()

  if contentType == "raids" then
    -- Use raid template
    local vars = GetRaidVariables()
    local template = AutoLFM.Logic.Content.Broadcasts.GetRaidTemplate()

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
    local template = AutoLFM.Logic.Content.Broadcasts.GetDungeonTemplate()

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
  local customMessage = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage()
  if customMessage and customMessage ~= "" then
    if message ~= "" then
      message = message .. " " .. customMessage
    else
      message = customMessage
    end
  end

  return message
end

-----------------------------------------------------------------------------
-- Update Preview
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.UpdatePreview()
  previewMessage = AutoLFM.Logic.Message.Generate()
end

-----------------------------------------------------------------------------
-- Public Getter
-----------------------------------------------------------------------------
function AutoLFM.Logic.Message.GetPreviewMessage()
  return previewMessage
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Message", function()
  AutoLFM.Logic.Message.Init()
  AutoLFM.Logic.Message.RegisterCommands()
end)
