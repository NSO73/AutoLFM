--=============================================================================
-- AutoLFM: Quests
--   Quests selection and quest log integration
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content.Quests = AutoLFM.Logic.Content.Quests or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local selectedQuests = {}

--=============================================================================
-- QUEST LOG RETRIEVAL
--=============================================================================

-----------------------------------------------------------------------------
-- Get Quests from Player's Quest Log
--   @return table: Array of quest data
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.GetQuestLog()
    local quests = {}
    local numEntries = GetNumQuestLogEntries()

    for i = 1, numEntries do
        local questLogTitleText, level, questTag, isHeader = GetQuestLogTitle(i)

        -- Only add actual quests, not headers
        if questLogTitleText and not isHeader then
            table.insert(quests, {
                index = i,
                name = questLogTitleText,
                level = level or 1,
                tag = questTag
            })
        end
    end

    return quests
end

--=============================================================================
-- QUEST COLOR CALCULATION
--=============================================================================

-----------------------------------------------------------------------------
-- Get Quest Color Based on Level Difference
--   @param questLevel number: Quest level
--   @return table: Color data
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.GetQuestColor(questLevel)
    if not questLevel then return AutoLFM.Core.Constants.COLORS.GRAY end

    local playerLevel = UnitLevel("player") or 1
    local priority = AutoLFM.Core.Utils.CalculateLevelPriority(playerLevel, questLevel, questLevel)
    return AutoLFM.Core.Utils.GetColor(priority)
end

--=============================================================================
-- QUEST LINK CREATION
--=============================================================================

-----------------------------------------------------------------------------
-- Create Quest Link for Chat
--   @param questIndex number: Quest log index
--   @return string: Quest link or nil
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.CreateQuestLink(questIndex)
    if not questIndex then return nil end
    if questIndex < 1 then return nil end

    local title, level, _, _, _, _, _, questID = GetQuestLogTitle(questIndex)
    if not title then return nil end

    questID = questID or 0
    level = level or 0
    local cleanTitle = string.gsub(title, "^%[.-%]%s*", "")

    -- Calculate color based on quest level vs player level
    local playerLevel = UnitLevel("player") or 1
    local priority = AutoLFM.Core.Utils.CalculateLevelPriority(playerLevel, level, level)
    local color = AutoLFM.Core.Utils.GetColor(priority)
    local colorCode = AutoLFM.Core.Utils.RGBToHex(color.r, color.g, color.b)

    -- Create quest link format with dynamic color
    return string.format(
        AutoLFM.Core.Constants.LINK_FORMATS.QUEST,
        colorCode,
        questID,
        level,
        cleanTitle
    )
end

--=============================================================================
-- QUEST ZONE RETRIEVAL
--=============================================================================

-----------------------------------------------------------------------------
-- Get Quest Zone by Finding the Header Above It
--   @param questIndex number: Quest log index
--   @return string: Zone name or nil
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.GetQuestZone(questIndex)
    if not questIndex then return nil end
    if questIndex <= 0 then return nil end

    for i = questIndex - 1, 1, -1 do
        local headerTitle, headerLevel = GetQuestLogTitle(i)
        if headerTitle and (not headerLevel or headerLevel == 0) then
            return headerTitle
        end
    end

    return nil
end

--=============================================================================
-- CUSTOM MESSAGE MANIPULATION
--=============================================================================

-----------------------------------------------------------------------------
-- Check if Quest Link is in Custom Message
--   @param link string: Quest link
--   @return boolean: True if link is in message
-----------------------------------------------------------------------------
local function IsQuestLinkInCustomMessage(link)
    if not link then return false end

    local currentText = ""
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetCustomMessage then
        currentText = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""
    end

    local escapedLink = string.gsub(link, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    return string.find(currentText, escapedLink) ~= nil
end

-----------------------------------------------------------------------------
-- Add Quest Link to Custom Message
--   @param link string: Quest link
-----------------------------------------------------------------------------
local function AddQuestLinkToCustomMessage(link)
    if not link then return end

    local currentText = ""
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetCustomMessage then
        currentText = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""
    end

    local newText = currentText == "" and link or (currentText .. " " .. link)

    -- Use Maestro command to update message
    AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetCustomMessage", newText)

    -- Update EditBox UI
    local editBox = getglobal("AutoLFM_Panel_Broadcasts_EditBox")
    if editBox then
        editBox:SetText(newText)
    end
end

-----------------------------------------------------------------------------
-- Remove Quest Link from Custom Message
--   @param link string: Quest link
-----------------------------------------------------------------------------
local function RemoveQuestLinkFromCustomMessage(link)
    if not link then return end

    local currentText = ""
    if AutoLFM.Logic.Content.Broadcasts and AutoLFM.Logic.Content.Broadcasts.GetCustomMessage then
        currentText = AutoLFM.Logic.Content.Broadcasts.GetCustomMessage() or ""
    end

    local escapedLink = string.gsub(link, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local newText = string.gsub(currentText, escapedLink, "")

    -- Clean up extra spaces
    newText = string.gsub(newText, "%s+", " ")
    newText = string.gsub(newText, "^%s+", "")
    newText = string.gsub(newText, "%s+$", "")

    -- Use Maestro command to update message
    AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetCustomMessage", newText)

    -- Update EditBox UI
    local editBox = getglobal("AutoLFM_Panel_Broadcasts_EditBox")
    if editBox then
        editBox:SetText(newText)
    end
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.RegisterCommands()
    -- Select quest command
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "Quests.Select",
        name = "Select Quest",
        description = "Selects a quest and adds its link to the broadcast message",
        handler = function(questIndex)
            if not questIndex then return end

            selectedQuests[questIndex] = true

            -- Add quest link to custom broadcast message
            local link = AutoLFM.Logic.Content.Quests.CreateQuestLink(questIndex)
            if link and not IsQuestLinkInCustomMessage(link) then
                AddQuestLinkToCustomMessage(link)
            end

            AutoLFM.Core.Maestro.Emit("Quests.SelectionChanged", questIndex, true)
        end
    })

    -- Deselect quest command
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "quests.deselect",
        name = "Deselect Quest",
        description = "Deselects a quest and removes its link from the broadcast message",
        handler = function(questIndex)
            if not questIndex then return end

            selectedQuests[questIndex] = nil

            -- Remove quest link from custom broadcast message
            local link = AutoLFM.Logic.Content.Quests.CreateQuestLink(questIndex)
            if link then
                RemoveQuestLinkFromCustomMessage(link)
            end

            AutoLFM.Core.Maestro.Emit("Quests.SelectionChanged", questIndex, false)
        end
    })

    -- Deselect all quests command (optimized for bulk operations)
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "Quests.DeselectAll",
        name = "Deselect All Quests",
        description = "Deselects all quests at once",
        handler = function()
            -- Clear local state directly (no individual deselect events)
            selectedQuests = {}

            -- Note: Quest links are cleared via broadcasts.set_custom_message("") in ClearAll
            -- No need to remove individual quest links here
        end
    })
end

--=============================================================================
-- PUBLIC GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Check if Quest is Selected
--   @param questIndex number: Quest index
--   @return boolean: Selection state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.IsSelected(questIndex)
    if not questIndex then return false end
    return selectedQuests[questIndex] and true or false
end

-----------------------------------------------------------------------------
-- Get Selected Quests
--   @return table: Array of selected quest data
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.GetSelected()
    local quests = AutoLFM.Logic.Content.Quests.GetQuestLog()
    local selected = {}

    for i = 1, table.getn(quests) do
        if selectedQuests[quests[i].index] then
            table.insert(selected, quests[i])
        end
    end

    return selected
end

--=============================================================================
-- CONTENT MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Load Quests Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Quests.Load()
    local content = getglobal("AutoLFM_MainFrame_Content")
    if not content then return end

    local quests = AutoLFM.Logic.Content.Quests.GetQuestLog()
    if AutoLFM.UI.Content and AutoLFM.UI.Content.Quests and AutoLFM.UI.Content.Quests.Create then
        AutoLFM.UI.Content.Quests.Create(content, quests)
    end
end

--=============================================================================
-- UI HANDLERS
--=============================================================================

-- Create UI namespace for XML callbacks
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Quests = AutoLFM.UI.Content.Quests or {}

local QuestsUI = AutoLFM.UI.Content.Quests
local checkboxes = {}
local uiFrame = nil

-----------------------------------------------------------------------------
-- UI Lifecycle
-----------------------------------------------------------------------------
function QuestsUI.OnLoad(self)
    uiFrame = self
end

function QuestsUI.OnShow(self)
    QuestsUI.Refresh()
end

-----------------------------------------------------------------------------
-- UI Management
-----------------------------------------------------------------------------
function QuestsUI.Refresh()
    -- Clear existing checkboxes
    QuestsUI.ClearCheckboxes()

    -- Request quest log data and create checkboxes
    AutoLFM.Core.Maestro.Dispatch("UI.Quests.Refresh", uiFrame, checkboxes)
end

function QuestsUI.ClearCheckboxes()
    for _, checkbox in ipairs(checkboxes) do
        checkbox:Hide()
        checkbox:SetParent(nil)
    end
    checkboxes = {}
end

-----------------------------------------------------------------------------
-- Event Handlers
-----------------------------------------------------------------------------
function QuestsUI.OnQuestToggle(checkbox)
    local questIndex = checkbox.questIndex
    if not questIndex then return end

    -- Dispatch toggle command
    AutoLFM.Core.Maestro.Dispatch("Quest.Toggle", questIndex, checkbox:GetChecked() == 1)
end

function QuestsUI.OnQuestEnter(checkbox)
    local questTitle = checkbox.questTitle
    local questDescription = checkbox.questDescription

    if not questTitle then return end

    GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
    GameTooltip:SetText(questTitle, 1, 1, 1)

    if questDescription then
        GameTooltip:AddLine(questDescription, 0.8, 0.8, 0.8, 1, true)
    end

    GameTooltip:Show()
end

function QuestsUI.OnRefreshClick()
    QuestsUI.Refresh()
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function QuestsUI.GetCheckboxes()
    return checkboxes
end

function QuestsUI.ShowEmptyMessage()
    local emptyMsg = getglobal(uiFrame:GetName().."_EmptyMessage")
    if emptyMsg then
        emptyMsg:Show()
    end
end

function QuestsUI.HideEmptyMessage()
    local emptyMsg = getglobal(uiFrame:GetName().."_EmptyMessage")
    if emptyMsg then
        emptyMsg:Hide()
    end
end

-----------------------------------------------------------------------------
-- Event Listeners
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.On("Quest.StateChanged", function()
    if uiFrame and uiFrame:IsVisible() then
        QuestsUI.Refresh()
    end
end)

AutoLFM.Core.Maestro.On("QuestLog.Updated", function()
    if uiFrame and uiFrame:IsVisible() then
        QuestsUI.Refresh()
    end
end)

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("quests.init", function()
    AutoLFM.Logic.Content.Quests.RegisterCommands()
end, {
    name = "Quests Commands",
    description = "Register quest selection and quest log integration commands"
})
