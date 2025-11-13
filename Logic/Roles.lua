--=============================================================================
-- AutoLFM: Roles
--   Role selection management
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Roles = AutoLFM.Logic.Roles or {}

-----------------------------------------------------------------------------
-- Private State (owned by this module)
-----------------------------------------------------------------------------
local selectedRoles = {
  tank = false,
  heal = false,
  dps = false
}

-----------------------------------------------------------------------------
-- Role configuration
-----------------------------------------------------------------------------
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

-----------------------------------------------------------------------------
-- Register Command Handlers
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.RegisterCommands()
  -- Toggle role command
  AutoLFM.Core.Maestro.RegisterCommand("Roles.Toggle", function(role)
    if not role or not ROLE_CONFIG[role] then return end

    -- Toggle local state
    selectedRoles[role] = not selectedRoles[role]
    local isActive = selectedRoles[role]

    -- Update button background visual
    AutoLFM.Logic.Roles.UpdateRoleButton(ROLE_CONFIG[role].button, isActive)

    -- Update checkbox visual (without triggering OnClick)
    local checkbox = getglobal(ROLE_CONFIG[role].checkbox)
    if checkbox then
      checkbox:SetChecked(isActive)
    end

    AutoLFM.Core.Maestro.EmitEvent("Roles.RoleToggled", role, isActive)
  end)

  -- Deselect all roles command (optimized for bulk operations)
  AutoLFM.Core.Maestro.RegisterCommand("Roles.DeselectAll", function()
    -- Deselect all roles
    for role, config in pairs(ROLE_CONFIG) do
      if selectedRoles[role] then
        selectedRoles[role] = false

        -- Update UI for this role
        AutoLFM.Logic.Roles.UpdateRoleButton(config.button, false)
        local checkbox = getglobal(config.checkbox)
        if checkbox then
          checkbox:SetChecked(false)
        end
      end
    end
  end)
end

-----------------------------------------------------------------------------
-- Update role button visual state
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.UpdateRoleButton(buttonName, isActive)
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

-----------------------------------------------------------------------------
-- Public Getters
-----------------------------------------------------------------------------
function AutoLFM.Logic.Roles.GetSelectedRoles()
  return selectedRoles
end

function AutoLFM.Logic.Roles.HasRoleSelected()
  return selectedRoles.tank or selectedRoles.heal or selectedRoles.dps
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("Roles", "Logic.Roles.RegisterCommands")
