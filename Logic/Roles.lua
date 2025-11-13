--=============================================================================
-- AutoLFM: Roles
--   Role selection management (Tank, Heal, DPS)
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Roles = AutoLFM.Logic.Roles or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local selectedRoles = {
    tank = false,
    heal = false,
    dps = false
}

local ROLE_CONFIG = {
    tank = {
        button = "AutoLFM_MainFrame_RoleTank",
        checkbox = "AutoLFM_MainFrame_RoleTankCheckbox"
    },
    heal = {
        button = "AutoLFM_MainFrame_RoleHeal",
        checkbox = "AutoLFM_MainFrame_RoleHealCheckbox"
    },
    dps = {
        button = "AutoLFM_MainFrame_RoleDPS",
        checkbox = "AutoLFM_MainFrame_RoleDPSCheckbox"
    }
}

--=============================================================================
-- COMMANDS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.RegisterCommands()
    -- Toggle role command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Roles.Toggle",
        description = "Toggles a role selection (tank, heal, or dps)",
        handler = function(role)
            if not role or not ROLE_CONFIG[role] then return end

            -- Toggle local state
            selectedRoles[role] = not selectedRoles[role]
            local isActive = selectedRoles[role]

            -- Update button background visual
            AutoLFM.Logic.Roles.UpdateRoleButton(ROLE_CONFIG[role].button, isActive)

            -- Update checkbox visual (without triggering OnClick)
            local checkbox = getglobal(ROLE_CONFIG[role].checkbox)
            if checkbox then
                AutoLFM.Core.Utils.SetCheckboxState(checkbox, isActive)
            end

            AutoLFM.Core.Maestro.Emit("Roles.Toggled", role, isActive)
        end
    })

    -- Deselect all roles command
    AutoLFM.Core.Maestro.RegisterCommand({
        key = "Roles.DeselectAll",
        description = "Deselects all role selections",
        handler = function()
            for role, config in pairs(ROLE_CONFIG) do
                if selectedRoles[role] then
                    selectedRoles[role] = false

                    -- Update UI for this role
                    AutoLFM.Logic.Roles.UpdateRoleButton(config.button, false)
                    local checkbox = getglobal(config.checkbox)
                    if checkbox then
                        AutoLFM.Core.Utils.SetCheckboxState(checkbox, false)
                    end
                end
            end
        end
    })
end

--=============================================================================
-- UI UPDATES
--=============================================================================

-----------------------------------------------------------------------------
-- Update Role Button Visual State
--   @param buttonName string: Button frame name
--   @param isActive boolean: Active state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.UpdateRoleButton(buttonName, isActive)
    if not buttonName then return end

    local button = getglobal(buttonName)
    if not button then return end

    local bg = getglobal(buttonName .. "_Background")
    if not bg then return end

    if isActive then
        bg:SetVertexColor(1, 1, 1, 1)
    else
        bg:SetVertexColor(1, 1, 1, 0.6)
    end
end

--=============================================================================
-- PUBLIC GETTERS
--=============================================================================

-----------------------------------------------------------------------------
-- Get Selected Roles
--   @return table: { tank, heal, dps } with boolean values
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.GetSelectedRoles()
    return selectedRoles
end

-----------------------------------------------------------------------------
-- Check if Any Role is Selected
--   @return boolean: true if at least one role is selected
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.HasRoleSelected()
    return selectedRoles.tank or selectedRoles.heal or selectedRoles.dps
end

-----------------------------------------------------------------------------
-- Get Role Text for Messages
--   Generates text like "Need Tank & Heal", "Need All", etc.
--   @return string: Role text
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.GetRoleText()
    local roles = {}
    if selectedRoles.tank then table.insert(roles, "Tank") end
    if selectedRoles.heal then table.insert(roles, "Heal") end
    if selectedRoles.dps then table.insert(roles, "DPS") end

    local count = table.getn(roles)
    if count == 0 then
        return ""
    elseif count == 3 then
        return "Need All"
    elseif count == 1 then
        return "Need " .. roles[1]
    else
        return "Need " .. table.concat(roles, " & ")
    end
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("roles.init", function()
    AutoLFM.Logic.Roles.RegisterCommands()
end, {
    key = "Roles.Init",
    description = "Register role selection commands"
})
