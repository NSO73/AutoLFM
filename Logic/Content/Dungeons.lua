--=============================================================================
-- AutoLFM: Dungeons
--   Dungeons selection and filtering logic
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content = AutoLFM.Logic.Content or {}
AutoLFM.Logic.Content.Dungeons = AutoLFM.Logic.Content.Dungeons or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local selectedDungeons = {}
local dungeonSelectionOrder = {}

--=============================================================================
-- DUNGEON COLOR CALCULATION
--=============================================================================

-----------------------------------------------------------------------------
-- Get Dungeon Color Based on Player Level
--   @param dungeon table: Dungeon data
--   @param playerLevel number: Player level
--   @return table: Color data
-----------------------------------------------------------------------------
local function GetDungeonColor(dungeon, playerLevel)
    if not dungeon then return AutoLFM.Core.Constants.COLORS.GRAY end
    if not dungeon.levelMin then return AutoLFM.Core.Constants.COLORS.GRAY end
    if not playerLevel then return AutoLFM.Core.Constants.COLORS.GRAY end

    local priority = AutoLFM.Core.Utils.CalculateLevelPriority(playerLevel, dungeon.levelMin, dungeon.levelMax)
    return AutoLFM.Core.Utils.GetColor(priority)
end

--=============================================================================
-- SORTING AND FILTERING
--=============================================================================

-----------------------------------------------------------------------------
-- Get Sorted Dungeons by Color Priority and Level
--   @return table: Array of sorted dungeon entries
-----------------------------------------------------------------------------
local function GetSortedDungeons()
    local playerLevel = UnitLevel("player") or 1
    local dungeons = AutoLFM.Core.Constants.DUNGEONS
    if not dungeons then return {} end

    local sorted = {}
    local filters = AutoLFM.Core.Persistent.GetDungeonFilters()
    if not filters then return {} end

    for i = 1, table.getn(dungeons) do
        local dungeon = dungeons[i]
        if dungeon then
            local color = GetDungeonColor(dungeon, playerLevel)

            -- Use color.name to check filter state
            if filters[color.name] then
                table.insert(sorted, {
                    index = i,
                    dungeon = dungeon,
                    color = color
                })
            end
        end
    end

    -- Sort by color priority (green first, then yellow, orange, red, gray)
    table.sort(sorted, function(a, b)
        if a.color.priority ~= b.color.priority then
            return a.color.priority < b.color.priority
        end
        return a.dungeon.levelMin < b.dungeon.levelMin
    end)

    return sorted
end

--=============================================================================
-- FILTER MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Get Filter State for Color
--   @param colorId string: Color identifier
--   @return boolean: Filter state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.GetFilterState(colorId)
    if not colorId then return false end

    local filters = AutoLFM.Core.Persistent.GetDungeonFilters()
    if not filters then return false end

    return filters[colorId] or false
end

-----------------------------------------------------------------------------
-- Get All Filters
--   @return table: All filter states
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.GetAllFilters()
    return AutoLFM.Core.Persistent.GetDungeonFilters()
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.RegisterCommands()
    -- Select dungeon command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Dungeons.Select",
        description = "Selects a dungeon and applies selection constraints",
        handler = function(dungeonIndex)
            if not dungeonIndex then return end

            selectedDungeons[dungeonIndex] = true

            -- Apply selection constraints (mutual exclusion with raids, max dungeons)
            if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.OnDungeonChecked then
                AutoLFM.Logic.Selection.OnDungeonChecked(dungeonIndex)
            end

            AutoLFM.Core.Maestro.Emit("Dungeons.SelectionChanged", dungeonIndex, true)
        end
    })

    -- Deselect dungeon command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Dungeons.Deselect",
        description = "Deselects a dungeon",
        handler = function(dungeonIndex)
            if not dungeonIndex then return end

            selectedDungeons[dungeonIndex] = nil

            -- Update selection constraints
            if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.OnDungeonUnchecked then
                AutoLFM.Logic.Selection.OnDungeonUnchecked(dungeonIndex)
            end

            AutoLFM.Core.Maestro.Emit("Dungeons.SelectionChanged", dungeonIndex, false)
        end
    })

    -- Deselect all dungeons command (optimized for bulk operations)
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Dungeons.DeselectAll",
        description = "Deselects all dungeons at once",
        handler = function()
            -- Clear local state directly (no individual deselect events)
            dungeonSelectionOrder = {}
            selectedDungeons = {}

            -- Update UI: uncheck all dungeon checkboxes
            local i = 1
            while i <= AutoLFM.Core.Constants.MAX_CHECKBOX_SEARCH_ITERATIONS do
                local checkbox = getglobal("AutoLFM_DungeonCheckbox" .. i)
                if not checkbox then break end
                if checkbox:GetChecked() then
                    AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
                end
                i = i + 1
            end

            -- Emit single event for all deselections
            AutoLFM.Core.Maestro.Emit("Dungeons.AllDeselected")
        end
    })

    -- Register event listener for filter changes
    AutoLFM.Core.Maestro.On("Dungeons.FilterChanged", function(colorId, enabled)
        -- Refresh dungeons display ONLY if currently on the Dungeons tab
        if AutoLFM.Core.Maestro.currentTab and AutoLFM.Core.Maestro.currentTab.bottomTab == "dungeons" then
            if AutoLFM.UI.Content and AutoLFM.UI.Content.Dungeons and AutoLFM.UI.Content.Dungeons.UpdateVisibility then
                local sorted = GetSortedDungeons()
                AutoLFM.UI.Content.Dungeons.UpdateVisibility(sorted)
            end
        end
    end, {
        name = "Refresh Dungeon List Visibility",
        description = "Updates dungeon list visibility when filters change"
    })
end

--=============================================================================
-- PUBLIC GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Check if Dungeon is Selected
--   @param dungeonIndex number: Dungeon index
--   @return boolean: Selection state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.IsSelected(dungeonIndex)
    if not dungeonIndex then return false end
    return selectedDungeons[dungeonIndex] and true or false
end

-----------------------------------------------------------------------------
-- Get Selected Dungeons
--   @return table: Array of selected dungeon data
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.GetSelected()
    local sorted = GetSortedDungeons()
    local selected = {}

    for i = 1, table.getn(sorted) do
        if selectedDungeons[sorted[i].index] then
            table.insert(selected, sorted[i].dungeon)
        end
    end

    return selected
end

-----------------------------------------------------------------------------
-- Get Selection Order
--   @return table: Array of dungeon indices in selection order
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.GetSelectionOrder()
    return dungeonSelectionOrder
end

-----------------------------------------------------------------------------
-- Get Sorted Dungeons
--   @return table: Array of sorted dungeon entries with color data
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.GetSortedDungeons()
    return GetSortedDungeons()
end

--=============================================================================
-- CONTENT MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Load Dungeons Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.Load()
    local content = getglobal("AutoLFM_MainFrame_Content")
    if not content then return end

    -- Create UI with sorted dungeons
    local sorted = GetSortedDungeons()
    if AutoLFM.UI.Content and AutoLFM.UI.Content.Dungeons and AutoLFM.UI.Content.Dungeons.Create then
        AutoLFM.UI.Content.Dungeons.Create(content, sorted)
    end
end

-----------------------------------------------------------------------------
-- Refresh Dungeons Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Dungeons.Refresh()
    AutoLFM.Logic.Content.Dungeons.Load()
end

--=============================================================================
-- UI HANDLERS
--=============================================================================

-- Create UI namespace for XML callbacks
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Dungeons = AutoLFM.UI.Content.Dungeons or {}

local DungeonsUI = AutoLFM.UI.Content.Dungeons
local checkboxes = {}
local uiFrame = nil

-----------------------------------------------------------------------------
-- UI Lifecycle
-----------------------------------------------------------------------------
function DungeonsUI.OnLoad(self)
    uiFrame = self
    DungeonsUI.CreateCheckboxes()
end

function DungeonsUI.OnShow(self)
    DungeonsUI.Refresh()
end

-----------------------------------------------------------------------------
-- UI Creation
-----------------------------------------------------------------------------
function DungeonsUI.CreateCheckboxes()
    -- Dispatch command to get dungeon data and create checkboxes
    AutoLFM.Core.Maestro.Dispatch("UI.Dungeons.Create", uiFrame, checkboxes)
end

-----------------------------------------------------------------------------
-- Event Handlers
-----------------------------------------------------------------------------
function DungeonsUI.OnDungeonToggle(checkbox)
    local dungeonKey = checkbox.dungeonKey
    if not dungeonKey then return end

    -- Dispatch toggle command
    AutoLFM.Core.Maestro.Dispatch("Dungeon.Toggle", dungeonKey, checkbox:GetChecked() == 1)
end

function DungeonsUI.OnDungeonEnter(checkbox)
    local dungeonName = checkbox.dungeonName
    if not dungeonName then return end

    GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
    GameTooltip:SetText(dungeonName, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function DungeonsUI.Refresh()
    -- Request data refresh from Logic layer
    AutoLFM.Core.Maestro.Dispatch("UI.Dungeons.Refresh", checkboxes)
end

function DungeonsUI.GetCheckboxes()
    return checkboxes
end

-----------------------------------------------------------------------------
-- Event Listeners
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.On("Dungeons.StateChanged", function()
    if uiFrame and uiFrame:IsVisible() then
        DungeonsUI.Refresh()
    end
end, {
    key = "DungeonsUI.Refresh",
    description = "Refreshes dungeons UI when state changes"
})

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("dungeons.init", function()
    AutoLFM.Logic.Content.Dungeons.RegisterCommands()
end, {
    name = "Dungeons Commands",
    description = "Register dungeon selection and filtering commands"
})
