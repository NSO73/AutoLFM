--=============================================================================
-- AutoLFM: Raids
--   Raids selection and size management logic
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Content.Raids = AutoLFM.Logic.Content.Raids or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local selectedRaids = {}
local raidSelectionOrder = {}
local raidSizes = {}

--=============================================================================
-- RAID SIZE MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Get Raid Size Range
--   @param raidIndex number: Raid index
--   @return number, number: Min size, max size
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)
    if not raidIndex then return 10, 10 end

    local raids = AutoLFM.Core.Constants.RAIDS
    if not raids then return 10, 10 end
    if not raids[raidIndex] then return 10, 10 end

    local minSize = raids[raidIndex].sizeMin or 10
    local maxSize = raids[raidIndex].sizeMax or 10

    return minSize, maxSize
end

-----------------------------------------------------------------------------
-- Check if Raid has Variable Size
--   @param raidIndex number: Raid index
--   @return boolean: True if raid has variable size
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.IsRaidVariableSize(raidIndex)
    if not raidIndex then return false end

    local minSize, maxSize = AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)
    return minSize ~= maxSize
end

-----------------------------------------------------------------------------
-- Get Raid Size
--   @param raidIndex number: Raid index
--   @return number: Current raid size
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.GetRaidSize(raidIndex)
    if not raidIndex then return 10 end

    -- Return custom size if set, otherwise return minimum size
    local size = raidSizes[raidIndex]
    if size then return size end

    local minSize, maxSize = AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)
    return minSize
end

-----------------------------------------------------------------------------
-- Get All Raid Sizes
--   @return table: All custom raid sizes
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.GetAllRaidSizes()
    return raidSizes
end

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.RegisterCommands()
    -- Select raid command
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "raids.select",
        name = "Select Raid",
        description = "Selects a raid (only one raid can be selected at a time)",
        handler = function(raidIndex)
            if not raidIndex then return end

            -- Only one raid can be selected at a time
            -- Deselect all other raids before selecting this one
            for i, isSelected in pairs(selectedRaids) do
                if isSelected and i ~= raidIndex then
                    AutoLFM.Core.Maestro.Dispatch("Raids.Deselect", i)
                end
            end

            selectedRaids[raidIndex] = true

            -- Apply selection constraints (mutual exclusion with dungeons)
            if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.OnRaidChecked then
                AutoLFM.Logic.Selection.OnRaidChecked(raidIndex)
            end

            AutoLFM.Core.Maestro.Emit("Raids.SelectionChanged", raidIndex, true)
        end
    })

    -- Deselect raid command
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "Raids.Deselect",
        name = "Deselect Raid",
        description = "Deselects a raid",
        handler = function(raidIndex)
            if not raidIndex then return end

            selectedRaids[raidIndex] = nil

            -- Update selection constraints
            if AutoLFM.Logic.Selection and AutoLFM.Logic.Selection.OnRaidUnchecked then
                AutoLFM.Logic.Selection.OnRaidUnchecked(raidIndex)
            end

            AutoLFM.Core.Maestro.Emit("Raids.SelectionChanged", raidIndex, false)
        end
    })

    -- Set raid size command
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "raids.set_size",
        name = "Set Raid Size",
        description = "Sets the target size for a variable-size raid",
        handler = function(raidIndex, size)
            if not raidIndex then return end
            if not size then return end

            local minSize, maxSize = AutoLFM.Logic.Content.Raids.GetRaidSizeRange(raidIndex)

            -- Clamp size to valid range
            if size < minSize then size = minSize end
            if size > maxSize then size = maxSize end

            raidSizes[raidIndex] = size
            AutoLFM.Core.Maestro.Emit("Raids.SizeChanged", raidIndex, size)
        end
    })

    -- Deselect all raids command (optimized for bulk operations)
    AutoLFM.Core.Maestro.RegisterCommand({
        id = "Raids.DeselectAll",
        name = "Deselect All Raids",
        description = "Deselects all raids at once",
        handler = function()
            -- Clear local state directly (no individual deselect events)
            raidSelectionOrder = {}
            selectedRaids = {}
            raidSizes = {}

            -- Update UI: uncheck all raid checkboxes
            local raids = AutoLFM.Core.Constants.RAIDS
            if raids then
                for i = 1, table.getn(raids) do
                    local checkbox = getglobal("AutoLFM_RaidCheckbox" .. i)
                    if checkbox and checkbox:GetChecked() then
                        AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
                    end
                end
            end

            -- Emit single event for all deselections
            AutoLFM.Core.Maestro.Emit("Raids.AllDeselected")
        end
    })
end

--=============================================================================
-- PUBLIC GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Check if Raid is Selected
--   @param raidIndex number: Raid index
--   @return boolean: Selection state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.IsSelected(raidIndex)
    if not raidIndex then return false end
    return selectedRaids[raidIndex] and true or false
end

-----------------------------------------------------------------------------
-- Get Selected Raids
--   @return table: Array of selected raid data
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.GetSelected()
    local raids = AutoLFM.Core.Constants.RAIDS
    if not raids then return {} end

    local selected = {}
    for i = 1, table.getn(raids) do
        if selectedRaids[i] then
            table.insert(selected, raids[i])
        end
    end

    return selected
end

-----------------------------------------------------------------------------
-- Get Selection Order
--   @return table: Array of raid indices in selection order
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.GetSelectionOrder()
    return raidSelectionOrder
end

--=============================================================================
-- CONTENT MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Load Raids Content
-----------------------------------------------------------------------------
function AutoLFM.Logic.Content.Raids.Load()
    local content = getglobal("AutoLFM_MainFrame_Content")
    if not content then return end

    -- Create UI with current raids
    local raids = AutoLFM.Core.Constants.RAIDS
    if AutoLFM.UI.Content and AutoLFM.UI.Content.Raids and AutoLFM.UI.Content.Raids.Create then
        AutoLFM.UI.Content.Raids.Create(content, raids)
    end

    -- Restore state after UI creation to sync checkboxes
    if AutoLFM.UI.Content and AutoLFM.UI.Content.Raids and AutoLFM.UI.Content.Raids.RestoreState then
        AutoLFM.UI.Content.Raids.RestoreState(raids)
    end
end

--=============================================================================
-- UI HANDLERS
--=============================================================================

-- Create UI namespace for XML callbacks
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Raids = AutoLFM.UI.Content.Raids or {}

local RaidsUI = AutoLFM.UI.Content.Raids
local raidRows = {}
local uiFrame = nil

-----------------------------------------------------------------------------
-- UI Lifecycle
-----------------------------------------------------------------------------
function RaidsUI.OnLoad(self)
    uiFrame = self
    RaidsUI.CreateRaidRows()
end

function RaidsUI.OnShow(self)
    RaidsUI.Refresh()
end

-----------------------------------------------------------------------------
-- UI Creation
-----------------------------------------------------------------------------
function RaidsUI.CreateRaidRows()
    -- Dispatch command to get raid data and create UI rows
    AutoLFM.Core.Maestro.Dispatch("UI.Raids.Create", uiFrame, raidRows)
end

-----------------------------------------------------------------------------
-- Event Handlers
-----------------------------------------------------------------------------
function RaidsUI.OnRaidToggle(row)
    local raidKey = row.raidKey
    if not raidKey then return end

    local checkbox = getglobal(row:GetName().."_Checkbox")
    local isChecked = checkbox:GetChecked() == 1

    -- Show/hide slider based on checkbox state
    local slider = getglobal(row:GetName().."_Slider")
    if slider then
        if isChecked then
            slider:Show()
        else
            slider:Hide()
        end
    end

    -- Dispatch toggle command
    AutoLFM.Core.Maestro.Dispatch("Raid.Toggle", raidKey, isChecked)
end

function RaidsUI.OnRaidEnter(row)
    local raidName = row.raidName
    if not raidName then return end

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(raidName, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

function RaidsUI.OnSizeChanged(row, value)
    local raidKey = row.raidKey
    if not raidKey then return end

    local slider = getglobal(row:GetName().."_Slider")
    if not slider then return end

    -- Update slider text display
    local text = getglobal(slider:GetName().."_Text")
    if text then
        text:SetText("Size: " .. math.floor(value))
    end

    -- Dispatch size change command
    AutoLFM.Core.Maestro.Dispatch("Raid.SetSize", raidKey, math.floor(value))
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function RaidsUI.Refresh()
    -- Request data refresh from Logic layer
    AutoLFM.Core.Maestro.Dispatch("UI.Raids.Refresh", raidRows)
end

function RaidsUI.GetRaidRows()
    return raidRows
end

-----------------------------------------------------------------------------
-- Event Listeners
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.On("Raid.StateChanged", function()
    if uiFrame and uiFrame:IsVisible() then
        RaidsUI.Refresh()
    end
end)

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("raids.init", function()
    AutoLFM.Logic.Content.Raids.RegisterCommands()
end, {
    name = "Raids Commands",
    description = "Register raid selection and size management commands"
})
