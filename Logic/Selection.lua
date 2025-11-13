--=============================================================================
-- AutoLFM: Selection
--   Selection constraints management (mutual exclusion, limits)
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Selection = AutoLFM.Logic.Selection or {}

--=============================================================================
-- DUNGEON SELECTION CONSTRAINTS
--=============================================================================

-----------------------------------------------------------------------------
-- On Dungeon Checked Handler
--   Applies mutual exclusion with raids and max dungeon limit
--   @param dungeonIndex number: Dungeon index
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.OnDungeonChecked(dungeonIndex)
    if not dungeonIndex then return end

    -- Uncheck all raids (dungeons and raids are mutually exclusive)
    AutoLFM.Core.Maestro.Dispatch("Raids.DeselectAll")

    -- Get selection order from Dungeons module
    local selectionOrder = {}
    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelectionOrder then
        selectionOrder = AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
    end

    table.insert(selectionOrder, dungeonIndex)

    -- If more than MAX_DUNGEONS selected, uncheck the oldest one
    if table.getn(selectionOrder) > AutoLFM.Core.Constants.MAX_DUNGEONS then
        local oldestIndex = table.remove(selectionOrder, 1)

        -- Deselect via command
        AutoLFM.Core.Maestro.Dispatch("Dungeons.Deselect", oldestIndex)

        -- Find and uncheck the oldest dungeon checkbox (prevent OnClick from firing)
        local checkbox = AutoLFM.Logic.Selection.FindDungeonCheckbox(oldestIndex)
        if checkbox then
            AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
        end
    end
end

-----------------------------------------------------------------------------
-- On Dungeon Unchecked Handler
--   @param dungeonIndex number: Dungeon index
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.OnDungeonUnchecked(dungeonIndex)
    if not dungeonIndex then return end

    -- Remove from selection order in Dungeons module
    local selectionOrder = {}
    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelectionOrder then
        selectionOrder = AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
    end

    for i = 1, table.getn(selectionOrder) do
        if selectionOrder[i] == dungeonIndex then
            table.remove(selectionOrder, i)
            break
        end
    end
end

--=============================================================================
-- RAID SELECTION CONSTRAINTS
--=============================================================================

-----------------------------------------------------------------------------
-- On Raid Checked Handler
--   Applies mutual exclusion with dungeons and allows only 1 raid
--   @param raidIndex number: Raid index
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.OnRaidChecked(raidIndex)
    if not raidIndex then return end

    -- Uncheck all dungeons (dungeons and raids are mutually exclusive)
    AutoLFM.Core.Maestro.Dispatch("Dungeons.DeselectAll")

    -- Get selection order from Raids module
    local selectionOrder = {}
    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelectionOrder then
        selectionOrder = AutoLFM.Logic.Content.Raids.GetSelectionOrder()
    end

    -- If another raid is selected, uncheck it (only 1 raid allowed)
    if table.getn(selectionOrder) > 0 then
        local oldRaidIndex = selectionOrder[1]

        -- Deselect via command
        AutoLFM.Core.Maestro.Dispatch("Raids.Deselect", oldRaidIndex)

        -- Find and uncheck the old raid checkbox (prevent OnClick from firing)
        local checkbox = AutoLFM.Logic.Selection.FindRaidCheckbox(oldRaidIndex)
        if checkbox then
            AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
        end

        -- Hide the old raid's size controls
        if AutoLFM.UI.Content and AutoLFM.UI.Content.Raids and AutoLFM.UI.Content.Raids.UpdateRowSizeControls then
            AutoLFM.UI.Content.Raids.UpdateRowSizeControls(oldRaidIndex, false)
        end

        -- Replace the old raid with the new one in selection order
        selectionOrder[1] = raidIndex
    else
        -- No raid was selected before, add the new one
        table.insert(selectionOrder, raidIndex)
    end
end

-----------------------------------------------------------------------------
-- On Raid Unchecked Handler
--   @param raidIndex number: Raid index
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.OnRaidUnchecked(raidIndex)
    if not raidIndex then return end

    -- Remove from selection order in Raids module
    local selectionOrder = {}
    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelectionOrder then
        selectionOrder = AutoLFM.Logic.Content.Raids.GetSelectionOrder()
    end

    for i = 1, table.getn(selectionOrder) do
        if selectionOrder[i] == raidIndex then
            table.remove(selectionOrder, i)
            break
        end
    end
end

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

-----------------------------------------------------------------------------
-- Find Dungeon Checkbox by Index
--   @param dungeonIndex number: Dungeon index
--   @return frame: Checkbox frame or nil
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.FindDungeonCheckbox(dungeonIndex)
    if not dungeonIndex then return nil end

    -- Search through all dungeon checkboxes to find the one with this dungeonIndex
    local i = 1
    while i <= AutoLFM.Core.Constants.MAX_CHECKBOX_SEARCH_ITERATIONS do
        local checkbox = getglobal("AutoLFM_DungeonCheckbox" .. i)
        if not checkbox then break end

        local row = checkbox:GetParent()
        if row and row.dungeonIndex == dungeonIndex then
            return checkbox
        end
        i = i + 1
    end

    return nil
end

-----------------------------------------------------------------------------
-- Find Raid Checkbox by Index
--   @param raidIndex number: Raid index
--   @return frame: Checkbox frame or nil
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.FindRaidCheckbox(raidIndex)
    if not raidIndex then return nil end

    -- Raid checkboxes use simple index (no sorting)
    return getglobal("AutoLFM_RaidCheckbox" .. raidIndex)
end

--=============================================================================
-- SELECTION INFO
--=============================================================================

-----------------------------------------------------------------------------
-- Get Dungeon Selection Count
--   @return number: Number of selected dungeons
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetDungeonSelectionCount()
    local selectionOrder = {}
    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelectionOrder then
        selectionOrder = AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
    end

    return table.getn(selectionOrder)
end

-----------------------------------------------------------------------------
-- Get Raid Selection Count
--   @return number: Number of selected raids
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetRaidSelectionCount()
    local selectionOrder = {}
    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelectionOrder then
        selectionOrder = AutoLFM.Logic.Content.Raids.GetSelectionOrder()
    end

    return table.getn(selectionOrder)
end

-----------------------------------------------------------------------------
-- Get Selection Type
--   @return string: "dungeons", "raids", or "none"
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetSelectionType()
    if AutoLFM.Logic.Selection.GetDungeonSelectionCount() > 0 then
        return "dungeons"
    elseif AutoLFM.Logic.Selection.GetRaidSelectionCount() > 0 then
        return "raids"
    else
        return "none"
    end
end

--=============================================================================
-- CONTENT TYPE AND DATA
--=============================================================================

-----------------------------------------------------------------------------
-- Get Content Type and Selected Data
--   @return string, table: Content type, selected content array
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetContentTypeAndData()
    local selectedRaids = {}
    if AutoLFM.Logic.Content.Raids and AutoLFM.Logic.Content.Raids.GetSelected then
        selectedRaids = AutoLFM.Logic.Content.Raids.GetSelected()
    end

    if table.getn(selectedRaids) > 0 then
        return "raids", selectedRaids
    end

    local selectedDungeons = {}
    if AutoLFM.Logic.Content.Dungeons and AutoLFM.Logic.Content.Dungeons.GetSelected then
        selectedDungeons = AutoLFM.Logic.Content.Dungeons.GetSelected()
    end

    if table.getn(selectedDungeons) > 0 then
        return "dungeons", selectedDungeons
    end

    return "none", {}
end

--=============================================================================
-- ROLES STRING
--=============================================================================

-----------------------------------------------------------------------------
-- Get Roles Formatted String
--   @return string: Formatted roles string (e.g., "Need Tank & Heal")
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.GetRolesString()
    local roles = { tank = false, heal = false, dps = false }
    if AutoLFM.Logic.Roles and AutoLFM.Logic.Roles.GetSelectedRoles then
        roles = AutoLFM.Logic.Roles.GetSelectedRoles()
    end

    local selectedRoles = {}
    local allRoles = {"Tank", "Heal", "DPS"}

    -- Build list of selected roles
    if roles.tank then
        table.insert(selectedRoles, "Tank")
    end
    if roles.heal then
        table.insert(selectedRoles, "Heal")
    end
    if roles.dps then
        table.insert(selectedRoles, "DPS")
    end

    local count = table.getn(selectedRoles)

    if count == 0 then
        return ""
    end

    if count == table.getn(allRoles) then
        return "Need All"
    end

    return "Need " .. table.concat(selectedRoles, " & ")
end

--=============================================================================
-- CLEAR ALL SELECTION
--=============================================================================

-----------------------------------------------------------------------------
-- Clear All Selection (Dungeons, Raids, Quests, Roles, Message)
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.ClearAll()
    -- Use optimized DeselectAll commands (single event per category instead of N events)
    AutoLFM.Core.Maestro.Dispatch("Dungeons.DeselectAll")
    AutoLFM.Core.Maestro.Dispatch("Raids.DeselectAll")
    AutoLFM.Core.Maestro.Dispatch("Quests.DeselectAll")
    AutoLFM.Core.Maestro.Dispatch("Roles.DeselectAll")

    -- Clear custom broadcast message
    -- The UI will update automatically via broadcasts.custom_message_changed event listener
    AutoLFM.Core.Maestro.Dispatch("Broadcasts.SetCustomMessage", "")
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Selection.RegisterCommands()
    -- Clear all command
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "Selection.ClearAll",
        name = "Clear All Selections",
        description = "Clears all selections (dungeons, raids, quests, roles, message)",
        handler = function()
            AutoLFM.Logic.Selection.ClearAll()
            -- Emit a final event after everything is cleared
            AutoLFM.Core.Maestro.Emit("Selection.AllCleared")
        end
    })
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("selection.init", function()
    AutoLFM.Logic.Selection.RegisterCommands()
end, {
    name = "Selection Constraints",
    description = "Register selection constraint management commands"
})
