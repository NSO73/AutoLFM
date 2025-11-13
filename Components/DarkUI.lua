--=============================================================================
-- AutoLFM: Dark UI
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Components = AutoLFM.Components or {}
AutoLFM.Components.DarkUI = AutoLFM.Components.DarkUI or {}

-----------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------
local COLOR_PRESETS = {
  yellow = {r = 1, g = 1, b = 0},
  gold = {r = 1, g = 0.82, b = 0},
  white = {r = 1, g = 1, b = 1},
  green = {r = 0.25, g = 0.75, b = 0.25},
  red = {r = 1, g = 0, b = 0},
  orange = {r = 1, g = 0.5, b = 0.25},
  gray = {r = 0.5, g = 0.5, b = 0.5},
  blue = {r = 0.3, g = 0.6, b = 1},
  disabled = {r = 0.5, g = 0.5, b = 0.5},
  dark = {r = 0.3, g = 0.3, b = 0.3, a = 0.9}
}

local TEXTURES = {
  TOOLTIP_BACKGROUND = "tooltipBackground",
  TOOLTIP_BORDER = "tooltipBorder",
  SLIDER_BUTTON = "sliderButtonHorizontal",
  SLIDER_BACKGROUND = "sliderBackground",
  SLIDER_BACKGROUND_LIGHT = "sliderBackgroundLight",
  SLIDER_BORDER = "sliderBorder",
  WHITE = "white",
  BUTTON_ROTATION_LEFT = "Icons\\buttonRotationLeft",
  BUTTON_HIGHLIGHT = "Icons\\buttonHighlight"
}

local DARKUI_BLACKLIST = {
  ["Eyes\\"] = true,
  ["preview"] = true,
  ["rolesTank"] = true,
  ["rolesHeal"] = true,
  ["rolesDps"] = true,
  ["clearAll"] = true,
  ["presets"] = true,
  ["addPreset"] = true,
  ["autoInvite"] = true,
  ["options"] = true,
  ["minimap"] = true,
  ["tooltipBackground"] = true,
  ["Button"] = true,
  ["Check"] = true,
  ["Radio"] = true,
  ["Icon"] = true
}

local DARKUI_WHITELIST = {
  ["mainFrame"] = true,
  ["minimapBorder"] = true,
  ["tabActive"] = true
}

local TEXTURE_PATH = "Interface\\AddOns\\AutoLFM3\\UI\\Textures\\"

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local enabled = false
local darkenedFrames = {}

-----------------------------------------------------------------------------
-- Texture Filtering
-----------------------------------------------------------------------------
local function IsWhitelisted(texturePath)
  if not texturePath then return false end

  for pattern in pairs(DARKUI_WHITELIST) do
    if string.find(texturePath, pattern) then return true end
  end
  return false
end

local function IsBlacklisted(texture)
  if not texture then return true end

  local name = texture:GetName()
  local texturePath = texture:GetTexture()
  if not texturePath then return true end
  if IsWhitelisted(texturePath) then return false end

  if name then
    for pattern in pairs(DARKUI_BLACKLIST) do
      if string.find(name, pattern) then return true end
    end
  end

  for pattern in pairs(DARKUI_BLACKLIST) do
    if string.find(texturePath, pattern) then return true end
  end

  return false
end

local function IsSliderBackdrop(backdrop)
  if not backdrop then return false end
  return backdrop.edgeSize == 8 and backdrop.tileSize == 8
end

-----------------------------------------------------------------------------
-- Frame Processing
-----------------------------------------------------------------------------
local function ProcessBackdropColor(frame)
  if not frame or not frame.SetBackdropColor or not frame.GetBackdrop then return end

  local backdrop = frame:GetBackdrop()
  if not backdrop then return end

  local r, g, b, a = frame:GetBackdropColor()
  if not a or a <= 0 then return end

  local dark = COLOR_PRESETS.dark
  frame:SetBackdropColor(dark.r, dark.g, dark.b, dark.a)
end

local function ProcessBackdropBorder(frame)
  if not frame or not frame.SetBackdropBorderColor then return end

  local dark = COLOR_PRESETS.dark
  frame:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
end

local function ProcessSliderBackdrop(frame)
  if not frame or not frame.SetBackdrop or not frame.GetBackdrop then return end

  local backdrop = frame:GetBackdrop()
  if not backdrop or not IsSliderBackdrop(backdrop) then return end

  local newBackdrop = {
    bgFile = TEXTURE_PATH .. TEXTURES.SLIDER_BACKGROUND_LIGHT,
    edgeFile = backdrop.edgeFile,
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = {left = 3, right = 3, top = 6, bottom = 6}
  }

  frame:SetBackdrop(newBackdrop)

  local dark = COLOR_PRESETS.dark
  frame:SetBackdropColor(dark.r, dark.g, dark.b, dark.a)
end

local function ProcessRegions(frame)
  if not frame or not frame.GetRegions then return end

  for _, region in pairs({frame:GetRegions()}) do
    if region and region.SetVertexColor and region:GetObjectType() == "Texture" then
      local skipRegion = false

      if region.GetBlendMode and region:GetBlendMode() == "ADD" then
        skipRegion = true
      elseif IsBlacklisted(region) then
        skipRegion = true
      end

      if not skipRegion then
        local dark = COLOR_PRESETS.dark
        region:SetVertexColor(dark.r, dark.g, dark.b, dark.a)
      end
    end
  end
end

local function ProcessRolesBackground(frame)
  if not frame then return end
end

local function ProcessChildren(frame, processFunc)
  if not frame or not frame.GetChildren then return end
  
  for _, child in pairs({frame:GetChildren()}) do
    if child then
      processFunc(child)
    end
  end
end

-----------------------------------------------------------------------------
-- Core Darkening
-----------------------------------------------------------------------------
function AutoLFM.Components.DarkUI.DarkenFrame(frame)
  if not enabled then return end
  if not frame then return end

  ProcessRolesBackground(frame)
  ProcessChildren(frame, AutoLFM.Components.DarkUI.DarkenFrame)

  if frame.GetRegions then
    ProcessBackdropBorder(frame)
    ProcessBackdropColor(frame)
    ProcessSliderBackdrop(frame)
    ProcessRegions(frame)
  end
end

-----------------------------------------------------------------------------
-- Theme Management
-----------------------------------------------------------------------------
local function ApplyDarkTheme()
  if not enabled then return end
  
  for _, frame in pairs(darkenedFrames) do
    if frame then
      AutoLFM.Components.DarkUI.DarkenFrame(frame)
    end
  end
end

local function ShowReloadMessage()
  if not AutoLFM or not AutoLFM.Core or not AutoLFM.Core.Utils then return end
  if not AutoLFM.Color then return end
  
  local msg = AutoLFM.Color("You must ", "orange") .. AutoLFM.Color("/reload", "gold") .. AutoLFM.Color(" to apply changes.", "orange")
  AutoLFM.Core.Utils.PrintSuccess(msg)
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------
function AutoLFM.Components.DarkUI.RegisterFrame(frame)
  if not frame then return end
  table.insert(darkenedFrames, frame)

  if enabled then
    AutoLFM.Components.DarkUI.DarkenFrame(frame)
  end
end

function AutoLFM.Components.DarkUI.RefreshFrame(frame)
  if not enabled then return end
  if not frame then return end
  AutoLFM.Components.DarkUI.DarkenFrame(frame)
end

function AutoLFM.Components.DarkUI.Enable()
  enabled = true
  ApplyDarkTheme()

  if AutoLFM and AutoLFM.Core and AutoLFM.Core.Persistent then
    AutoLFM.Core.Persistent.SetDarkMode(true)
  end

  ShowReloadMessage()
end

function AutoLFM.Components.DarkUI.Disable()
  enabled = false

  if AutoLFM and AutoLFM.Core and AutoLFM.Core.Persistent then
    AutoLFM.Core.Persistent.SetDarkMode(false)
  end

  ShowReloadMessage()
end

function AutoLFM.Components.DarkUI.Toggle()
  if enabled then
    AutoLFM.Components.DarkUI.Disable()
  else
    AutoLFM.Components.DarkUI.Enable()
  end
end

function AutoLFM.Components.DarkUI.IsEnabled()
  return enabled
end

-----------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------
function AutoLFM.Components.DarkUI.Init()
  if AutoLFM and AutoLFM.Core and AutoLFM.Core.Persistent then
    enabled = AutoLFM.Core.Persistent.GetDarkMode()
    if enabled then
      ApplyDarkTheme()
    end
  end
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("DarkUI", "Components.DarkUI.Init")
