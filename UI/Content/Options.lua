--=============================================================================
-- AutoLFM: Options Content
--   Options panel UI
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Content = AutoLFM.UI.Content or {}
AutoLFM.UI.Content.Options = AutoLFM.UI.Content.Options or {}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local panel = nil
local filterCheckboxes = {}
local defaultPanelDropdown = nil
local isRestoringState = false  -- Flag to prevent OnClick during restoration

-----------------------------------------------------------------------------
-- Helper: Create Checkbox with Label
-----------------------------------------------------------------------------
local function CreateCheckboxWithLabel(parent, name, label, anchorPoint, anchorX, anchorY)
  local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  checkbox:SetWidth(24)
  checkbox:SetHeight(24)
  checkbox:SetPoint(anchorPoint.point, anchorPoint.relativeTo or parent, anchorPoint.relativePoint or anchorPoint.point, anchorX, anchorY)

  local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)
  text:SetText(label)
  text:SetTextColor(1, 1, 1)

  checkbox.label = text
  return checkbox
end

-----------------------------------------------------------------------------
-- Helper: Create Button
-----------------------------------------------------------------------------
local function CreateButton(parent, name, text, width, anchorPoint, anchorX, anchorY)
  local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(20)
  button:SetPoint(anchorPoint.point, anchorPoint.relativeTo or parent, anchorPoint.relativePoint or anchorPoint.point, anchorX, anchorY)
  button:SetText(text)
  return button
end

-----------------------------------------------------------------------------
-- Helper: Create Section Header
-----------------------------------------------------------------------------
local function CreateSectionHeader(parent, text, anchorPoint, anchorX, anchorY)
  local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  header:SetPoint(anchorPoint.point, anchorPoint.relativeTo or parent, anchorPoint.relativePoint or anchorPoint.point, anchorX, anchorY)
  header:SetText(text)
  AutoLFM.Core.Utils.SetFontColor(header, "gold")
  return header
end

-----------------------------------------------------------------------------
-- Helper: Create Radio Button
-----------------------------------------------------------------------------
local function CreateRadioButton(parent, name, label, anchorPoint, anchorX, anchorY)
  local radio = CreateFrame("CheckButton", name, parent, "UIRadioButtonTemplate")
  radio:SetWidth(16)
  radio:SetHeight(16)
  radio:SetPoint(anchorPoint.point, anchorPoint.relativeTo or parent, anchorPoint.relativePoint or anchorPoint.point, anchorX, anchorY)

  local text = radio:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("LEFT", radio, "RIGHT", 2, 0)
  text:SetText(label)
  text:SetTextColor(1, 1, 1)

  radio.label = text
  return radio
end

-----------------------------------------------------------------------------
-- Dropdown Implementation
-----------------------------------------------------------------------------
local function CreateDropdown(parent, name, items, initialValue, width, anchorPoint, anchorX, anchorY, onChange)
  local dropdown = CreateFrame("Frame", name, parent)
  dropdown:SetWidth(width)
  dropdown:SetHeight(24)
  dropdown:SetPoint(anchorPoint.point, anchorPoint.relativeTo or parent, anchorPoint.relativePoint or anchorPoint.point, anchorX, anchorY)

  -- Background
  local bg = dropdown:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetTexture(0, 0, 0, 0.5)

  -- Border
  local border = dropdown:CreateTexture(nil, "BORDER")
  border:SetTexture(0.4, 0.4, 0.4, 1)
  border:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
  border:SetPoint("BOTTOMRIGHT", dropdown, "TOPRIGHT", 0, -1)

  local borderBottom = dropdown:CreateTexture(nil, "BORDER")
  borderBottom:SetTexture(0.4, 0.4, 0.4, 1)
  borderBottom:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, 1)
  borderBottom:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)

  local borderLeft = dropdown:CreateTexture(nil, "BORDER")
  borderLeft:SetTexture(0.4, 0.4, 0.4, 1)
  borderLeft:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
  borderLeft:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMLEFT", 1, 0)

  local borderRight = dropdown:CreateTexture(nil, "BORDER")
  borderRight:SetTexture(0.4, 0.4, 0.4, 1)
  borderRight:SetPoint("TOPLEFT", dropdown, "TOPRIGHT", -1, 0)
  borderRight:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)

  -- Text
  local text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
  text:SetText(initialValue or items[1])
  text:SetTextColor(1, 1, 1)

  -- Arrow
  local arrow = dropdown:CreateTexture(nil, "OVERLAY")
  arrow:SetWidth(12)
  arrow:SetHeight(12)
  arrow:SetPoint("RIGHT", dropdown, "RIGHT", -6, 0)
  arrow:SetTexture(AutoLFM.Core.Constants.TEXTURE_PATH .. "Icons\\down")

  -- Click to expand
  local button = CreateFrame("Button", name.."_Button", dropdown)
  button:SetAllPoints()
  button:SetScript("OnClick", function()
    -- Create menu
    local menu = CreateFrame("Frame", name.."_Menu", UIParent)
    menu:SetWidth(width)
    menu:SetHeight(24 * table.getn(items))
    menu:SetPoint("TOP", dropdown, "BOTTOM", 0, 0)
    menu:SetFrameStrata("DIALOG")

    local menuBg = menu:CreateTexture(nil, "BACKGROUND")
    menuBg:SetAllPoints()
    menuBg:SetTexture(0.1, 0.1, 0.1, 0.95)

    -- Menu border
    local menuBorder = menu:CreateTexture(nil, "BORDER")
    menuBorder:SetTexture(0.5, 0.5, 0.5, 1)
    menuBorder:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 1)
    menuBorder:SetPoint("BOTTOMRIGHT", menu, "TOPRIGHT", 0, 0)

    for i = 1, table.getn(items) do
      local item = items[i]
      local itemBtn = CreateFrame("Button", name.."_MenuItem"..i, menu)
      itemBtn:SetWidth(width)
      itemBtn:SetHeight(24)
      itemBtn:SetPoint("TOP", menu, "TOP", 0, -(i-1) * 24)

      local itemBg = itemBtn:CreateTexture(nil, "BACKGROUND")
      itemBg:SetAllPoints()
      itemBg:SetTexture(0, 0, 0, 0)

      local itemText = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      itemText:SetPoint("LEFT", itemBtn, "LEFT", 8, 0)
      itemText:SetText(item)
      itemText:SetTextColor(1, 1, 1)

      itemBtn:SetScript("OnEnter", function()
        itemBg:SetTexture(0.3, 0.3, 0.3, 0.8)
      end)

      itemBtn:SetScript("OnLeave", function()
        itemBg:SetTexture(0, 0, 0, 0)
      end)

      itemBtn:SetScript("OnClick", function()
        text:SetText(item)
        menu:Hide()
        if onChange then
          onChange(item)
        end
      end)
    end

    -- Close menu on outside click
    menu:SetScript("OnHide", function()
      this:SetParent(nil)
    end)

    menu:SetScript("OnUpdate", function()
      if not MouseIsOver(this) and not MouseIsOver(dropdown) then
        this:Hide()
      end
    end)

    menu:Show()
  end)

  dropdown.SetValue = function(self, value)
    text:SetText(value)
  end

  dropdown.GetValue = function(self)
    return text:GetText()
  end

  return dropdown
end

-----------------------------------------------------------------------------
-- Panel creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Options.Create(parent)
  if not parent then return nil end

  parent:SetHeight(AutoLFM.Core.Constants.CONTENT_DEFAULT_HEIGHT)

  -- Check if panel already exists (to preserve dropdown state)
  local existingPanel = getglobal("AutoLFM_Panel_Options")
  if existingPanel and existingPanel:GetParent() == parent then
    -- Panel already exists and is in the right parent, just restore state
    panel = existingPanel
    panel:Show()
    return panel
  end

  -- Clean up old panel if it exists but has wrong parent
  if existingPanel then
    existingPanel:Hide()
    existingPanel:SetParent(nil)
  end

  panel = CreateFrame("Frame", "AutoLFM_Panel_Options", parent)
  panel:SetAllPoints()

  local currentY = -10

  -- Dungeon Filters Section (header + checkboxes on same line)
  local filtersContainer = CreateFrame("Frame", nil, panel)
  filtersContainer:SetWidth(320)
  filtersContainer:SetHeight(24)
  filtersContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, currentY)

  -- Header text
  local filtersHeader = filtersContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  filtersHeader:SetPoint("LEFT", filtersContainer, "LEFT", 0, 0)
  filtersHeader:SetText("- Dungeon filters:")
  AutoLFM.Core.Utils.SetFontColor(filtersHeader, "gold")

  -- 5 filter checkboxes in a horizontal row (Gray - Green - Yellow - Orange - Red)
  local filterData = {
    {id = "GRAY", color = AutoLFM.Core.Constants.COLORS.GRAY},
    {id = "GREEN", color = AutoLFM.Core.Constants.COLORS.GREEN},
    {id = "YELLOW", color = AutoLFM.Core.Constants.COLORS.YELLOW},
    {id = "ORANGE", color = AutoLFM.Core.Constants.COLORS.ORANGE},
    {id = "RED", color = AutoLFM.Core.Constants.COLORS.RED}
  }

  for i = 1, table.getn(filterData) do
    local filter = filterData[i]
    local checkbox = CreateFrame("CheckButton", "AutoLFM_Options_Filter_"..filter.id, filtersContainer, "UICheckButtonTemplate")
    checkbox:SetWidth(20)
    checkbox:SetHeight(20)
    -- Position after the header text with spacing
    checkbox:SetPoint("LEFT", filtersHeader, "RIGHT", 8 + (i - 1) * 30, 0)

    -- Tint the checkbox textures with the color
    local normalTex = checkbox:GetNormalTexture()
    local checkedTex = checkbox:GetCheckedTexture()
    local disabledCheckedTex = checkbox:GetDisabledCheckedTexture()

    if normalTex then
      normalTex:SetVertexColor(filter.color.r, filter.color.g, filter.color.b)
    end
    if checkedTex then
      checkedTex:SetVertexColor(filter.color.r, filter.color.g, filter.color.b)
    end
    if disabledCheckedTex then
      disabledCheckedTex:SetVertexColor(filter.color.r, filter.color.g, filter.color.b)
    end

    checkbox:SetScript("OnClick", function()
      if isRestoringState then return end
      AutoLFM.Core.Maestro.DispatchCommand("Options.ToggleDungeonFilter", filter.id)
    end)

    filterCheckboxes[filter.id] = checkbox
  end

  currentY = currentY - 30

  -- Minimap Button Section (header + radio buttons + reset button on same line)
  local minimapContainer = CreateFrame("Frame", nil, panel)
  minimapContainer:SetWidth(320)
  minimapContainer:SetHeight(24)
  minimapContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, currentY)

  -- Header text
  local minimapHeader = minimapContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  minimapHeader:SetPoint("LEFT", minimapContainer, "LEFT", 0, 0)
  minimapHeader:SetText("- Minimap button:")
  minimapHeader:SetWidth(100)
  minimapHeader:SetJustifyH("LEFT")
  AutoLFM.Core.Utils.SetFontColor(minimapHeader, "gold")

  -- Show radio button
  local minimapShowRadio = CreateRadioButton(
    minimapContainer,
    "AutoLFM_Options_MinimapShow",
    "Show",
    {point = "LEFT", relativeTo = minimapHeader, relativePoint = "RIGHT"},
    5,
    0
  )
  minimapShowRadio.label:SetWidth(32)
  minimapShowRadio.label:SetJustifyH("LEFT")

  -- Hide radio button
  local minimapHideRadio = CreateRadioButton(
    minimapContainer,
    "AutoLFM_Options_MinimapHide",
    "Hide",
    {point = "LEFT", relativeTo = minimapShowRadio.label, relativePoint = "RIGHT"},
    2,
    0
  )
  minimapHideRadio.label:SetWidth(32)
  minimapHideRadio.label:SetJustifyH("LEFT")

  -- Radio button behavior (mutual exclusion)
  minimapShowRadio:SetScript("OnClick", function()
    if isRestoringState then return end  -- Don't trigger during state restoration
    minimapShowRadio:SetChecked(true)
    minimapHideRadio:SetChecked(false)
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetMinimapVisible", true)
  end)

  minimapHideRadio:SetScript("OnClick", function()
    if isRestoringState then return end  -- Don't trigger during state restoration
    minimapShowRadio:SetChecked(false)
    minimapHideRadio:SetChecked(true)
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetMinimapVisible", false)
  end)

  -- Reset button
  local minimapResetBtn = CreateButton(
    minimapContainer,
    "AutoLFM_Options_MinimapReset",
    "Reset",
    60,
    {point = "LEFT", relativeTo = minimapHideRadio.label, relativePoint = "RIGHT"},
    12,
    0
  )

  minimapResetBtn:SetScript("OnClick", function()
    AutoLFM.Core.Maestro.DispatchCommand("Minimap.ResetPosition")
    AutoLFM.Core.Utils.PrintSuccess("Minimap button position reset")
  end)

  currentY = currentY - 30

  -- DarkUI Section (header + radio buttons + reload button on same line)
  local darkUIContainer = CreateFrame("Frame", nil, panel)
  darkUIContainer:SetWidth(320)
  darkUIContainer:SetHeight(24)
  darkUIContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, currentY)

  -- Header text
  local darkUIHeader = darkUIContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  darkUIHeader:SetPoint("LEFT", darkUIContainer, "LEFT", 0, 0)
  darkUIHeader:SetText("- DarkUI (Shagu):")
  darkUIHeader:SetWidth(100)
  darkUIHeader:SetJustifyH("LEFT")
  AutoLFM.Core.Utils.SetFontColor(darkUIHeader, "gold")

  -- On radio button
  local darkUIOnRadio = CreateRadioButton(
    darkUIContainer,
    "AutoLFM_Options_DarkUIOn",
    "On",
    {point = "LEFT", relativeTo = darkUIHeader, relativePoint = "RIGHT"},
    5,
    0
  )
  darkUIOnRadio.label:SetWidth(32)
  darkUIOnRadio.label:SetJustifyH("LEFT")

  -- Off radio button
  local darkUIOffRadio = CreateRadioButton(
    darkUIContainer,
    "AutoLFM_Options_DarkUIOff",
    "Off",
    {point = "LEFT", relativeTo = darkUIOnRadio.label, relativePoint = "RIGHT"},
    2,
    0
  )
  darkUIOffRadio.label:SetWidth(32)
  darkUIOffRadio.label:SetJustifyH("LEFT")

  -- Radio button behavior (mutual exclusion)
  darkUIOnRadio:SetScript("OnClick", function()
    if isRestoringState then return end
    darkUIOnRadio:SetChecked(true)
    darkUIOffRadio:SetChecked(false)
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetDarkMode", true)
  end)

  darkUIOffRadio:SetScript("OnClick", function()
    if isRestoringState then return end
    darkUIOnRadio:SetChecked(false)
    darkUIOffRadio:SetChecked(true)
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetDarkMode", false)
  end)

  -- Reload button
  local darkUIReloadBtn = CreateButton(
    darkUIContainer,
    "AutoLFM_Options_DarkUIReload",
    "Reload",
    60,
    {point = "LEFT", relativeTo = darkUIOffRadio.label, relativePoint = "RIGHT"},
    12,
    0
  )

  darkUIReloadBtn:SetScript("OnClick", function()
    ReloadUI()
  end)

  currentY = currentY - 30

  -- Presets View Section (header + radio buttons on same line)
  local presetsContainer = CreateFrame("Frame", nil, panel)
  presetsContainer:SetWidth(320)
  presetsContainer:SetHeight(24)
  presetsContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, currentY)

  -- Header text
  local presetsHeader = presetsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  presetsHeader:SetPoint("LEFT", presetsContainer, "LEFT", 0, 0)
  presetsHeader:SetText("- Presets display:")
  presetsHeader:SetWidth(100)
  presetsHeader:SetJustifyH("LEFT")
  AutoLFM.Core.Utils.SetFontColor(presetsHeader, "gold")

  -- Full radio button
  local presetsFullRadio = CreateRadioButton(
    presetsContainer,
    "AutoLFM_Options_PresetsFull",
    "Full",
    {point = "LEFT", relativeTo = presetsHeader, relativePoint = "RIGHT"},
    5,
    0
  )
  presetsFullRadio.label:SetWidth(32)
  presetsFullRadio.label:SetJustifyH("LEFT")

  -- Condensed radio button
  local presetsCondRadio = CreateRadioButton(
    presetsContainer,
    "AutoLFM_Options_PresetsCond",
    "Condensed",
    {point = "LEFT", relativeTo = presetsFullRadio.label, relativePoint = "RIGHT"},
    2,
    0
  )
  presetsCondRadio.label:SetJustifyH("LEFT")

  -- Radio button behavior (mutual exclusion)
  presetsFullRadio:SetScript("OnClick", function()
    if isRestoringState then return end
    presetsFullRadio:SetChecked(true)
    presetsCondRadio:SetChecked(false)
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetPresetsCondensed", false)
  end)

  presetsCondRadio:SetScript("OnClick", function()
    if isRestoringState then return end
    presetsFullRadio:SetChecked(false)
    presetsCondRadio:SetChecked(true)
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetPresetsCondensed", true)
  end)

  currentY = currentY - 30

  -- Default Panel Container
  local defaultPanelContainer = CreateFrame("Frame", nil, panel)
  defaultPanelContainer:SetWidth(320)
  defaultPanelContainer:SetHeight(24)
  defaultPanelContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, currentY)

  -- Header text
  local defaultPanelHeader = defaultPanelContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  defaultPanelHeader:SetPoint("LEFT", defaultPanelContainer, "LEFT", 0, 0)
  defaultPanelHeader:SetText("- Default panel:")
  defaultPanelHeader:SetWidth(100)
  defaultPanelHeader:SetJustifyH("LEFT")
  AutoLFM.Core.Utils.SetFontColor(defaultPanelHeader, "gold")

  -- Native WoW dropdown
  defaultPanelDropdown = CreateFrame("Frame", "AutoLFM_Options_DefaultPanelDropdown", defaultPanelContainer, "UIDropDownMenuTemplate")
  defaultPanelDropdown:SetPoint("LEFT", defaultPanelHeader, "RIGHT", -15, -2)
  UIDropDownMenu_SetWidth(120, defaultPanelDropdown)

  -- Dropdown initialization function
  UIDropDownMenu_Initialize(defaultPanelDropdown, function(self)
    local items = {"Dungeons", "Raids", "Quests", "Broadcasts", "Presets"}
    for i = 1, table.getn(items) do
      local itemName = items[i]
      local info = {}
      info.text = itemName
      info.value = itemName
      info.func = function()
        UIDropDownMenu_SetSelectedValue(defaultPanelDropdown, itemName)
        -- Manually update button text
        local button = getglobal(defaultPanelDropdown:GetName() .. "Button")
        if button then
          local buttonText = getglobal(button:GetName() .. "NormalText")
          if buttonText then
            buttonText:SetText(itemName)
          end
        end
        -- Convert display name to internal name (lowercase)
        local internalName = string.lower(itemName)
        AutoLFM.Core.Maestro.DispatchCommand("Options.SetDefaultPanel", internalName)
      end
      info.checked = nil
      UIDropDownMenu_AddButton(info)
    end
  end)

  -- Set initial value from saved settings
  local savedDefaultPanel = AutoLFM.Core.Persistent.GetDefaultPanel()
  local initialDisplayName = "Dungeons"
  if savedDefaultPanel then
    initialDisplayName = string.upper(string.sub(savedDefaultPanel, 1, 1)) .. string.sub(savedDefaultPanel, 2)
  end
  UIDropDownMenu_SetSelectedValue(defaultPanelDropdown, initialDisplayName)
  -- Manually set button text
  local button = getglobal(defaultPanelDropdown:GetName() .. "Button")
  if button then
    local buttonText = getglobal(button:GetName() .. "NormalText")
    if buttonText then
      buttonText:SetText(initialDisplayName)
    end
  end

  currentY = currentY - 28

  -- Bottom Section: Dry run & Debug
  local separator = panel:CreateTexture(nil, "ARTWORK")
  separator:SetTexture(0.3, 0.3, 0.3, 0.8)
  separator:SetHeight(1)
  separator:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 5, 35)
  separator:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 35)

  local testModeCheckbox = CreateCheckboxWithLabel(
    panel,
    "AutoLFM_Options_TestMode",
    "Dry run (simulated broadcast)",
    {point = "BOTTOMLEFT", relativeTo = panel, relativePoint = "BOTTOMLEFT"},
    10,
    10
  )

  testModeCheckbox:SetScript("OnClick", function()
    local isChecked = this:GetChecked()
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetTestMode", isChecked)
    if isChecked then
      AutoLFM.Core.Utils.PrintWarning("Dry run enabled")
    else
      AutoLFM.Core.Utils.PrintInfo("Dry run disabled")
    end
  end)

  local debugModeCheckbox = CreateCheckboxWithLabel(
    panel,
    "AutoLFM_Options_DebugMode",
    "Debug",
    {point = "LEFT", relativeTo = testModeCheckbox.label, relativePoint = "RIGHT"},
    30,
    0
  )

  debugModeCheckbox:SetScript("OnClick", function()
    local isChecked = this:GetChecked()
    AutoLFM.Core.Maestro.DispatchCommand("Options.SetDebugMode", isChecked)
    -- Event Monitor is now auto-started/stopped by the command itself
    if isChecked then
      AutoLFM.Core.Utils.PrintWarning("Debug mode enabled (Command + Event logging)")
    else
      AutoLFM.Core.Utils.PrintInfo("Debug mode disabled")
    end
  end)

  -- Store references for restoration
  panel.minimapShowRadio = minimapShowRadio
  panel.minimapHideRadio = minimapHideRadio
  panel.darkUIOnRadio = darkUIOnRadio
  panel.darkUIOffRadio = darkUIOffRadio
  panel.presetsFullRadio = presetsFullRadio
  panel.presetsCondRadio = presetsCondRadio
  panel.testModeCheckbox = testModeCheckbox
  panel.debugModeCheckbox = debugModeCheckbox
  panel.filterCheckboxes = filterCheckboxes
  panel.defaultPanelDropdown = defaultPanelDropdown

  -- Register event listener for filter changes
  AutoLFM.Core.Maestro.RegisterEventListener("Dungeons.FilterChanged", function(colorId, enabled)
    if panel.filterCheckboxes and panel.filterCheckboxes[colorId] then
      isRestoringState = true
      panel.filterCheckboxes[colorId]:SetChecked(enabled and 1 or nil)
      isRestoringState = false
    end
  end, "Update filter checkbox state in Options UI")

  return panel
end

-----------------------------------------------------------------------------
-- Restore State
-----------------------------------------------------------------------------
function AutoLFM.UI.Content.Options.RestoreState()
  if not panel then return end

  isRestoringState = true  -- Prevent OnClick handlers from firing

  -- Restore filter checkboxes
  local filters = AutoLFM.Logic.Content.Options.GetDungeonFilters()
  for filterId, checkbox in pairs(panel.filterCheckboxes) do
    local isEnabled = filters[filterId]
    if isEnabled == nil then
      isEnabled = true  -- Default to enabled
    end
    checkbox:SetChecked(isEnabled and 1 or nil)
  end

  -- Restore minimap radio buttons (flag prevents OnClick from triggering)
  local isMinimapVisible = AutoLFM.Logic.Content.Options.GetMinimapVisible()
  if isMinimapVisible then
    panel.minimapShowRadio:SetChecked(true)
    panel.minimapHideRadio:SetChecked(false)
  else
    panel.minimapShowRadio:SetChecked(false)
    panel.minimapHideRadio:SetChecked(true)
  end

  -- Restore dark UI radio buttons (flag prevents OnClick from triggering)
  local darkMode = AutoLFM.Logic.Content.Options.GetDarkUI()
  if darkMode then
    panel.darkUIOnRadio:SetChecked(true)
    panel.darkUIOffRadio:SetChecked(false)
  else
    panel.darkUIOnRadio:SetChecked(false)
    panel.darkUIOffRadio:SetChecked(true)
  end

  -- Restore presets radio buttons (flag prevents OnClick from triggering)
  local presetsCondensed = AutoLFM.Logic.Content.Options.GetPresetsCondensed()
  if presetsCondensed then
    panel.presetsFullRadio:SetChecked(false)
    panel.presetsCondRadio:SetChecked(true)
  else
    panel.presetsFullRadio:SetChecked(true)
    panel.presetsCondRadio:SetChecked(false)
  end

  -- Restore default panel dropdown (if it exists, which it should since panel is now persistent)
  if defaultPanelDropdown and AutoLFM.Core.Persistent.GetDefaultPanel then
    local defaultPanel = AutoLFM.Core.Persistent.GetDefaultPanel()
    if defaultPanel then
      local displayName = string.upper(string.sub(defaultPanel, 1, 1)) .. string.sub(defaultPanel, 2)
      UIDropDownMenu_SetSelectedValue(defaultPanelDropdown, displayName)

      -- Manually update button text
      local button = getglobal(defaultPanelDropdown:GetName() .. "Button")
      if button then
        local buttonText = getglobal(button:GetName() .. "NormalText")
        if buttonText then
          buttonText:SetText(displayName)
        end
      end
    end
  end

  -- Restore dry run
  local testMode = AutoLFM.Logic.Content.Options.GetTestMode()
  panel.testModeCheckbox:SetChecked(testMode)

  -- Restore debug
  local debugMode = AutoLFM.Logic.Content.Options.GetDebugMode()
  panel.debugModeCheckbox:SetChecked(debugMode)

  isRestoringState = false  -- Re-enable OnClick handlers
end
